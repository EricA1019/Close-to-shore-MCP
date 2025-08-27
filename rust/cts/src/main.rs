use anyhow::Result;
use clap::{Parser, Subcommand};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

mod commands;

use commands::{bundle::BundleCommand, test::TestCommand};
use commands::docs::DocsCommand;
use commands::engine::EngineCommand;
use commands::scene::SceneCommand;
use commands::lint::LintCommand;
use commands::logs::LogsCommand;
use commands::health::HealthCommand;
use commands::release::ReleaseCommand;
use commands::db::DbCommand;

#[derive(Parser)]
#[command(name = "cts")]
#[command(about = "Close-to-Shore: Unified tooling for MCP project")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    /// Set log level (trace, debug, info, warn, error)
    #[arg(long, global = true, default_value = "info")]
    log_level: String,

    /// Output JSON instead of human-readable format
    #[arg(long, global = true)]
    json: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Run test suites (GUT, smoke, etc.)
    Test(TestCommand),
    /// Build context bundle from project docs
    Bundle(BundleCommand),
    /// Manage external documentation (fetch, list)
    Docs(DocsCommand),
    /// Manage Godot engine binaries (ensure, link)
    Engine(EngineCommand),
    /// Scene tools (lint, index)
    Scene(SceneCommand),
    /// Code quality lints (api-guard, gdscript)
    Lint(LintCommand),
    /// Logs tooling (summarize)
    Logs(LogsCommand),
    /// Project health summary
    Health(HealthCommand),
    /// Release prep (notes, changelog, bump)
    Release(ReleaseCommand),
    /// Resource DB tools (validate)
    Db(DbCommand),
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // Initialize tracing
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(&cli.log_level));

    if cli.json {
        tracing_subscriber::registry()
            .with(tracing_subscriber::fmt::layer().json())
            .with(filter)
            .init();
    } else {
        tracing_subscriber::registry()
            .with(tracing_subscriber::fmt::layer().compact())
            .with(filter)
            .init();
    }

    // Execute command
    match cli.command {
        Commands::Test(cmd) => cmd.execute(cli.json).await,
        Commands::Bundle(cmd) => cmd.execute(cli.json).await,
    Commands::Docs(cmd) => cmd.execute(cli.json).await,
    Commands::Engine(cmd) => cmd.execute(cli.json).await,
    Commands::Scene(cmd) => cmd.execute(cli.json).await,
    Commands::Lint(cmd) => cmd.execute(cli.json).await,
    Commands::Logs(cmd) => cmd.execute(cli.json).await,
    Commands::Health(cmd) => cmd.execute(cli.json).await,
    Commands::Release(cmd) => cmd.execute(cli.json).await,
    Commands::Db(cmd) => cmd.execute(cli.json).await,
    }
}
