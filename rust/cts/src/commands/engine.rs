use anyhow::{Context, Result};
use clap::{Args, Subcommand};
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use tokio::fs;
use tracing::{info, warn};

#[derive(Args)]
pub struct EngineCommand {
    /// Workspace root (repo root)
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    #[command(subcommand)]
    pub action: EngineAction,
}

#[derive(Subcommand)]
pub enum EngineAction {
    /// Ensure a Godot binary is available as .tools/godot/bin/godot-<version>
    Ensure(EnsureArgs),
    /// Link an existing Godot binary into .tools/godot/bin as godot-<alias>
    Link(LinkArgs),
}

#[derive(Args)]
pub struct EnsureArgs {
    /// Version tag (e.g., 4.5-beta6)
    #[arg(long)]
    pub version: String,

    /// Download URL to fetch the engine if missing (optional)
    #[arg(long)]
    pub url: Option<String>,

    /// Timeout in seconds for download
    #[arg(long, default_value = "120")]
    pub timeout: u64,
}

#[derive(Args)]
pub struct LinkArgs {
    /// Absolute path to an existing Godot binary
    #[arg(long)]
    pub path: PathBuf,

    /// Alias to link as (e.g., 4.5-beta6)
    #[arg(long, value_name = "ALIAS")]
    pub r#as: String,
}

impl EngineCommand {
    pub async fn execute(&self, _json_output: bool) -> Result<()> {
        match &self.action {
            EngineAction::Ensure(args) => self.ensure(args).await,
            EngineAction::Link(args) => self.link(args).await,
        }
    }

    async fn ensure(&self, args: &EnsureArgs) -> Result<()> {
        let bin_dir = self.project_root.join(".tools/godot/bin");
        fs::create_dir_all(&bin_dir).await.ok();
        let target = bin_dir.join(format!("godot-{}", args.version));

        if target.exists() {
            info!("Godot already present: {}", target.display());
            return Ok(());
        }

        if let Some(url) = &args.url {
            // Try to download and chmod +x
            info!("Downloading Godot {} from {}", args.version, url);
            cts_web::download_file(url, &target, args.timeout)
                .await
                .with_context(|| format!("Failed to download engine from {}", url))?;
            // Make executable (unix)
            let mut perms = fs::metadata(&target).await?.permissions();
            perms.set_mode(0o755);
            fs::set_permissions(&target, perms).await?;
            info!("Installed: {}", target.display());
            return Ok(());
        }

        // No URL provided; advise user to link
        warn!(
            "Godot {} not found at {}. Provide --url to download or use `cts engine link --path /abs/bin --as {}`",
            args.version,
            target.display(),
            args.version
        );
        anyhow::bail!("Engine missing and no --url provided");
    }

    async fn link(&self, args: &LinkArgs) -> Result<()> {
        let bin_dir = self.project_root.join(".tools/godot/bin");
        fs::create_dir_all(&bin_dir).await.ok();
        let target = bin_dir.join(format!("godot-{}", args.r#as));

        if !args.path.is_absolute() {
            anyhow::bail!("--path must be absolute: {}", args.path.display());
        }
        if !args.path.exists() {
            anyhow::bail!("Binary not found: {}", args.path.display());
        }

        // Remove existing file/symlink if present
        if target.exists() {
            fs::remove_file(&target).await.ok();
        }

        // Create a small wrapper script for portability (avoid broken symlinks across moves)
        let wrapper = format!("#!/usr/bin/env bash\nexec '{}' \"$@\"\n", args.path.display());
        fs::write(&target, wrapper).await?;
        let mut perms = fs::metadata(&target).await?.permissions();
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt as _;
            perms.set_mode(0o755);
        }
        fs::set_permissions(&target, perms).await?;

        info!("Linked Godot as {} -> {}", target.display(), args.path.display());
        Ok(())
    }
}
