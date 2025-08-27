use std::path::PathBuf;
use std::process::Command;

use anyhow::{Context, Result};
use clap::{Args, Subcommand};
use serde_json::Value;
use tokio::fs;
use tracing::{error, info, warn};

#[derive(Args)]
pub struct DbCommand {
    #[command(subcommand)]
    pub action: DbAction,

    /// Project root directory (contains godot_project)
    #[arg(long, global = true, default_value = ".")]
    pub project_root: PathBuf,

    /// Path to Godot binary (auto-detected if not specified)
    #[arg(long, global = true)]
    pub godot: Option<PathBuf>,
}

#[derive(Subcommand)]
pub enum DbAction {
    /// Validate the Resource DB using the headless runner
    Validate(ValidateArgs),
    /// List collections
    List(ListArgs),
    /// Search entries
    Search(SearchArgs),
    /// Export snapshot
    Export(ExportArgs),
    /// Build index (optionally export)
    Index(IndexArgs),
}

#[derive(Args, Clone)]
pub struct ValidateArgs {
    /// Comma-separated roots for DB indexing (e.g., res://data,res://addons/resource_databases)
    #[arg(long, default_value = "res://data,res://addons/resource_databases")]
    pub roots: String,

    /// Treat warnings as failures (non-zero exit)
    #[arg(long, default_value_t = false)]
    pub strict: bool,

    /// Write the JSON report to this file
    #[arg(long)]
    pub out: Option<PathBuf>,
}

impl DbCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        match &self.action {
            DbAction::Validate(args) => self.validate(args.clone(), json_output).await,
            DbAction::List(args) => self.list(args.clone(), json_output).await,
            DbAction::Search(args) => self.search(args.clone(), json_output).await,
            DbAction::Export(args) => self.export(args.clone(), json_output).await,
            DbAction::Index(args) => self.index(args.clone(), json_output).await,
        }
    }

    async fn validate(&self, args: ValidateArgs, json_output: bool) -> Result<()> {
        let godot_cmd = self.find_godot_binary()?;
        let godot_project = self.project_root.join("godot_project");

        info!(
            "Running DB validate (strict={}, roots={})",
            args.strict, args.roots
        );

        let mut cmd = Command::new(&godot_cmd);
        cmd.args(["--headless", "--path"]).arg(&godot_project);
    cmd.args(["-s", "res://scripts/tools/db_runner.gd", "validate"]);
        if args.strict {
            cmd.arg("--strict");
        }
        cmd.arg(format!("--roots={}", args.roots));

        let output = cmd.output().context("Failed to execute Godot db_runner")?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        // Attempt to locate the JSON line from stdout (ignore engine noise)
        let mut json_value: Option<Value> = None;
        for line in stdout.lines().rev() {
            let trimmed = line.trim();
            if trimmed.starts_with('{') && trimmed.ends_with('}') {
                if let Ok(v) = serde_json::from_str::<Value>(trimmed) {
                    json_value = Some(v);
                    break;
                }
            }
        }

        if let Some(v) = &json_value {
            if json_output {
                println!("{}", serde_json::to_string(v)?);
            } else {
                // Pretty print minimal summary
                let ok = v.get("ok").and_then(|x| x.as_bool()).unwrap_or(false);
                let summary = v.get("summary").cloned().unwrap_or(Value::Null);
                println!("DB Validate => ok={} summary={}", ok, summary);
            }
        } else {
            // Fallback: print captured stdout/stderr for debugging
            warn!("Could not parse JSON from db_runner output; forwarding raw output");
            println!("{}", stdout);
            if !stderr.is_empty() {
                eprintln!("{}", stderr);
            }
        }

        // Optionally write to file (write parsed JSON if available, else raw stdout)
        if let Some(out_path) = args.out {
            if let Some(v) = &json_value {
                let s = serde_json::to_string_pretty(v)?;
                fs::write(&out_path, s).await.context("Failed to write JSON report")?;
            } else {
                fs::write(&out_path, stdout)
                    .await
                    .context("Failed to write raw report")?;
            }
        }

        // Propagate failure if child failed or ok=false
        let mut exit_code = output.status.code().unwrap_or(1);
        if let Some(v) = &json_value {
            if let Some(ok) = v.get("ok").and_then(|x| x.as_bool()) {
                if !ok {
                    exit_code = 1;
                } else if args.strict {
                    // Strict mode: fail on any warnings even if child exited 0.
                    let mut warn_count = 0usize;
                    if let Some(summary) = v.get("summary") {
                        warn_count = summary
                            .get("warnings")
                            .and_then(|x| x.as_u64()).unwrap_or(0) as usize;
                    }
                    if warn_count == 0 {
                        if let Some(issues) = v.get("issues").and_then(|x| x.as_array()) {
                            warn_count = issues.iter().filter(|i| i.get("level").and_then(|l| l.as_str()) == Some("warning")).count();
                        }
                    }
                    if warn_count > 0 { exit_code = 1; }
                }
            }
        }

        if exit_code != 0 {
            error!("DB validate failed (exit code {})", exit_code);
            std::process::exit(exit_code);
        }

        Ok(())
    }

    async fn list(&self, args: ListArgs, json_output: bool) -> Result<()> {
        let (stdout, stderr) = self.run_runner(&["list"], Some(&args.roots))?;
        self.print_or_forward(stdout, stderr, json_output)?;
        Ok(())
    }

    async fn search(&self, args: SearchArgs, json_output: bool) -> Result<()> {
        let mut extra: Vec<String> = Vec::new();
        extra.push("search".into());
        extra.push(format!("--q={}", args.query));
        if let Some(coll) = args.collection { extra.push(format!("--collection={}", coll)); }
        if let Some(limit) = args.limit { extra.push(format!("--limit={}", limit)); }

        let (stdout, stderr) = self.run_runner(&extra.iter().map(|s| s.as_str()).collect::<Vec<_>>(), Some(&args.roots))?;
        self.print_or_forward(stdout, stderr, json_output)?;
        Ok(())
    }

    async fn export(&self, args: ExportArgs, json_output: bool) -> Result<()> {
        let mut extra: Vec<String> = vec!["export".into()];
        if let Some(out) = args.out { extra.push(format!("--out={}", out.display())); }
        let (stdout, stderr) = self.run_runner(&extra.iter().map(|s| s.as_str()).collect::<Vec<_>>(), Some(&args.roots))?;
        self.print_or_forward(stdout, stderr, json_output)?;
        Ok(())
    }

    async fn index(&self, args: IndexArgs, json_output: bool) -> Result<()> {
        // If out specified, call export to also persist snapshot; else just build_index
    let extra: Vec<String> = if let Some(out) = args.out {
            vec!["export".into(), format!("--out={}", out.display())]
        } else {
            vec!["build_index".into()]
        };
        let (stdout, stderr) = self.run_runner(&extra.iter().map(|s| s.as_str()).collect::<Vec<_>>(), Some(&args.roots))?;
        self.print_or_forward(stdout, stderr, json_output)?;
        Ok(())
    }

    fn run_runner(&self, sub_and_flags: &[&str], roots: Option<&String>) -> Result<(String, String)> {
        let godot_cmd = self.find_godot_binary()?;
        let godot_project = self.project_root.join("godot_project");
        let mut cmd = Command::new(&godot_cmd);
        cmd.args(["--headless", "--path"]).arg(&godot_project);
        cmd.args(["-s", "res://scripts/tools/db_runner.gd"]);
        // Subcommand first
        for s in sub_and_flags { cmd.arg(s); }
        // Roots
        if let Some(r) = roots { cmd.arg(format!("--roots={}", r)); }

        let output = cmd.output().context("Failed to execute Godot db_runner")?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        Ok((stdout, stderr))
    }

    fn print_or_forward(&self, stdout: String, stderr: String, json_output: bool) -> Result<()> {
        // Try to extract JSON line from stdout
        let mut json_value: Option<Value> = None;
        for line in stdout.lines().rev() {
            let trimmed = line.trim();
            if trimmed.starts_with('{') && trimmed.ends_with('}') {
                if let Ok(v) = serde_json::from_str::<Value>(trimmed) {
                    json_value = Some(v);
                    break;
                }
            }
        }

        if let Some(v) = json_value {
            if json_output {
                println!("{}", serde_json::to_string(&v)?);
            } else {
                println!("{}", serde_json::to_string_pretty(&v)?);
            }
        } else {
            // Forward raw output if parsing failed
            println!("{}", stdout);
            if !stderr.is_empty() { eprintln!("{}", stderr); }
        }
        Ok(())
    }

    fn find_godot_binary(&self) -> Result<PathBuf> {
        if let Some(ref godot_path) = self.godot {
            return Ok(godot_path.clone());
        }

        // Try local .tools/godot/bin/godot first
        let local_godot = self.project_root.join(".tools/godot/bin/godot");
        if local_godot.exists() {
            return Ok(local_godot);
        }

        // Try godot4 in PATH
        if let Ok(output) = Command::new("which").arg("godot4").output() {
            if output.status.success() {
                let path_str = String::from_utf8_lossy(&output.stdout);
                let trimmed = path_str.trim();
                return Ok(PathBuf::from(trimmed));
            }
        }

        // Try godot in PATH
        if let Ok(output) = Command::new("which").arg("godot").output() {
            if output.status.success() {
                let path_str = String::from_utf8_lossy(&output.stdout);
                let trimmed = path_str.trim();
                return Ok(PathBuf::from(trimmed));
            }
        }

        anyhow::bail!("Could not find Godot binary. Use --godot to specify path.")
    }
}

#[derive(Args, Clone)]
pub struct ListArgs {
    /// Comma-separated roots for DB indexing
    #[arg(long, default_value = "res://data,res://addons/resource_databases")]
    pub roots: String,
}

#[derive(Args, Clone)]
pub struct SearchArgs {
    /// Query text to search
    #[arg(long, alias = "q")]
    pub query: String,
    /// Restrict to a collection
    #[arg(long)]
    pub collection: Option<String>,
    /// Limit results
    #[arg(long)]
    pub limit: Option<usize>,
    /// Comma-separated roots for DB indexing
    #[arg(long, default_value = "res://data,res://addons/resource_databases")]
    pub roots: String,
}

#[derive(Args, Clone)]
pub struct ExportArgs {
    /// Comma-separated roots for DB indexing
    #[arg(long, default_value = "res://data,res://addons/resource_databases")]
    pub roots: String,
    /// Output file for snapshot (user:// or absolute)
    #[arg(long)]
    pub out: Option<PathBuf>,
}

#[derive(Args, Clone)]
pub struct IndexArgs {
    /// Comma-separated roots for DB indexing
    #[arg(long, default_value = "res://data,res://addons/resource_databases")]
    pub roots: String,
    /// Optional output file; if set, export snapshot after building
    #[arg(long)]
    pub out: Option<PathBuf>,
}
