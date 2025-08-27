
pub fn tokenize(query: &str) -> Vec<String> {
    query
        .split_whitespace()
        .map(|s| s.to_lowercase())
        .filter(|s| !s.is_empty())
        .collect()
}

pub fn entry_matches(tokens: &[String], title: &str, key: &str, tags: &[String]) -> bool {
    let lt = title.to_lowercase();
    let lk = key.to_lowercase();
    // Pre-lowercase tags
    let ltags: Vec<String> = tags.iter().map(|t| t.to_lowercase()).collect();
    tokens.iter().all(|t| {
        lt.contains(t) || lk.contains(t) || ltags.iter().any(|tt| tt.contains(t))
    })
}
