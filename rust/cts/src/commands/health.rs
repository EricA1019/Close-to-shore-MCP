use anyhow::{Context, Result};
use clap::Args;
use serde::{Deserialize, Serialize};
use walkdir::WalkDir;
use std::path::{Path, PathBuf};
use std::time::SystemTime;
use std::process::Command;
use tokio::fs;

#[derive(Args)]
pub struct HealthCommand {
    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    /// Godot project directory
    #[arg(long, default_value = "godot_project")]
    pub godot_project: PathBuf,

    /// Strict lint mode (default from env STRICT_LINT)
    #[arg(long)]
    pub strict_lint: Option<bool>,

    /// Output JSON
    #[arg(long, default_value = "logs/health.json")]
    pub out: PathBuf,
}

#[derive(Serialize, Deserialize, Clone, Copy, PartialEq, Eq, Debug)]
#[serde(rename_all = "lowercase")]
enum CheckStatus { Pass, Warn, Fail }

#[derive(Serialize, Deserialize)]
struct CheckResult { name: String, status: CheckStatus, message: String }

#[derive(Serialize, Deserialize)]
struct HealthReport {
    summary: CheckStatus,
    checks: Vec<CheckResult>,
}

impl HealthCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        let project_root = resolve(&self.project_root)?;
        let godot_root = if self.godot_project.is_absolute() { self.godot_project.clone() } else { project_root.join(&self.godot_project) };
        let strict = self.strict_lint.unwrap_or_else(|| std::env::var("STRICT_LINT").map(|v| v=="true").unwrap_or(false));

        let mut checks: Vec<CheckResult> = Vec::new();

        // 1) Engine available
        checks.push(engine_check(&project_root));

        // 2) Scene index freshness
        checks.push(scene_index_freshness(&project_root, &godot_root));

        // 3) Scene lint
        checks.push(run_and_check(&project_root, &["scene","lint","--project-root",".","--godot-project","godot_project","--out","logs/scene_lint.json"],
            |root| parse_scene_lint(root).map(|n| (n==0, format!("{} issues", n))), "Scene Lint"));

        // 4) API Guard
        checks.push(run_and_check(&project_root, &["lint","--project-root",".","api-guard","--godot-project","godot_project","--out","logs/api_guard.json"],
            |root| parse_api_guard(root).map(|n| (n==0, format!("{} violations", n))), "API Guard"));

        // 5) GDScript Lint
        let gd = run_and_check(
            &project_root,
            &["lint","--project-root",".","gdscript","--godot-project","godot_project","--out","logs/gdscript_lint.json"],
            |root| parse_gdscript_lint(root).map(|n| (n==0, format!("{} findings", n))),
            "GDScript Lint"
        );
        let gd = if strict { gd } else { downgrade_warn(gd) };
        checks.push(gd);

    // 6) Docs manifest present
    checks.push(docs_manifest(&project_root));

        // Summary
        let summary = summarize(&checks);
        let report = HealthReport { summary, checks };
        let out_path = if self.out.is_absolute() { self.out.clone() } else { project_root.join(&self.out) };
        if let Some(parent) = out_path.parent() { fs::create_dir_all(parent).await.ok(); }
        fs::write(&out_path, serde_json::to_string_pretty(&report)?).await?;

        if json_output { println!("{}", serde_json::to_string(&report)?); }
        else { println!("Health: {:?} -> {}", report.summary, out_path.display()); }

        match report.summary {
            CheckStatus::Pass => std::process::exit(0),
            CheckStatus::Warn => std::process::exit(2),
            CheckStatus::Fail => std::process::exit(1),
        }
    }
}

fn resolve(p: &Path) -> Result<PathBuf> {
    if p.is_absolute() { Ok(p.to_path_buf()) } else { Ok(std::env::current_dir()?.join(p)) }
}

fn engine_check(project_root: &Path) -> CheckResult {
    let candidates = [
        ".tools/godot/bin/godot-4.5-beta6",
        ".tools/godot/bin/godot-4.5",
        ".tools/godot/bin/godot",
    ];
    for c in candidates { if project_root.join(c).exists() { return pass("Engine", &format!("found {}", c)); } }
    // Fallback to PATH
    if cmd_exists("godot4") || cmd_exists("godot") { return pass("Engine", "found in PATH"); }
    fail("Engine", "no Godot binary found (managed or PATH)")
}

fn scene_index_freshness(project_root: &Path, godot_root: &Path) -> CheckResult {
    let index = project_root.join("godot_project/scripts/tools/scene_index.json");
    let scenes_dir = godot_root.join("scenes");
    if !index.exists() { return warn("Scene Index", "missing: scripts/tools/scene_index.json"); }
    let idx_time = mtime(&index);
    let mut latest_scene = idx_time;
    if scenes_dir.exists() {
        for entry in WalkDir::new(&scenes_dir).into_iter().filter_map(|e| e.ok()) {
            let p = entry.path();
            if p.is_file() && p.extension().and_then(|s| s.to_str()) == Some("tscn") {
                latest_scene = latest(latest_scene, mtime(p));
            }
        }
    }
    if latest_scene > idx_time { warn("Scene Index", "stale: index older than latest .tscn") } else { pass("Scene Index", "fresh") }
}

fn mtime(p: &Path) -> SystemTime { std::fs::metadata(p).and_then(|m| m.modified()).unwrap_or(SystemTime::UNIX_EPOCH) }
fn latest(a: SystemTime, b: SystemTime) -> SystemTime { if a> b { a } else { b } }

fn run_and_check<F>(project_root: &Path, args: &[&str], interpret: F, name: &str) -> CheckResult
where F: Fn(&Path) -> Result<(bool, String)>
{
    let exe = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("./cts"));
    let out = Command::new(&exe)
        .current_dir(project_root)
        .args(args)
        .output();
    match out {
        Ok(_o) => match interpret(project_root) {
            Ok((ok, msg)) => if ok { pass(name, &msg) } else { fail(name, &msg) },
            Err(e) => warn(name, &format!("parse failed: {}", e)),
        },
        Err(e) => fail(name, &format!("exec failed: {}", e)),
    }
}

fn cmd_exists(name: &str) -> bool {
    // Try to spawn --version; success implies existence
    Command::new(name).arg("--version").output().is_ok()
}

fn pass(name: &str, msg: &str) -> CheckResult { CheckResult{ name: name.into(), status: CheckStatus::Pass, message: msg.into() } }
fn warn(name: &str, msg: &str) -> CheckResult { CheckResult{ name: name.into(), status: CheckStatus::Warn, message: msg.into() } }
fn fail(name: &str, msg: &str) -> CheckResult { CheckResult{ name: name.into(), status: CheckStatus::Fail, message: msg.into() } }

fn downgrade_warn(mut r: CheckResult) -> CheckResult { if matches!(r.status, CheckStatus::Fail) { r.status = CheckStatus::Warn; r } else { r } }

fn summarize(checks: &[CheckResult]) -> CheckStatus {
    if checks.iter().any(|c| c.status == CheckStatus::Fail) { CheckStatus::Fail }
    else if checks.iter().any(|c| c.status == CheckStatus::Warn) { CheckStatus::Warn }
    else { CheckStatus::Pass }
}

// JSON parsers
#[derive(Deserialize)]
struct SceneLint { total_issues: usize }
fn parse_scene_lint(root: &Path) -> Result<usize> {
    let p = root.join("logs/scene_lint.json");
    let s = std::fs::read_to_string(&p).with_context(|| format!("read {}", p.display()))?;
    let v: SceneLint = serde_json::from_str(&s)?; Ok(v.total_issues)
}

#[derive(Deserialize)]
struct LintReport { total_findings: usize }
fn parse_api_guard(root: &Path) -> Result<usize> {
    let p = root.join("logs/api_guard.json");
    let s = std::fs::read_to_string(&p).with_context(|| format!("read {}", p.display()))?;
    let v: LintReport = serde_json::from_str(&s)?; Ok(v.total_findings)
}
fn parse_gdscript_lint(root: &Path) -> Result<usize> {
    let p = root.join("logs/gdscript_lint.json");
    let s = std::fs::read_to_string(&p).with_context(|| format!("read {}", p.display()))?;
    let v: LintReport = serde_json::from_str(&s)?; Ok(v.total_findings)
}

fn docs_manifest(project_root: &Path) -> CheckResult {
    let manifest = project_root.join("docs/manifest.json");
    if manifest.exists() { return pass("Docs", "manifest present"); }
    let rust_book = project_root.join("docs/rust-book/index.html");
    let gdext = project_root.join("godot_project/docs/GODOT_RUST_GDEXT/index.html");
    let gut = project_root.join("godot_project/docs/GUT_DOCS/gut.readthedocs.io/index.html");
    let rd = project_root.join("godot_project/docs/ResourceDatabases/ResourceDatabases.wiki/Home.md");
    if rust_book.exists() || gdext.exists() || gut.exists() || rd.exists() {
        pass("Docs", "local mirrors detected")
    } else {
        warn("Docs", "no docs manifest or mirrors found")
    }
}
