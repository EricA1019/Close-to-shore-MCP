use anyhow::{Context, Result};
use clap::{Args, Subcommand};
use chrono::{DateTime, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tokio::fs;

#[derive(Args)]
pub struct LogsCommand {
    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    /// Logs actions
    #[command(subcommand)]
    pub action: LogsAction,
}

#[derive(Subcommand)]
pub enum LogsAction {
    /// Summarize recent run logs into JSON
    Summarize(SummarizeArgs),
}

#[derive(Args)]
pub struct SummarizeArgs {
    /// Glob for run logs (relative to project root)
    #[arg(long, default_value = "logs/run-*-testrunner.out")]
    pub run_log: String,

    /// Optional output path for JSON summary
    #[arg(long, default_value = "logs/log_summary.json")]
    pub out: PathBuf,

    /// Maximum number of lines read per file (to cap runtime)
    #[arg(long, default_value_t = 50000)]
    pub max_lines: usize,
}

#[derive(Serialize, Deserialize, Default)]
struct LogItem { message: String, file: String, line: usize, ts: Option<String> }

#[derive(Serialize, Deserialize, Default)]
struct LogSummary {
    run_id: Option<String>,
    started_at: Option<String>,
    ended_at: Option<String>,
    duration_sec: Option<i64>,
    files_processed: usize,
    counts: LevelCounts,
    errors: Vec<LogItem>,
    warnings: Vec<LogItem>,
}

#[derive(Serialize, Deserialize, Default)]
struct LevelCounts { error: usize, warn: usize, info: usize }

impl LogsCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        match &self.action {
            LogsAction::Summarize(args) => self.summarize(args, json_output).await,
        }
    }

    async fn summarize(&self, args: &SummarizeArgs, json_output: bool) -> Result<()> {
    let root: PathBuf = if self.project_root.is_absolute() { self.project_root.clone() } else { std::env::current_dir().unwrap_or_default().join(&self.project_root) };
    let pattern = root.join(&args.run_log);
        let mut files: Vec<PathBuf> = match glob::glob(pattern.to_str().unwrap_or("")) {
            Ok(paths) => paths.filter_map(|p| p.ok()).collect(),
            Err(_) => Vec::new(),
        };
        files.sort();

        let re_ts = Regex::new(r"(?P<ts>\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}Z?)").unwrap();
        let re_error = Regex::new(r"(?i)\berror\b").unwrap();
        let re_warn = Regex::new(r"(?i)\bwarn(ing)?\b").unwrap();
        let re_info = Regex::new(r"(?i)\binfo\b").unwrap();
        let re_runid = Regex::new(r"RUN_ID[:=]\s*([A-Za-z0-9_-]+)").unwrap();

        let mut summary = LogSummary::default();
        summary.files_processed = files.len();

        for file in files {
            let content = match std::fs::read_to_string(&file) { Ok(s) => s, Err(_) => continue };
            for (idx, line) in content.lines().take(args.max_lines).enumerate() {
                // run id
                if summary.run_id.is_none() {
                    if let Some(cap) = re_runid.captures(line) { summary.run_id = Some(cap.get(1).unwrap().as_str().to_string()); }
                }
                // timestamps
                if let Some(cap) = re_ts.captures(line) {
                    let ts = cap.name("ts").unwrap().as_str();
                    summary.started_at = pick_earliest(summary.started_at.take(), ts.to_string());
                    summary.ended_at = pick_latest(summary.ended_at.take(), ts.to_string());
                }
                // levels
                if re_error.is_match(line) {
                    summary.counts.error += 1;
                    summary.errors.push(LogItem{ message: line.trim().to_string(), file: to_rel(&root, &file), line: idx+1, ts: extract_ts(line) });
                } else if re_warn.is_match(line) {
                    summary.counts.warn += 1;
                    summary.warnings.push(LogItem{ message: line.trim().to_string(), file: to_rel(&root, &file), line: idx+1, ts: extract_ts(line) });
                } else if re_info.is_match(line) {
                    summary.counts.info += 1;
                }
            }
        }

        if let (Some(start), Some(end)) = (&summary.started_at, &summary.ended_at) {
            if let (Ok(s), Ok(e)) = (parse_ts(start), parse_ts(end)) { summary.duration_sec = Some((e - s).num_seconds()); }
        }

    let out_path = if args.out.is_absolute() { args.out.clone() } else { root.join(&args.out) };
        if let Some(parent) = out_path.parent() { fs::create_dir_all(parent).await.ok(); }
        fs::write(&out_path, serde_json::to_string_pretty(&summary)?).await
            .with_context(|| format!("write summary {}", out_path.display()))?;

        if json_output { println!("{}", serde_json::to_string(&summary)?); }
        else { println!("Logs: summarized {} files -> {}", summary.files_processed, out_path.display()); }
        Ok(())
    }
}

fn to_rel(root: &Path, p: &Path) -> String { p.strip_prefix(root).unwrap_or(p).display().to_string() }

fn extract_ts(line: &str) -> Option<String> {
    let re_ts = Regex::new(r"(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}Z?)").unwrap();
    re_ts.captures(line).and_then(|c| c.get(1)).map(|m| m.as_str().to_string())
}

fn parse_ts(s: &str) -> Result<DateTime<Utc>> { Ok(DateTime::parse_from_rfc3339(&normalize_ts(s))?.with_timezone(&Utc)) }

fn normalize_ts(s: &str) -> String {
    // If missing 'Z', assume UTC
    if s.ends_with('Z') { s.to_string() } else { format!("{}Z", s) }
}

fn pick_earliest(current: Option<String>, candidate: String) -> Option<String> {
    match current {
        None => Some(candidate),
        Some(cur) => {
            if parse_ts(&candidate).ok() < parse_ts(&cur).ok() { Some(candidate) } else { Some(cur) }
        }
    }
}

fn pick_latest(current: Option<String>, candidate: String) -> Option<String> {
    match current {
        None => Some(candidate),
        Some(cur) => {
            if parse_ts(&candidate).ok() > parse_ts(&cur).ok() { Some(candidate) } else { Some(cur) }
        }
    }
}
