use anyhow::Result;
use clap::{Args, Subcommand};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use tokio::fs;

#[derive(Args)]
pub struct LintCommand {
    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    #[command(subcommand)]
    pub action: LintAction,
}

#[derive(Subcommand)]
pub enum LintAction {
    /// Guard against external access to private members (prefixed with `_`)
    ApiGuard(ApiGuardArgs),
    /// Basic GDScript lint (regex-based MVP)
    Gdscript(GdscriptArgs),
}

#[derive(Args)]
pub struct ApiGuardArgs {
    /// Godot project directory
    #[arg(long, default_value = "godot_project")]
    pub godot_project: PathBuf,

    /// JSON output file
    #[arg(long, default_value = "logs/api_guard.json")]
    pub out: PathBuf,
}

#[derive(Args)]
pub struct GdscriptArgs {
    /// Godot project directory
    #[arg(long, default_value = "godot_project")]
    pub godot_project: PathBuf,

    /// JSON output file
    #[arg(long, default_value = "logs/gdscript_lint.json")]
    pub out: PathBuf,
}

#[derive(Serialize, Deserialize, Default)]
struct LintFinding {
    file: String,
    line: usize,
    rule: String,
    message: String,
}

#[derive(Serialize, Deserialize, Default)]
struct LintReport {
    findings: Vec<LintFinding>,
    total_files: usize,
    total_findings: usize,
}

impl LintCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        match &self.action {
            LintAction::ApiGuard(args) => self.api_guard(args, json_output).await,
            LintAction::Gdscript(args) => self.gdscript(args, json_output).await,
        }
    }

    async fn api_guard(&self, args: &ApiGuardArgs, json_output: bool) -> Result<()> {
        let gp_root = if args.godot_project.is_absolute() {
            args.godot_project.clone()
        } else {
            self.project_root.join(&args.godot_project)
        };

    // Load optional configuration from cts.json at repo root
    let cfg = load_config(&self.project_root);

    // Patterns matching the legacy Python heuristic
        let re_private_access = Regex::new(r"[^\w]([A-Za-z_][A-Za-z0-9_]*)\._([A-Za-z0-9_]+)").unwrap();
        let re_private_def = Regex::new(r"^\s*(var|const|func)\s+_([A-Za-z0-9_]+)").unwrap();
    let mut engine_callbacks = [
            "ready","process","physics_process","input","unhandled_input","gui_input","enter_tree","exit_tree","notification"
    ].into_iter().map(|s| s.to_string()).collect::<std::collections::HashSet<_>>();
    // Allowlist from config
    if let Some(api) = &cfg.api_guard { for m in &api.allow_members { engine_callbacks.insert(m.clone()); } }

        let mut report = LintReport::default();

        for entry in WalkDir::new(&gp_root).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("gd") {
                let path_str = path.to_string_lossy();
        if should_ignore_path(&cfg, &path_str) { continue; }
                report.total_files += 1;
                let content = match std::fs::read_to_string(path) { Ok(s) => s, Err(_) => continue };

                // gather private defs in this file
                let mut private_defs: std::collections::HashSet<String> = std::collections::HashSet::new();
                for line in content.lines() {
                    if let Some(cap) = re_private_def.captures(line) {
                        private_defs.insert(cap.get(2).unwrap().as_str().to_string());
                    }
                }

        let mut prev = "";
        for (i, line) in content.lines().enumerate() {
                    let trimmed = line.trim_start();
                    if trimmed.starts_with('#') { continue; }
            if is_suppressed(prev, trimmed, "api_guard.no_privates") { prev = line; continue; }
                    for cap in re_private_access.captures_iter(&format!(" {}", line)) {
                        let member = cap.get(2).unwrap().as_str();
                        if engine_callbacks.contains(member) { continue; }
                        if private_defs.contains(member) { continue; }
                        report.findings.push(LintFinding{
                            file: to_rel(&self.project_root, path),
                            line: i + 1,
                            rule: "api_guard.no_privates".to_string(),
                            message: format!("External access to private member: _{}", member),
                        });
                    }
            prev = line;
                }
            }
        }

        report.total_findings = report.findings.len();

        let out_path = resolve_path(&self.project_root, &args.out);
        if let Some(parent) = out_path.parent() { fs::create_dir_all(parent).await.ok(); }
        fs::write(&out_path, serde_json::to_string_pretty(&report)?).await?;

        if json_output { println!("{}", serde_json::to_string(&report)?); }
        else {
            if report.total_findings == 0 { println!("API Guard: ✓ no violations ({} files)", report.total_files); }
            else { println!("API Guard: ✗ {} violations in {} files (see {})", report.total_findings, report.total_files, out_path.display()); }
        }

        if report.total_findings > 0 { std::process::exit(1); }
        Ok(())
    }

    async fn gdscript(&self, args: &GdscriptArgs, json_output: bool) -> Result<()> {
        let gp_root = if args.godot_project.is_absolute() {
            args.godot_project.clone()
        } else {
            self.project_root.join(&args.godot_project)
        };

        // Load optional configuration from cts.json at repo root
        let cfg = load_config(&self.project_root);

    // MVP checks: TODO markers, print-debug, obvious sleep() without await (regex fallback)
    let re_todo = Regex::new(r"(?i)\bTODO\b").unwrap();
    // Avoid matching identifiers like print_rich: require start or non-identifier before
    let re_print = Regex::new(r"(^|[^A-Za-z_])(print|prints|printt|print_debug)\s*\(").unwrap();
    let re_sleep_no_await = Regex::new(r"(?i)\bsleep\s*\(\s*\d+\s*\)").unwrap();

        let mut report = LintReport::default();

        for entry in WalkDir::new(&gp_root).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("gd") {
                let path_str = path.to_string_lossy();
                if should_ignore_path(&cfg, &path_str) { continue; }
                report.total_files += 1;
                let content = match std::fs::read_to_string(path) { Ok(s) => s, Err(_) => continue };
                // If AST feature is enabled, prefer AST scan to reduce noise
                #[cfg(feature = "gdscript-ast")]
                {
                    ast_scan_gdscript(&content, path, &mut report, &cfg, &self.project_root);
                    continue;
                }
                // Fallback: regex line scanner
                {
                    let mut prev = "";
                    for (i, line) in content.lines().enumerate() {
                        let l = line.trim();
                        if l.starts_with('#') { prev = line; continue; }
                        // Inline suppression comments either same line or previous line
                        let sup_todo = is_suppressed(prev, l, "gdscript.todo_present");
                        let sup_print = is_suppressed(prev, l, "gdscript.print_debug");
                        let sup_sleep = is_suppressed(prev, l, "gdscript.sleep_without_await");

                        if re_todo.is_match(l) && !sup_todo {
                            if !cfg.gdscript.as_ref().and_then(|g| Some(matches_any(&g.allow_todo_patterns, l))).unwrap_or(false) {
                                report.findings.push(LintFinding{ file: to_rel(&self.project_root, path), line: i+1, rule: "gdscript.todo_present".to_string(), message: "TODO marker present".to_string() });
                            }
                        }
                        if re_print.is_match(l) && !sup_print {
                            let allowed = cfg.gdscript.as_ref().map(|g| matches_any(&g.allow_print_if_contains, l)).unwrap_or(false);
                            if !allowed {
                                report.findings.push(LintFinding{ file: to_rel(&self.project_root, path), line: i+1, rule: "gdscript.print_debug".to_string(), message: "Debug print in code".to_string() });
                            }
                        }
                        if re_sleep_no_await.is_match(l) && !l.contains("await") && !sup_sleep {
                            report.findings.push(LintFinding{ file: to_rel(&self.project_root, path), line: i+1, rule: "gdscript.sleep_without_await".to_string(), message: "sleep() without await".to_string() });
                        }
                        prev = line;
                    }
                }
            }
        }

        report.total_findings = report.findings.len();
        let out_path = resolve_path(&self.project_root, &args.out);
        if let Some(parent) = out_path.parent() { fs::create_dir_all(parent).await.ok(); }
        fs::write(&out_path, serde_json::to_string_pretty(&report)?).await?;

        if json_output { println!("{}", serde_json::to_string(&report)?); }
        else {
            if report.total_findings == 0 { println!("GDScript Lint: ✓ clean ({} files)", report.total_files); }
            else { println!("GDScript Lint: ✗ {} findings in {} files (see {})", report.total_findings, report.total_files, out_path.display()); }
        }

        if report.total_findings > 0 { std::process::exit(1); }
        Ok(())
    }
}

fn resolve_path(root: &Path, p: &Path) -> PathBuf {
    if p.is_absolute() { p.to_path_buf() } else { root.join(p) }
}

fn to_rel(root: &Path, path: &Path) -> String {
    path.strip_prefix(root).unwrap_or(path).display().to_string()
}

#[derive(Deserialize, Default, Debug)]
struct CtsConfig { gdscript: Option<GdscriptLintConfig>, api_guard: Option<ApiGuardConfig> }

#[derive(Deserialize, Default, Debug)]
struct GdscriptLintConfig {
    #[serde(default = "default_ignore_dirs")]  // default if not provided
    ignore_dirs: Vec<String>,
    #[serde(default)]
    allow_print_if_contains: Vec<String>,
    #[serde(default)]
    allow_todo_patterns: Vec<String>,
}

#[derive(Deserialize, Default, Debug)]
struct ApiGuardConfig {
    #[serde(default)]
    allow_members: Vec<String>,
}

fn default_ignore_dirs() -> Vec<String> { vec!["/addons/".into(), "/tests/".into()] }

fn load_config(root: &Path) -> CtsConfig {
    let path = root.join("cts.json");
    if let Ok(s) = std::fs::read_to_string(&path) {
        if let Ok(cfg) = serde_json::from_str::<CtsConfig>(&s) { return cfg; }
    }
    CtsConfig::default()
}

fn should_ignore_path(cfg: &CtsConfig, path: &str) -> bool {
    if let Some(g) = &cfg.gdscript {
        g.ignore_dirs.iter().any(|d| path.contains(d))
    } else {
        default_ignore_dirs().into_iter().any(|d| path.contains(&d))
    }
}

fn matches_any(patterns: &Vec<String>, hay: &str) -> bool {
    patterns.iter().any(|p| hay.contains(p))
}

fn is_suppressed(prev_line: &str, line: &str, rule: &str) -> bool {
    let key = format!("cts-lint: allow {}", rule);
    prev_line.contains(&key) || line.contains(&key)
}

#[cfg(feature = "gdscript-ast")]
fn ast_scan_gdscript(content: &str, path: &Path, report: &mut LintReport, cfg: &CtsConfig, root: &Path) {
    use tree_sitter::{Parser, Query, QueryCursor, Node};
    use tree_sitter_gdscript::language;

    let mut parser = Parser::new();
    parser.set_language(&language()).ok();
    if let Some(tree) = parser.parse(content, None) {
        let root_node = tree.root_node();
        // Heuristic AST queries:
        // 1) comments with TODO
        // 2) function calls to print/prints/printt/print_debug
        let src = content.as_bytes();
        // Comments are not always in the tree; scan lines to catch TODOs
        for (i, line) in content.lines().enumerate() {
            let l = line.trim();
            if l.starts_with('#') && l.to_uppercase().contains("TODO") {
                report.findings.push(LintFinding{ file: to_rel(root, path), line: i+1, rule: "gdscript.todo_present".into(), message: "TODO marker present".into() });
            }
        }

        let q_text = r#"(
            (call_expression
                function: (identifier) @fname
            )
        )"#;
        if let Ok(q) = Query::new(language(), q_text) {
            let mut qc = QueryCursor::new();
            for m in qc.matches(&q, root_node, src) {
                for cap in m.captures {
                    let name = cap.node.utf8_text(src).unwrap_or("");
                    if ["print","prints","printt","print_debug"].contains(&name) {
                        // derive line
                        let line = cap.node.start_position().row + 1;
                        let text_line = content.lines().nth(line-1).unwrap_or("");
                        let allowed = cfg.gdscript.as_ref().map(|g| matches_any(&g.allow_print_if_contains, text_line.trim())).unwrap_or(false);
                        if !allowed {
                            report.findings.push(LintFinding{ file: to_rel(root, path), line, rule: "gdscript.print_debug".into(), message: "Debug print in code".into() });
                        }
                    }
                }
            }
        }
        // sleep without await: approximate by finding call identifiers named sleep on lines missing 'await'
        let q_sleep = r#"(
            (call_expression function: (identifier) @sname)
        )"#;
        if let Ok(q) = Query::new(language(), q_sleep) {
            let mut qc = QueryCursor::new();
            for m in qc.matches(&q, root_node, src) {
                for cap in m.captures {
                    let name = cap.node.utf8_text(src).unwrap_or("");
                    if name == "sleep" {
                        let line = cap.node.start_position().row + 1;
                        let text_line = content.lines().nth(line-1).unwrap_or("");
                        if !text_line.contains("await") {
                            report.findings.push(LintFinding{ file: to_rel(root, path), line, rule: "gdscript.sleep_without_await".into(), message: "sleep() without await".into() });
                        }
                    }
                }
            }
        }
    }
}
