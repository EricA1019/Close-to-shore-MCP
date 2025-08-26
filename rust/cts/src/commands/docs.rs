use anyhow::Result;
use clap::{Args, Subcommand};
use std::path::{Path, PathBuf};
use std::fs as stdfs;
use tokio::fs;
use tracing::{info, warn};
use cts_web::{download_file, download_file_with_etag};
use serde::{Serialize, Deserialize};

#[derive(Args)]
pub struct DocsCommand {
    /// Project root directory
    #[arg(long, default_value = ".")]
    pub project_root: PathBuf,

    /// What to do: fetch, list
    #[command(subcommand)]
    pub action: DocsAction,
}

#[derive(Subcommand)]
pub enum DocsAction {
    /// Download/update external docs (Rust Book, Godot Rust GDext, GUT, Resource Databases)
    Fetch(FetchArgs),
    /// List local docs status
    List,
    /// Search local docs for a query string
    Search(SearchArgs),
    /// Generate a simple manifest (title + path) for local mirrors
    Gen(GenArgs),
    /// Sync docs from a sources manifest (docs/docs_sources.json)
    Sync(SyncArgs),
}

#[derive(Args)]
pub struct FetchArgs {
    /// Include the Rust Book (large). Stored under ./docs/rust-book/
    #[arg(long, default_value_t = true)]
    pub rust_book: bool,

    /// Include Godot Rust (gdnative/gdextension) API docs. Stored under godot_project/docs/GODOT_RUST_GDEXT/
    #[arg(long, default_value_t = true)]
    pub godot_rust: bool,

    /// Include GUT docs mirror. Stored under godot_project/docs/GUT_DOCS/
    #[arg(long, default_value_t = true)]
    pub gut: bool,

    /// Include Resource Databases docs. Stored under godot_project/docs/ResourceDatabases/
    #[arg(long, default_value_t = true)]
    pub resource_databases: bool,
}

impl DocsCommand {
    pub async fn execute(&self, _json_output: bool) -> Result<()> {
        match &self.action {
            DocsAction::Fetch(args) => self.fetch_docs(args).await,
            DocsAction::List => self.list_docs().await,
            DocsAction::Search(args) => self.search_docs(args).await,
            DocsAction::Gen(args) => self.gen_manifest(args).await,
            DocsAction::Sync(args) => self.sync_docs(args).await,
        }
    }

    async fn list_docs(&self) -> Result<()> {
        let rust_book_dir = self.project_root.join("docs/rust-book");
        let godot_rust_dir = self
            .project_root
            .join("godot_project/docs/GODOT_RUST_GDEXT");
        let gut_dir = self.project_root.join("godot_project/docs/GUT_DOCS");
        let rd_dir = self
            .project_root
            .join("godot_project/docs/ResourceDatabases");

        println!("Local docs status:");
        println!("- Rust Book: {}", exists_status(&rust_book_dir));
        println!("- Godot Rust (GDext): {}", exists_status(&godot_rust_dir));
        println!("- GUT docs: {}", exists_status(&gut_dir));
        println!("- Resource Databases: {}", exists_status(&rd_dir));
        Ok(())
    }

    async fn fetch_docs(&self, args: &FetchArgs) -> Result<()> {
        fs::create_dir_all(&self.project_root).await.ok();

        if args.rust_book {
            // Official static site export. We'll mirror the ZIP if available; else fallback to scraping index.html
            let target = self.project_root.join("docs/rust-book");
            fetch_site_simple(
                "https://doc.rust-lang.org/book/",
                &target,
                &["index.html", "css/", "imgs/", "ch*/"],
            )
            .await?;
            info!("Rust Book fetched to {}", target.display());
        }

        if args.godot_rust {
            let target = self
                .project_root
                .join("godot_project/docs/GODOT_RUST_GDEXT");
            // Fetch the main index + all.html + src/ (source view)
            fetch_site_simple(
                "https://docs.rs/gdext/latest/gdext/",
                &target,
                &["index.html", "all.html", "src/"],
            ).await?;
            info!("Godot Rust GDext docs fetched to {}", target.display());
        }

        if args.gut {
            // GUT docs already exist in repo; ensure README pointer remains. Optionally refresh homepage
            let gut_root = self.project_root.join("godot_project/docs/GUT_DOCS");
            fs::create_dir_all(&gut_root).await.ok();
            let target = gut_root.join("gut.readthedocs.io");
            fetch_site_simple(
                "https://gut.readthedocs.io/en/latest/",
                &target,
                &["index.html", "search.html", "_static/", "_images/", "api.html"],
            )
            .await?;
            info!("GUT docs mirrored to {}", target.display());
        }

        if args.resource_databases {
            // Resource Databases wiki snapshot; only mirror home and getting started
            let target = self
                .project_root
                .join("godot_project/docs/ResourceDatabases/ResourceDatabases.wiki");
            fs::create_dir_all(&target).await.ok();
            // Simple pages
            if let Err(e) = fetch_file(
                "https://raw.githubusercontent.com/wiki/ThatOneGamer/ResourceDatabases/Home.md",
                &target.join("Home.md"),
            ).await { warn!("RD Home fetch failed: {}", e); }
            if let Err(e) = fetch_file(
                "https://raw.githubusercontent.com/wiki/ThatOneGamer/ResourceDatabases/Getting-started.md",
                &target.join("Getting-started.md"),
            ).await { warn!("RD Getting-started fetch failed: {}", e); }
            if let Err(e) = fetch_file(
                "https://raw.githubusercontent.com/wiki/ThatOneGamer/ResourceDatabases/About.md",
                &target.join("About.md"),
            ).await { warn!("RD About fetch failed: {}", e); }
            info!(
                "Resource Databases wiki pages refreshed under {}",
                target.display()
            );
        }

        Ok(())
    }
}

#[derive(Args)]
pub struct SearchArgs {
    /// Case-insensitive text to search for
    pub query: String,

    /// Restrict to Rust Book mirror
    #[arg(long, default_value_t = true)]
    pub rust_book: bool,
    /// Restrict to Godot Rust GDext docs
    #[arg(long, default_value_t = true)]
    pub godot_rust: bool,
    /// Restrict to GUT docs
    #[arg(long, default_value_t = true)]
    pub gut: bool,
    /// Restrict to Resource Databases docs
    #[arg(long, default_value_t = true)]
    pub resource_databases: bool,
}

impl DocsCommand {
    async fn gen_manifest(&self, args: &GenArgs) -> Result<()> {
        let rust_book_dir = self.project_root.join("docs/rust-book/index.html");
        let gdext_dir = self.project_root.join("godot_project/docs/GODOT_RUST_GDEXT/index.html");
        let gut_dir = self.project_root.join("godot_project/docs/GUT_DOCS/gut.readthedocs.io/index.html");
        let rd_dir = self.project_root.join("godot_project/docs/ResourceDatabases/ResourceDatabases.wiki/Home.md");

        let mut items: Vec<DocEntry> = Vec::new();
        if let Some(e) = probe_doc(&rust_book_dir, "Rust Book") { items.push(e); }
        if let Some(e) = probe_doc(&gdext_dir, "Godot Rust (GDext)") { items.push(e); }
        if let Some(e) = probe_doc(&gut_dir, "GUT Docs") { items.push(e); }
        if let Some(e) = probe_doc(&rd_dir, "Resource Databases Wiki") { items.push(e); }

        let manifest = DocManifest { items };
        let out = if args.output.is_absolute() { args.output.clone() } else { self.project_root.join(&args.output) };
        if let Some(parent) = out.parent() { fs::create_dir_all(parent).await.ok(); }
        fs::write(&out, serde_json::to_string_pretty(&manifest)?).await?;
        println!("Docs manifest written: {}", out.display());
        Ok(())
    }

    async fn sync_docs(&self, args: &SyncArgs) -> Result<()> {
        let manifest_path = if args.sources.is_absolute() { args.sources.clone() } else { self.project_root.join(&args.sources) };
        let text = stdfs::read_to_string(&manifest_path)?;
        let spec: DocSources = serde_json::from_str(&text)?;

        for src in spec.sources {
            match src.kind.as_str() {
                "site" => {
                    let target = if src.target.is_absolute() { src.target.clone() } else { self.project_root.join(src.target) };
                    fetch_site_simple(&src.url, &target.as_path(), &src.hints.iter().map(|s| s.as_str()).collect::<Vec<_>>()).await?;
                    info!("fetched site {} -> {}", src.url, target.display());
                }
                "file" => {
                    let target = if src.target.is_absolute() { src.target.clone() } else { self.project_root.join(src.target) };
                    if let Some(parent) = target.parent() { fs::create_dir_all(parent).await.ok(); }
                    fetch_file(&src.url, &target).await?;
                    info!("fetched file {} -> {}", src.url, target.display());
                }
                _ => {
                    warn!("Unknown source kind: {}", src.kind);
                }
            }
        }
        Ok(())
    }

    async fn search_docs(&self, args: &SearchArgs) -> Result<()> {
        let mut roots: Vec<PathBuf> = Vec::new();
        if args.rust_book {
            roots.push(self.project_root.join("docs/rust-book"));
        }
        if args.godot_rust {
            roots.push(self.project_root.join("godot_project/docs/GODOT_RUST_GDEXT"));
        }
        if args.gut {
            roots.push(self.project_root.join("godot_project/docs/GUT_DOCS"));
        }
        if args.resource_databases {
            roots.push(self.project_root.join("godot_project/docs/ResourceDatabases"));
        }

        let needle = args.query.to_lowercase();
        let mut hits = 0usize;

        for root in roots {
            if !root.exists() { continue; }
            for entry in walkdir::WalkDir::new(&root).into_iter().filter_map(|e| e.ok()) {
                let path = entry.path();
                if path.is_file() {
                    // limit to likely text files
                    let ext_ok = match path.extension().and_then(|s| s.to_str()) {
                        Some("md") | Some("html") | Some("htm") | Some("txt") | Some("rst") => true,
                        _ => false,
                    };
                    if !ext_ok { continue; }

                    if let Ok(content) = stdfs::read_to_string(path) {
                        for (idx, line) in content.lines().enumerate() {
                            if line.to_lowercase().contains(&needle) {
                                let rel = path.strip_prefix(&self.project_root).unwrap_or(path);
                                println!("{}:{}: {}", rel.display(), idx + 1, line.trim());
                                hits += 1;
                                if hits >= 200 { // cap output to avoid flooding
                                    println!("-- output truncated (200 hits) --");
                                    return Ok(());
                                }
                            }
                        }
                    }
                }
            }
        }

        if hits == 0 { println!("No matches."); }
        Ok(())
    }
}

fn exists_status(path: &Path) -> &'static str {
    if path.exists() { "present" } else { "missing" }
}

async fn fetch_site_simple(base_url: &str, target_dir: &Path, hints: &[&str]) -> Result<()> {
    // Minimal site mirror: fetch index and a few hinted paths. Not a full crawler to keep it simple.
    fs::create_dir_all(target_dir).await.ok();

    // Always fetch index.html
    let index_url = if base_url.ends_with('/') { format!("{}index.html", base_url) } else { format!("{}/index.html", base_url) };
    let index_path = target_dir.join("index.html");
    fetch_file(&index_url, &index_path).await?;

    // Fetch hinted paths if they look like files or folders we can append
    for hint in hints {
        if hint.ends_with('/') {
            // Try a directory index
            let url = format!("{}{}index.html", base_url, hint);
            let out = target_dir.join(hint).join("index.html");
            if let Err(e) = fetch_file(&url, &out).await {
                warn!("Skipping {}: {}", url, e);
            }
        } else {
            // Treat as a single file or pattern root; try fetch directly
            let url = format!("{}{}", base_url, hint);
            let out = target_dir.join(hint);
            if let Some(parent) = out.parent() { fs::create_dir_all(parent).await.ok(); }
            if let Err(e) = fetch_file(&url, &out).await {
                warn!("Skipping {}: {}", url, e);
            }
        }
    }

    Ok(())
}

async fn fetch_file(url: &str, out_path: &Path) -> Result<()> {
    if let Some(parent) = out_path.parent() {
        fs::create_dir_all(parent).await.ok();
    }
    // 45s timeout per file, adjust as needed, with simple ETag cache file alongside
    let etag_path = out_path.with_extension("etag");
    let _ = download_file_with_etag(url, out_path, &etag_path, 45).await;
    // Fallback to plain download if etag path didn't retrieve (network or 412 etc.)
    if !out_path.exists() {
        download_file(url, out_path, 45).await?;
    }
    Ok(())
}

#[derive(Args)]
pub struct GenArgs {
    /// Output path for docs manifest JSON
    #[arg(long, default_value = "docs/manifest.json")]
    pub output: PathBuf,
}

#[derive(Args)]
pub struct SyncArgs {
    /// Sources manifest JSON (see docs/docs_sources.json)
    #[arg(long, default_value = "docs/docs_sources.json")]
    pub sources: PathBuf,
}

#[derive(Serialize, Deserialize, Default)]
struct DocManifest { items: Vec<DocEntry> }

#[derive(Serialize, Deserialize)]
struct DocEntry { title: String, path: String }

fn probe_doc(index_path: &Path, fallback_title: &str) -> Option<DocEntry> {
    if !index_path.exists() { return None; }
    let title = if let Ok(s) = stdfs::read_to_string(index_path) {
        if index_path.extension().and_then(|x| x.to_str()) == Some("html") {
            extract_title(&s).unwrap_or_else(|| fallback_title.to_string())
        } else {
            fallback_title.to_string()
        }
    } else { fallback_title.to_string() };
    Some(DocEntry{ title, path: index_path.to_string_lossy().to_string() })
}

fn extract_title(html: &str) -> Option<String> {
    // very small regex-free grab for <title> ... </title>
    let l = html.to_lowercase();
    let start = l.find("<title>")? + 7;
    let end = l[start..].find("</title>")? + start;
    Some(html[start..end].trim().to_string())
}

#[derive(Serialize, Deserialize)]
struct DocSources { sources: Vec<DocSource> }

#[derive(Serialize, Deserialize)]
struct DocSource {
    kind: String,          // "site" or "file"
    url: String,
    target: PathBuf,
    #[serde(default)]
    hints: Vec<String>,    // for site mirrors
}
