use std::path::Path;
use walkdir::WalkDir;

/// Find files matching a pattern in a directory
pub fn find_files_with_extension(dir: &Path, extension: &str) -> Vec<std::path::PathBuf> {
    WalkDir::new(dir)
        .into_iter()
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.file_type().is_file())
        .filter(|entry| {
            entry.path()
                .extension()
                .and_then(|ext| ext.to_str())
                .map(|ext| ext == extension)
                .unwrap_or(false)
        })
        .map(|entry| entry.path().to_path_buf())
        .collect()
}
