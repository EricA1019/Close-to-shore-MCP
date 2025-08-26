use anyhow::{Context, Result};
use clap::Args;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::process::Command;
use std::time::{Duration, Instant};
use tokio::fs;
use tracing::{error, info, warn};

#[derive(Args)]
pub struct TestCommand {
    /// Test mode to run
    #[arg(value_enum, default_value = "all")]
    pub mode: TestMode,

    /// Path to Godot binary (auto-detected if not specified)
    #[arg(long)]
    pub godot: Option<PathBuf>,

    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    /// Output directory for logs
    #[arg(long)]
    pub output_dir: Option<PathBuf>,

    /// Timeout for each test suite in seconds
    #[arg(long, default_value = "300")]
    pub timeout: u64,
}

#[derive(clap::ValueEnum, Clone, Debug)]
pub enum TestMode {
    All,
    Integration,
    Ui,
    Smoke,
    E2e,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct TestResult {
    pub suite: String,
    pub status: TestStatus,
    pub duration_ms: u64,
    pub timestamp: String,
    pub output_file: Option<PathBuf>,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "lowercase")]
pub enum TestStatus {
    Passed,
    Failed,
    Timeout,
    Error,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct TestSummary {
    pub run_id: String,
    pub mode: String,
    pub results: Vec<TestResult>,
    pub overall_success: bool,
    pub total_duration_ms: u64,
}

impl TestCommand {
    pub async fn execute(&self, json_output: bool) -> Result<()> {
        let start_time = Instant::now();
        let run_id = std::env::var("RUN_ID")
            .unwrap_or_else(|_| Utc::now().format("%Y%m%dT%H%M%SZ").to_string());

        info!("Starting test run: {}", run_id);

        // Setup output directory
        let log_dir = self.output_dir.clone().unwrap_or_else(|| {
            self.project_root.join("logs")
        });
        fs::create_dir_all(&log_dir).await
            .context("Failed to create log directory")?;

        let output_file = log_dir.join(format!("run-{}-testrunner.out", run_id));

        // Find Godot binary
        let godot_cmd = self.find_godot_binary()?;
        info!("Using Godot binary: {}", godot_cmd.display());

        // Run tests based on mode
        let mut results = Vec::new();
        let mut overall_success = true;

        match self.mode {
            TestMode::All => {
                let result = self.run_gut_suite(
                    &godot_cmd,
                    "GUT: All",
                    &["-gdir=res://tests", "-ginclude_subdirs", "-gprefix", "test_", "-gexit"],
                    &output_file,
                ).await?;
                overall_success &= matches!(result.status, TestStatus::Passed);
                results.push(result);
            },
            TestMode::Integration => {
                let result = self.run_gut_suite(
                    &godot_cmd,
                    "GUT: Integration",
                    &["-gdir=res://tests/integration", "-ginclude_subdirs", "-gprefix", "test_", "-gexit"],
                    &output_file,
                ).await?;
                overall_success &= matches!(result.status, TestStatus::Passed);
                results.push(result);
            },
            TestMode::Ui => {
                let result = self.run_gut_suite(
                    &godot_cmd,
                    "GUT: UI",
                    &["-gdir=res://tests/ui", "-ginclude_subdirs", "-gprefix", "test_", "-gexit"],
                    &output_file,
                ).await?;
                overall_success &= matches!(result.status, TestStatus::Passed);
                results.push(result);
            },
            TestMode::Smoke => {
                let result = self.run_smoke_suite(&godot_cmd, &output_file).await?;
                overall_success &= matches!(result.status, TestStatus::Passed);
                results.push(result);
            },
            TestMode::E2e => {
                let result = self.run_e2e_suite(&godot_cmd, &output_file).await?;
                overall_success &= matches!(result.status, TestStatus::Passed);
                results.push(result);
            },
        }

        let total_duration = start_time.elapsed();
        let summary = TestSummary {
            run_id: run_id.clone(),
            mode: format!("{:?}", self.mode).to_lowercase(),
            results,
            overall_success,
            total_duration_ms: total_duration.as_millis() as u64,
        };

        // Write JSON summary
        let summary_file = log_dir.join(format!("run-{}-summary.json", run_id));
        let summary_json = serde_json::to_string_pretty(&summary)?;
        fs::write(&summary_file, summary_json).await
            .context("Failed to write summary file")?;

        if json_output {
            println!("{}", serde_json::to_string(&summary)?);
        } else {
            self.print_summary(&summary);
        }

        if !overall_success {
            std::process::exit(1);
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

    async fn run_gut_suite(
        &self,
        godot_cmd: &PathBuf,
        suite_name: &str,
        gut_args: &[&str],
        output_file: &PathBuf,
    ) -> Result<TestResult> {
        let start_time = Instant::now();
        info!("Running {}", suite_name);

        let godot_project = self.project_root.join("godot_project");
        let mut cmd = Command::new(godot_cmd);
        cmd.args(&["--headless", "--path"])
            .arg(&godot_project)
            .args(&["-s", "res://addons/gut/gut_cmdln.gd"])
            .args(gut_args);

        let result = self.run_command_with_timeout(cmd, suite_name, output_file).await?;
        let duration = start_time.elapsed();

        Ok(TestResult {
            suite: suite_name.to_string(),
            status: result,
            duration_ms: duration.as_millis() as u64,
            timestamp: Utc::now().to_rfc3339(),
            output_file: Some(output_file.clone()),
        })
    }

    async fn run_smoke_suite(&self, godot_cmd: &PathBuf, output_file: &PathBuf) -> Result<TestResult> {
        let start_time = Instant::now();
        let suite_name = "Smoke: Scenes from Index";
        info!("Running {}", suite_name);

        let godot_project = self.project_root.join("godot_project");
        let mut cmd = Command::new(godot_cmd);
        cmd.args(&["--headless", "--path"])
            .arg(&godot_project)
            .args(&["-s", "res://scripts/tools/scene_smoke_runner.gd"])
            .args(&["--", "--index", "res://scripts/tools/scene_index.json"]);

        let result = self.run_command_with_timeout(cmd, suite_name, output_file).await?;
        let duration = start_time.elapsed();

        Ok(TestResult {
            suite: suite_name.to_string(),
            status: result,
            duration_ms: duration.as_millis() as u64,
            timestamp: Utc::now().to_rfc3339(),
            output_file: Some(output_file.clone()),
        })
    }

    async fn run_e2e_suite(&self, godot_cmd: &PathBuf, output_file: &PathBuf) -> Result<TestResult> {
        let start_time = Instant::now();
        let suite_name = "E2E: Scene Switch";
        info!("Running {}", suite_name);

        let godot_project = self.project_root.join("godot_project");
        let mut cmd = Command::new(godot_cmd);
        cmd.args(&["--headless", "--path"])
            .arg(&godot_project)
            .args(&["-s", "res://scripts/tools/e2e_scene_switch_runner.gd"]);

        let result = self.run_command_with_timeout(cmd, suite_name, output_file).await?;
        let duration = start_time.elapsed();

        Ok(TestResult {
            suite: suite_name.to_string(),
            status: result,
            duration_ms: duration.as_millis() as u64,
            timestamp: Utc::now().to_rfc3339(),
            output_file: Some(output_file.clone()),
        })
    }

    async fn run_command_with_timeout(
        &self,
        mut cmd: Command,
        suite_name: &str,
        output_file: &PathBuf,
    ) -> Result<TestStatus> {
        let timeout = Duration::from_secs(self.timeout);
        
        match tokio::time::timeout(timeout, async {
            let output = cmd.output().context("Failed to execute command")?;
            
            // Append output to log file
            let log_entry = format!(
                "\n[TestRunner] Running {}...\n{}\n[TestRunner] {} {}\n",
                suite_name,
                String::from_utf8_lossy(&output.stdout),
                if output.status.success() { "✓" } else { "✗" },
                if output.status.success() { "PASSED" } else { "FAILED" }
            );
            
            fs::write(output_file, log_entry).await
                .context("Failed to write log file")?;

            Ok::<bool, anyhow::Error>(output.status.success())
        }).await {
            Ok(Ok(success)) => {
                if success {
                    info!("✓ {} PASSED", suite_name);
                    Ok(TestStatus::Passed)
                } else {
                    error!("✗ {} FAILED", suite_name);
                    Ok(TestStatus::Failed)
                }
            },
            Ok(Err(e)) => {
                error!("✗ {} ERROR: {}", suite_name, e);
                Ok(TestStatus::Error)
            },
            Err(_) => {
                warn!("⏱ {} TIMEOUT", suite_name);
                Ok(TestStatus::Timeout)
            },
        }
    }

    fn print_summary(&self, summary: &TestSummary) {
        println!("\n=== Test Summary (Run ID: {}) ===", summary.run_id);
        println!("Mode: {}", summary.mode);
        println!("Total Duration: {}ms", summary.total_duration_ms);
        println!("Overall Result: {}", if summary.overall_success { "PASSED" } else { "FAILED" });
        println!("\nSuite Results:");
        
        for result in &summary.results {
            let status_icon = match result.status {
                TestStatus::Passed => "✓",
                TestStatus::Failed => "✗",
                TestStatus::Timeout => "⏱",
                TestStatus::Error => "!",
            };
            println!("  {} {} ({}ms)", status_icon, result.suite, result.duration_ms);
        }
        println!();
    }
}
