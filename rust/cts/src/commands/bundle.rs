use anyhow::{Context, Result};
use clap::Args;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tokio::fs;
use tracing::{info, warn};

#[derive(Args)]
pub struct BundleCommand {
    /// Output file for the context bundle
    #[arg(long, default_value = ".mcp_context/context_bundle.md")]
    pub output: PathBuf,

    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    /// Additional source files to include
    #[arg(long)]
    pub sources: Vec<PathBuf>,

    /// Skip missing files instead of erroring
    #[arg(long)]
    pub skip_missing: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BundleResult {
    pub output_file: PathBuf,
    pub sources_processed: usize,
    pub sources_skipped: usize,
    pub timestamp: String,
}

impl BundleCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        info!("Building context bundle");

        // Define default source files (matching context_bundler.py)
        let default_sources = vec![
            "AGENT_PROMPT.md",
            "MCP/CLOSE_TO_SHORE.md", 
            "MCP/TOOLING_PHILOSOPHY.md",
            "MCP/TEST_POLICY.md",
            "MCP/GODOT_WORKFLOW.md",
            "MCP/PLUGINS.md",
            "MCP/DOCUMENTATION_INDEX.md",
            "README.md",
        ];

        let mut all_sources = Vec::new();
        
        // Add default sources
        for source in default_sources {
            all_sources.push(self.project_root.join(source));
        }
        
        // Add additional sources
        for source in &self.sources {
            all_sources.push(if source.is_absolute() {
                source.clone()
            } else {
                self.project_root.join(source)
            });
        }

        // Create output directory
        if let Some(parent) = self.output.parent() {
            fs::create_dir_all(parent).await
                .context("Failed to create output directory")?;
        }

        // Build bundle content
        let mut bundle_content = String::new();
        let mut sources_processed = 0;
        let mut sources_skipped = 0;

        // Add header
        bundle_content.push_str(&format!(
            "# Close-to-Shore MCP Context Bundle\n\n\
            Generated: {}\n\
            Generator: cts bundle\n\n\
            This bundle contains key project documentation for MCP context.\n\n",
            Utc::now().format("%Y-%m-%d %H:%M:%S UTC")
        ));

        // Process each source file
        for source_path in all_sources {
            match self.read_source_file(&source_path).await {
                Ok(content) => {
                    let relative_path = source_path.strip_prefix(&self.project_root)
                        .unwrap_or(&source_path);
                    // Choose an outer fence length longer than any backtick run in content
                    let fence_len = 1 + max_backtick_run(&content).max(3);
                    let fence = "`".repeat(fence_len);
                    bundle_content.push_str(&format!(
                        "## {}\n\n{}markdown\n{}\n{}\n\n",
                        relative_path.display(),
                        fence,
                        content,
                        fence
                    ));
                    sources_processed += 1;
                    info!("Included: {}", relative_path.display());
                },
                Err(e) => {
                    if self.skip_missing {
                        let relative_path = source_path.strip_prefix(&self.project_root)
                            .unwrap_or(&source_path);
                        bundle_content.push_str(&format!(
                            "## {} (Skipped)\n\n<!-- Skipped {} ({}) -->\n\n",
                            relative_path.display(),
                            relative_path.display(),
                            e
                        ));
                        sources_skipped += 1;
                        warn!("Skipped: {} ({})", relative_path.display(), e);
                    } else {
                        return Err(e);
                    }
                }
            }
        }

        // Write bundle file
        // Append lightweight docs manifest if present
        {
            let root = &self.project_root;
            let mut manifest = String::new();
            let rust_book = root.join("docs/rust-book/index.html");
            let gdext = root.join("godot_project/docs/GODOT_RUST_GDEXT/index.html");
            let gut = root.join("godot_project/docs/GUT_DOCS/gut.readthedocs.io/index.html");
            let rd = root.join("godot_project/docs/ResourceDatabases/ResourceDatabases.wiki/Home.md");

            if rust_book.exists() || gdext.exists() || gut.exists() || rd.exists() {
                manifest.push_str("## Local Reference Docs (Manifest)\n\n");
                if rust_book.exists() {
                    manifest.push_str(&format!("- Rust Book: {}\n", rust_book.display()));
                }
                if gdext.exists() {
                    manifest.push_str(&format!("- Godot Rust (GDext): {}\n", gdext.display()));
                }
                if gut.exists() {
                    manifest.push_str(&format!("- GUT docs: {}\n", gut.display()));
                }
                if rd.exists() {
                    manifest.push_str(&format!("- Resource Databases wiki: {}\n", rd.display()));
                }
                manifest.push_str("\nNote: These paths are local mirrors for offline lookup.\n\n");
                bundle_content.push_str(&manifest);
            }
        }

        fs::write(&self.output, bundle_content).await
            .context("Failed to write bundle file")?;

        let result = BundleResult {
            output_file: self.output.clone(),
            sources_processed,
            sources_skipped,
            timestamp: Utc::now().to_rfc3339(),
        };

        if json_output {
            println!("{}", serde_json::to_string(&result)?);
        } else {
            println!("✓ Context bundle created: {}", self.output.display());
            println!("  Processed: {} files", sources_processed);
            if sources_skipped > 0 {
                println!("  Skipped: {} files", sources_skipped);
            }
        }

        Ok(())
    }

    async fn read_source_file(&self, path: &PathBuf) -> Result<String> {
        if !path.exists() {
            anyhow::bail!("File not found: {}", path.display());
        }

        fs::read_to_string(path).await
            .with_context(|| format!("Failed to read file: {}", path.display()))
    }
}

fn max_backtick_run(s: &str) -> usize {
    let mut max_run = 0usize;
    let mut cur = 0usize;
    for ch in s.chars() {
        if ch == '`' { cur += 1; } else { max_run = max_run.max(cur); cur = 0; }
    }
    max_run.max(cur)
}
