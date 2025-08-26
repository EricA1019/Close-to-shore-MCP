use anyhow::{Context, Result};
use clap::Args;
use chrono::Utc;
use regex::Regex;
use std::path::{Path, PathBuf};
use tokio::fs;

#[derive(Args)]
pub struct ReleaseCommand {
    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    /// Target version (e.g., v0.2.0). Use 'auto' to infer.
    #[arg(long)]
    pub version: String,

    /// Git range to collect notes from (e.g., v0.1.0..HEAD)
    #[arg(long)]
    pub notes_from: Option<String>,

    /// Changelog file path
    #[arg(long, default_value = "CHANGELOG.md")]
    pub changelog: PathBuf,

    /// Godot project file to update
    #[arg(long, default_value = "godot_project/project.godot")]
    pub project_file: PathBuf,

    /// Output file for release notes
    #[arg(long, default_value = "RELEASE_NOTES.md")]
    pub out: PathBuf,

    /// Dry run (do not modify files other than release notes)
    #[arg(long, default_value_t = true)]
    pub dry_run: bool,
}

impl ReleaseCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        let root = if self.project_root.is_absolute() { self.project_root.clone() } else { std::env::current_dir()?.join(&self.project_root) };
        let version = if self.version.to_lowercase() == "auto" { infer_next_version(&root)? } else { self.version.clone() };

        // Gather notes
        let notes = generate_notes(self.notes_from.clone())?;
        let date = Utc::now().format("%Y-%m-%d").to_string();

        // Write RELEASE_NOTES.md
        let notes_body = format!("# {} - {}\n\n{}\n", version, date, notes);
        let out_path = resolve(&root, &self.out);
        fs::write(&out_path, &notes_body).await?;

        // Update CHANGELOG.md (append)
        let changelog_path = resolve(&root, &self.changelog);
        if !self.dry_run {
            let mut existing = String::new();
            if let Ok(s) = std::fs::read_to_string(&changelog_path) { existing = s; }
            let entry = format!("\n## {} - {}\n\n{}\n", version, date, notes);
            fs::write(&changelog_path, format!("{}{}", existing, entry)).await?;
        }

        // Update project.godot version
        let proj_path = resolve(&root, &self.project_file);
        if !self.dry_run && proj_path.exists() {
            if let Ok(s) = std::fs::read_to_string(&proj_path) {
                let re = Regex::new(r#"(?m)^(config/version\s*=\s*")([^"]*)(")$"#).unwrap();
                let updated = if re.is_match(&s) { re.replace(&s, format!("$1{}$3", version)).to_string() } else { s };
                fs::write(&proj_path, updated).await?;
            }
        }

        if json_output { println!("{{\"version\":\"{}\",\"notes\":\"{}\",\"out\":\"{}\"}}", sanitize(&version), sanitize(&notes), out_path.display()); }
        else { println!("Release prep: {} -> {} (dry_run={})", version, out_path.display(), self.dry_run); }
        Ok(())
    }
}

fn resolve(root: &Path, p: &Path) -> PathBuf { if p.is_absolute() { p.to_path_buf() } else { root.join(p) } }

fn sanitize(s: &str) -> String { s.replace('"', "'").replace('\n', "\\n") }

fn infer_next_version(_root: &Path) -> Result<String> {
    // Minimal inference: bump patch if any commits include fix:, else bump minor if feat:
    let log = git_log(Some("HEAD~50..HEAD".into()))?;
    if log.iter().any(|l| l.starts_with("feat:")) { Ok("v0.1.0".into()) } else if log.iter().any(|l| l.starts_with("fix:")) { Ok("v0.0.1".into()) } else { Ok("v0.0.1".into()) }
}

fn generate_notes(range: Option<String>) -> Result<String> {
    let lines = git_log(range)?;
    let mut feats = Vec::new();
    let mut fixes = Vec::new();
    let mut others = Vec::new();
    for l in lines {
        if l.starts_with("feat:") { feats.push(l); }
        else if l.starts_with("fix:") { fixes.push(l); }
        else { others.push(l); }
    }
    let mut out = String::new();
    if !feats.is_empty() { out.push_str("### Features\n"); for f in feats { out.push_str(&format!("- {}\n", f)); } out.push('\n'); }
    if !fixes.is_empty() { out.push_str("### Fixes\n"); for f in fixes { out.push_str(&format!("- {}\n", f)); } out.push('\n'); }
    if !others.is_empty() { out.push_str("### Other\n"); for o in others { out.push_str(&format!("- {}\n", o)); } out.push('\n'); }
    if out.is_empty() { out.push_str("- Maintenance\n"); }
    Ok(out)
}

fn git_log(range: Option<String>) -> Result<Vec<String>> {
    let mut cmd = std::process::Command::new("git");
    cmd.arg("log").arg("--pretty=%s");
    if let Some(r) = range { cmd.arg(r); }
    let out = cmd.output().context("git log failed")?;
    if !out.status.success() { return Ok(Vec::new()); }
    let s = String::from_utf8_lossy(&out.stdout);
    Ok(s.lines().map(|l| l.trim().to_string()).filter(|l| !l.is_empty()).collect())
}
