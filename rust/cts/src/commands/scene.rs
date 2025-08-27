use anyhow::Result;
use clap::{Args, Subcommand};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use tokio::fs;
use tracing::{error, info, warn};
use walkdir::WalkDir;

#[derive(Args)]
pub struct SceneCommand {
    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    #[command(subcommand)]
    pub action: SceneAction,
}

#[derive(Subcommand)]
pub enum SceneAction {
    /// Build or update scripts/tools/scene_index.json
    Index(IndexArgs),
    /// Lint scenes for missing resources and basic issues
    Lint(LintArgs),
}

#[derive(Args)]
pub struct IndexArgs {
    /// Godot project directory
    #[arg(long, default_value = "godot_project")]
    pub godot_project: PathBuf,

    /// Output file (resolves relative to repo root)
    #[arg(long, default_value = "godot_project/scripts/tools/scene_index.json")]
    pub output: PathBuf,

    /// Include only scenes whose res:// path contains any of these substrings
    #[arg(long)]
    pub include: Vec<String>,

    /// Exclude scenes whose res:// path contains any of these substrings
    #[arg(long)]
    pub exclude: Vec<String>,
}

#[derive(Args)]
pub struct LintArgs {
    /// Godot project directory
    #[arg(long, default_value = "godot_project")]
    pub godot_project: PathBuf,

    /// JSON output for issues
    #[arg(long, default_value = "logs/scene_lint.json")]
    pub out: PathBuf,
}

#[derive(Serialize, Deserialize)]
struct SceneIndex { scenes: Vec<String> }

#[derive(Serialize, Deserialize, Default)]
struct LintIssue {
    file: String,
    line: usize,
    kind: String,
    message: String,
}

#[derive(Serialize, Deserialize, Default)]
struct LintReport {
    issues: Vec<LintIssue>,
    total_files: usize,
    total_issues: usize,
}

impl SceneCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        match &self.action {
            SceneAction::Index(args) => self.index(args, json_output).await,
            SceneAction::Lint(args) => self.lint(args, json_output).await,
        }
    }

    async fn index(&self, args: &IndexArgs, _json_output: bool) -> Result<()> {
        let gp_root = if args.godot_project.is_absolute() {
            args.godot_project.clone()
        } else {
            self.project_root.join(&args.godot_project)
        };
        let out_path = if args.output.is_absolute() {
            args.output.clone()
        } else {
            self.project_root.join(&args.output)
        };

        let mut set: BTreeSet<String> = BTreeSet::new();

        for entry in WalkDir::new(&gp_root).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("tscn") {
                // Build res:// path
                if let Some(res_path) = to_res_path(path, &gp_root) {
                    // include/exclude filters
                    if !args.include.is_empty() && !args.include.iter().any(|s| res_path.contains(s)) {
                        continue;
                    }
                    if args.exclude.iter().any(|s| res_path.contains(s)) {
                        continue;
                    }
                    set.insert(res_path);
                }
            }
        }

        let scenes: Vec<String> = set.into_iter().collect();
        let index = SceneIndex { scenes };

        if let Some(parent) = out_path.parent() {
            fs::create_dir_all(parent).await.ok();
        }
        fs::write(&out_path, serde_json::to_string_pretty(&index)?).await?;
        info!("Scene index written: {}", out_path.display());
        Ok(())
    }

    async fn lint(&self, args: &LintArgs, json_output: bool) -> Result<()> {
        let gp_root = if args.godot_project.is_absolute() {
            args.godot_project.clone()
        } else {
            self.project_root.join(&args.godot_project)
        };
        let mut report = LintReport::default();

        let re_path = Regex::new(r#"path"\s*=\s*"(res://[^"]+)""#).unwrap();

        for entry in WalkDir::new(&gp_root).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("tscn") {
                report.total_files += 1;
                let content = match std::fs::read_to_string(path) {
                    Ok(s) => s,
                    Err(e) => {
                        warn!("Failed to read {}: {}", path.display(), e);
                        continue;
                    }
                };
                for (i, line) in content.lines().enumerate() {
                    if let Some(cap) = re_path.captures(line) {
                        let res_p = cap.get(1).unwrap().as_str();
                        let fs_p = res_to_fs(res_p, &gp_root);
                        if !fs_p.exists() {
                            report.issues.push(LintIssue {
                                file: to_res_path(path, &gp_root).unwrap_or_else(|| path.display().to_string()),
                                line: i + 1,
                                kind: "missing_resource".to_string(),
                                message: format!("Referenced resource not found: {}", res_p),
                            });
                        }
                    }
                }
            }
        }

        report.total_issues = report.issues.len();

        let out_path = if args.out.is_absolute() {
            args.out.clone()
        } else {
            self.project_root.join(&args.out)
        };
        if let Some(parent) = out_path.parent() { fs::create_dir_all(parent).await.ok(); }
        fs::write(&out_path, serde_json::to_string_pretty(&report)?).await?;

        if json_output {
            println!("{}", serde_json::to_string(&report)?);
        } else {
            if report.total_issues == 0 {
                println!("Scene Lint: ✓ no issues ({} files)", report.total_files);
            } else {
                println!("Scene Lint: ✗ {} issues in {} files (see {})", report.total_issues, report.total_files, out_path.display());
            }
        }

        if report.total_issues > 0 {
            // Non-zero exit on issues
            error!("scene lint found issues: {}", report.total_issues);
            std::process::exit(1);
        }

        Ok(())
    }
}

fn to_res_path(path: &Path, godot_root: &Path) -> Option<String> {
    let p = path.strip_prefix(godot_root).ok()?;
    Some(format!("res://{}", p.to_string_lossy().replace('\\', "/")))
}

fn res_to_fs(res_path: &str, godot_root: &Path) -> PathBuf {
    let rel = res_path.strip_prefix("res://").unwrap_or(res_path);
    godot_root.join(rel)
}
