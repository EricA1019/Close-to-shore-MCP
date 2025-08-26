use anyhow::Result;
use std::path::{Path, PathBuf};
use tokio::io::AsyncWriteExt;
use futures_util::StreamExt;
use reqwest::header::{ETAG, IF_NONE_MATCH};

/// Download a file from a URL with timeout and retries
pub async fn download_file(url: &str, dest: &Path, timeout_secs: u64) -> Result<()> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()?;

    let response = client.get(url).send().await?;
    response.error_for_status_ref()?;

    let mut file = tokio::fs::File::create(dest).await?;
    let mut stream = response.bytes_stream();
    
    while let Some(chunk_result) = stream.next().await {
        let chunk = chunk_result?;
        file.write_all(&chunk).await?;
    }

    file.flush().await?;
    Ok(())
}

/// Download a file with simple ETag caching. Returns true if file was modified/downloaded, false on 304.
pub async fn download_file_with_etag(url: &str, dest: &Path, etag_file: &Path, timeout_secs: u64) -> Result<bool> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()?;

    // Load previous etag if present
    let prev_etag = match tokio::fs::read_to_string(etag_file).await {
        Ok(s) => Some(s.trim().to_string()),
        Err(_) => None,
    };

    let mut req = client.get(url);
    if let Some(tag) = &prev_etag {
        req = req.header(IF_NONE_MATCH, tag);
    }

    let resp = req.send().await?;

    if resp.status() == reqwest::StatusCode::NOT_MODIFIED {
        return Ok(false);
    }

    resp.error_for_status_ref()?;

    // Capture etag header (if any) before consuming body
    let new_etag: Option<String> = resp
        .headers()
        .get(ETAG)
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());

    // Write to temp then atomically move
    let tmp: PathBuf = dest.with_extension("download");
    if let Some(parent) = dest.parent() {
        tokio::fs::create_dir_all(parent).await.ok();
    }
    let mut file = tokio::fs::File::create(&tmp).await?;
    let mut stream = resp.bytes_stream();
    while let Some(chunk_result) = stream.next().await {
        let chunk = chunk_result?;
        file.write_all(&chunk).await?;
    }
    file.flush().await?;
    drop(file);
    tokio::fs::rename(&tmp, dest).await?;

    // Persist new etag if available
    if let Some(s) = new_etag {
        if let Some(parent) = etag_file.parent() { tokio::fs::create_dir_all(parent).await.ok(); }
        tokio::fs::write(etag_file, s).await.ok();
    }

    Ok(true)
}
