use godot::prelude::*;
use crate::resource_db::types::{stats_dict, Entry};
use crate::resource_db::search::{tokenize, entry_matches};
use std::collections::HashMap;
use serde::{Serialize, Deserialize};
use godot::classes::{FileAccess};
use godot::classes::file_access::ModeFlags;

#[derive(Serialize, Deserialize, Clone)]
struct SnapshotEntry {
    collection: String,
    key: String,
    title: String,
    tags: Vec<String>,
    path: String,
    #[serde(default)]
    refs: Vec<String>,
    // meta omitted for snapshot v1 for simplicity
}

#[derive(Serialize, Deserialize)]
struct Snapshot {
    entries: Vec<SnapshotEntry>,
}

#[derive(Serialize, Deserialize, Default, Clone)]
struct RootCache {
    hash: u64,
    entries: Vec<SnapshotEntry>,
}

#[derive(Serialize, Deserialize, Default)]
struct CacheManifest {
    roots: HashMap<String, RootCache>,
}

#[derive(GodotClass)]
#[class(base=RefCounted)]
pub struct ResourceDbBridge {
    #[base]
    base: Base<RefCounted>,
    entry_count: i64,
    collections: Vec<GString>,
    updated_at: i64,
    index: Vec<Entry>,
    by_id: HashMap<String, usize>,
    // Phase 5 cache/state
    use_cache: bool,
    verify_hash: f64,
    cache_manifest: CacheManifest,
    cache_hits: i64,
    cache_changed: i64,
    cache_deleted: i64,
    // Timing breakdown (ms)
    timing_discover_ms: f64,
    timing_hash_ms: f64,
    timing_parse_ms: f64,
    timing_total_ms: f64,
}

#[godot_api]
impl ResourceDbBridge {
    /// Scans provided root directories and updates internal stats.
    /// For Phase 1, this is a stub that verifies headless invocation.
    #[func]
    pub fn build_index(&mut self, root_dirs: PackedStringArray) -> i64 {
    let total_start = std::time::Instant::now();
    self.timing_discover_ms = 0.0;
    self.timing_hash_ms = 0.0;
    self.timing_parse_ms = 0.0;
    self.timing_total_ms = 0.0;
        // Phase 2+5: load entries from each root's index.json (fixtures format) with cache by file hash
        self.collections.clear();
        self.index.clear();
        self.by_id.clear();
        self.cache_hits = 0;
        self.cache_changed = 0;
        self.cache_deleted = 0;

        // Load previous manifest if present
        let cache_path = "user://resource_db_cache.json".to_string();
        if let Some(f) = FileAccess::open(cache_path.as_str(), ModeFlags::READ) {
            let s = f.get_as_text().to_string();
            if let Ok(m) = serde_json::from_str::<CacheManifest>(&s) {
                self.cache_manifest = m;
            }
        }

        let mut new_manifest = CacheManifest { roots: HashMap::new() };
        let len = root_dirs.len();
        // Track roots seen this run
        let mut seen_roots: std::collections::HashSet<String> = std::collections::HashSet::new();
        for i in 0..len {
            if let Some(root) = root_dirs.get(i) {
                let r = root.to_string();
                seen_roots.insert(r.clone());
                let p = format!("{}/index.json", r);
                // Discover + read
                let t_disc_start = std::time::Instant::now();
                if let Some(fa) = FileAccess::open(p.as_str(), ModeFlags::READ) {
                    let s: String = fa.get_as_text().to_string();
                    self.timing_discover_ms += t_disc_start.elapsed().as_secs_f64() * 1000.0;
                    // Hashing
                    let t_hash_start = std::time::Instant::now();
                    let h = hash_str(&s);
                    self.timing_hash_ms += t_hash_start.elapsed().as_secs_f64() * 1000.0;
                    let mut reused = false;
                    if self.use_cache {
                        if let Some(rc) = self.cache_manifest.roots.get(&r) {
                            if rc.hash == h {
                                // reuse cached entries
                                for se in rc.entries.iter() {
                                    let id = format!("{}.{}", se.collection, se.key);
                                    let entry = Entry{
                                        collection: se.collection.clone(),
                                        key: se.key.clone(),
                                        title: se.title.clone(),
                                        tags: se.tags.clone(),
                                        path: se.path.clone(),
                                        refs: se.refs.clone(),
                                        meta: Dictionary::new(),
                                    };
                                    self.by_id.insert(id, self.index.len());
                                    self.index.push(entry);
                                }
                                new_manifest.roots.insert(r.clone(), rc.clone());
                                self.cache_hits += 1;
                                reused = true;
                            }
                        }
                    }
                    if !reused {
                        // Parse + build entries
                        let t_parse_start = std::time::Instant::now();
                        if let Ok(snapshot) = serde_json::from_str::<Snapshot>(&s) {
                            let mut entries_copy: Vec<SnapshotEntry> = Vec::new();
                            for se in snapshot.entries.into_iter() {
                                let id = format!("{}.{}", se.collection, se.key);
                                let entry = Entry{
                                    collection: se.collection.clone(),
                                    key: se.key.clone(),
                                    title: se.title.clone(),
                                    tags: se.tags.clone(),
                                    path: se.path.clone(),
                                    refs: se.refs.clone(),
                                    meta: Dictionary::new(),
                                };
                                self.by_id.insert(id, self.index.len());
                                self.index.push(entry);
                                entries_copy.push(se);
                            }
                            new_manifest.roots.insert(r.clone(), RootCache { hash: h, entries: entries_copy });
                            self.cache_changed += 1;
                            self.timing_parse_ms += t_parse_start.elapsed().as_secs_f64() * 1000.0;
                        }
                    }
                }
            }
        }
        // Count deleted roots (present previously but not now)
        for old_root in self.cache_manifest.roots.keys() {
            if !seen_roots.contains(old_root) {
                self.cache_deleted += 1;
            }
        }
        // Save manifest
        if let Ok(json) = serde_json::to_string(&new_manifest) {
            if let Some(mut fa) = FileAccess::open(cache_path.as_str(), ModeFlags::WRITE) {
                let _ = fa.store_string(json.as_str());
            }
        }
        self.cache_manifest = new_manifest;
        // Rebuild collections from entries
        let mut set = std::collections::BTreeSet::<String>::new();
        for e in &self.index { set.insert(e.collection.clone()); }
        for c in set { self.collections.push(c.into()); }
    self.entry_count = self.index.len() as i64;
    self.timing_total_ms = total_start.elapsed().as_secs_f64() * 1000.0;
        self.updated_at = 0;
        self.entry_count
    }

    #[func]
    pub fn stats(&self) -> Dictionary {
        stats_dict(self.entry_count, self.collections.clone(), self.updated_at)
    }

    /// Configure cache usage and verification sampling rate.
    #[func]
    pub fn set_cache_options(&mut self, use_cache: bool, verify_hash: f64) {
        self.use_cache = use_cache;
        self.verify_hash = verify_hash;
    }

    /// Returns last cache stats as a Dictionary.
    #[func]
    pub fn cache_stats(&self) -> Dictionary {
        let mut d = Dictionary::new();
        d.set("hits", self.cache_hits);
        d.set("changed", self.cache_changed);
        d.set("deleted", self.cache_deleted);
        d
    }

    /// Returns timing stats from the last build_index run.
    #[func]
    pub fn timings(&self) -> Dictionary {
        let mut d = Dictionary::new();
        d.set("discover_ms", self.timing_discover_ms);
        d.set("hash_ms", self.timing_hash_ms);
        d.set("parse_ms", self.timing_parse_ms);
        d.set("total_ms", self.timing_total_ms);
        d
    }

    #[func]
    pub fn list_collections(&self) -> PackedStringArray {
        let mut arr = PackedStringArray::new();
        for c in &self.collections {
            // Push as &str to satisfy AsArg implementation
            arr.push(&*c);
        }
        arr
    }

    /// Get a single entry by id "collection.key"; returns Dictionary or null.
    #[func]
    pub fn get(&self, id: GString) -> Variant {
        let id_s = id.to_string();
        if let Some(&idx) = self.by_id.get(&id_s) {
            return self.index[idx].to_dict().to_variant();
        }
        Variant::nil()
    }

    /// Search entries by query with optional collection filter and limit.
    #[func]
    pub fn search(&self, query: GString, collection: GString, limit: i64) -> Array<Variant> {
        let tokens = tokenize(&query.to_string());
        let coll = collection.to_string();
        let mut out = Array::<Variant>::new();
        if tokens.is_empty() {
            return out;
        }
    for e in &self.index {
            if !coll.is_empty() && e.collection != coll { continue; }
            if entry_matches(&tokens, &e.title, &e.key, &e.tags) {
        let v: Variant = e.to_dict().to_variant();
        out.push(&v);
                if (out.len() as i64) >= limit && limit > 0 { break; }
            }
        }
        out
    }

    /// Save in-memory index to a JSON file.
    #[func]
    pub fn save_index(&self, path: GString) -> bool {
        let mut vec = Vec::<SnapshotEntry>::new();
        for e in &self.index {
            vec.push(SnapshotEntry{
                collection: e.collection.clone(),
                key: e.key.clone(),
                title: e.title.clone(),
                tags: e.tags.clone(),
                path: e.path.clone(),
                refs: e.refs.clone(),
            });
        }
        let json = match serde_json::to_string(&vec) { Ok(s) => s, Err(_) => return false };
        // Use Godot's FileAccess for portability
    let Some(mut fa) = FileAccess::open(path.to_string().as_str(), ModeFlags::WRITE) else { return false };
    let _ = fa.store_string(json.as_str());
        true
    }

    /// Load index from a JSON file previously saved.
    #[func]
    pub fn load_index(&mut self, path: GString) -> bool {
    let Some(fa) = FileAccess::open(path.to_string().as_str(), ModeFlags::READ) else { return false };
    let s: String = fa.get_as_text().to_string();
        let vec: Vec<SnapshotEntry> = match serde_json::from_str(&s) { Ok(v) => v, Err(_) => return false };
        self.index.clear();
        self.by_id.clear();
        self.collections.clear();
        for se in vec.into_iter() {
            let entry = Entry{
                collection: se.collection.clone(),
                key: se.key.clone(),
                title: se.title,
                tags: se.tags,
                path: se.path,
                refs: se.refs,
                meta: Dictionary::new(),
            };
            let id = format!("{}.{}", se.collection, se.key);
            self.by_id.insert(id, self.index.len());
            self.index.push(entry);
        }
        // rebuild collections list
        let mut set = std::collections::BTreeSet::<String>::new();
        for e in &self.index { set.insert(e.collection.clone()); }
        for c in set { self.collections.push(c.into()); }
        self.entry_count = self.index.len() as i64;
        true
    }

    /// Validate the in-memory index and return a structured report.
    /// Shape: { issues: Issue[], summary: { errors: i64, warnings: i64, total: i64 } }
    #[func]
    pub fn validate(&self) -> Dictionary {
    let mut issues = Array::<Variant>::new();
    let mut errors: i64 = 0;
    let mut warnings: i64 = 0;

        // DB001 Duplicate ID check
        {
            let mut seen: HashMap<String, usize> = HashMap::new();
            for e in &self.index {
                let id = format!("{}.{}", e.collection, e.key);
                if let Some(_) = seen.get(&id) {
                    let mut d = Dictionary::new();
                    d.set("level", "error");
                    d.set("code", "DB001");
                    d.set("message", format!("Duplicate id: {}", id));
                    d.set("id", id);
                    d.set("path", e.path.clone());
                    let v: Variant = d.to_variant();
                    issues.push(&v);
                    errors += 1; // DB001 is an error
                } else {
                    seen.insert(id, 1);
                }
            }
        }

        // DB004 Invalid Schema (basic checks)
        for e in &self.index {
            let mut add_issue = |msg: String, code: &str| {
                let mut d = Dictionary::new();
                d.set("level", "error");
                d.set("code", code);
                d.set("message", msg.clone());
                d.set("id", format!("{}.{}", e.collection, e.key));
                d.set("path", e.path.clone());
                let v: Variant = d.to_variant();
                issues.push(&v);
                errors += 1; // DB004 is an error
            };
            if e.collection.trim().is_empty() {
                add_issue("Missing collection".to_string(), "DB004");
            }
            if e.key.trim().is_empty() {
                add_issue("Missing key".to_string(), "DB004");
            }
            if e.title.trim().is_empty() {
                add_issue("Missing title".to_string(), "DB004");
            }
        }

        // Build id map for ref checks + by-collection map
        let mut id_set: std::collections::HashSet<String> = std::collections::HashSet::new();
        let mut by_collection: HashMap<String, Vec<&Entry>> = HashMap::new();
        for e in &self.index {
            id_set.insert(format!("{}.{}", e.collection, e.key));
            by_collection.entry(e.collection.clone()).or_default().push(e);
        }

        // DB002 Missing Reference
        for e in &self.index {
            for r in &e.refs {
                if !id_set.contains(r) {
                    let mut d = Dictionary::new();
                    d.set("level", "error");
                    d.set("code", "DB002");
                    d.set("message", format!("Missing reference {} from {}.{}", r, e.collection, e.key));
                    d.set("id", format!("{}.{}", e.collection, e.key));
                    d.set("ref_id", r.clone());
                    d.set("path", e.path.clone());
                    let v: Variant = d.to_variant();
                    issues.push(&v);
                    errors += 1;
                }
            }
        }

        // DB003 Unknown Collection (example: non-alphanumeric/underscore names)
        for e in &self.index {
            if !e.collection.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' ) {
                let mut d = Dictionary::new();
                d.set("level", "warning");
                d.set("code", "DB003");
                d.set("message", format!("Unknown collection: {}", e.collection));
                d.set("id", format!("{}.{}", e.collection, e.key));
                d.set("path", e.path.clone());
                let v: Variant = d.to_variant();
                issues.push(&v);
                warnings += 1;
            }
        }

        // DB005 Cycle detection (simple DFS over refs)
        // Build adjacency map
        let mut adj: HashMap<String, Vec<String>> = HashMap::new();
        for e in &self.index {
            let id = format!("{}.{}", e.collection, e.key);
            adj.insert(id.clone(), e.refs.clone());
        }
        // DFS with recursion stack
    fn dfs(node: &String, adj: &HashMap<String, Vec<String>>, visited: &mut std::collections::HashSet<String>, stack: &mut Vec<String>, out: &mut Array<Variant>, warn_count: &mut i64) {
            if visited.contains(node) { return; }
            visited.insert(node.clone());
            stack.push(node.clone());
            if let Some(neis) = adj.get(node) {
                for n in neis {
                    if let Some(pos) = stack.iter().position(|s| s == n) {
                        // cycle found
                        let path_vec = &stack[pos..];
                        let mut d = Dictionary::new();
                        d.set("level", "warning");
                        d.set("code", "DB005");
                        d.set("message", format!("Cyclic reference detected: {} -> {}", path_vec.join(" -> "), n));
                        let v: Variant = d.to_variant();
                        out.push(&v);
            *warn_count += 1;
                    }
            dfs(n, adj, visited, stack, out, warn_count);
                }
            }
            stack.pop();
        }
        let mut visited = std::collections::HashSet::<String>::new();
        for k in adj.keys() {
            let mut stack = Vec::<String>::new();
        dfs(k, &adj, &mut visited, &mut stack, &mut issues, &mut warnings);
        }

        // DB006 Unique key per-collection (keys must be unique within a collection)
        for (coll, entries) in &by_collection {
            let mut seen: std::collections::HashSet<&str> = std::collections::HashSet::new();
            for e in entries.iter() {
                if !seen.insert(e.key.as_str()) {
                    let mut d = Dictionary::new();
                    d.set("level", "error");
                    d.set("code", "DB006");
                    d.set("message", format!("Duplicate key '{}' in collection '{}'", e.key, coll));
                    d.set("id", format!("{}.{}", e.collection, e.key));
                    d.set("path", e.path.clone());
                    let v: Variant = d.to_variant();
                    issues.push(&v);
                    errors += 1;
                }
            }
        }

        // DB007 Cross-ref: entity.ability_ids -> abilities, entity.status_ids -> statuses, equipment -> items
        // Our snapshot does not carry typed fields, so use refs[] convention:
        // Expect refs like "abilities.X", "statuses.Y", "items.Z" from entity entries.
        for e in &self.index {
            if e.collection == "entities" {
                for r in &e.refs {
                    let parts: Vec<&str> = r.split('.').collect();
                    if parts.len() == 2 {
                        let (rcoll, _rkey) = (parts[0], parts[1]);
                        if rcoll != "abilities" && rcoll != "statuses" && rcoll != "items" {
                            let mut d = Dictionary::new();
                            d.set("level", "error");
                            d.set("code", "DB007");
                            d.set("message", format!("Entity '{}' has invalid ref '{}' (expected abilities./statuses./items.)", e.key, r));
                            d.set("id", format!("{}.{}", e.collection, e.key));
                            d.set("ref_id", r.clone());
                            d.set("path", e.path.clone());
                            let v: Variant = d.to_variant();
                            issues.push(&v);
                            errors += 1;
                        }
                    }
                }
            }
        }

        // DB008 Tile tags sanity: tiles entries must have at least one tag
        if let Some(entries) = by_collection.get("tiles") {
            for e in entries {
                if e.tags.is_empty() {
                    let mut d = Dictionary::new();
                    d.set("level", "error");
                    d.set("code", "DB008");
                    d.set("message", "Tile entry must include at least one tag (e.g., walkable)");
                    d.set("id", format!("{}.{}", e.collection, e.key));
                    d.set("path", e.path.clone());
                    let v: Variant = d.to_variant();
                    issues.push(&v);
                    errors += 1;
                }
            }
        }

        // DB009 Reserved ID format checks for new collections
        // Entities: E-###, Statuses: S-###, Tiles: T-### (3+ digits allowed)
        let re_entity = regex_lite::Regex::new(r"^E-\d{3,}$").ok();
        let re_status = regex_lite::Regex::new(r"^S-\d{3,}$").ok();
        let re_tile = regex_lite::Regex::new(r"^T-\d{3,}$").ok();
        for e in &self.index {
            match e.collection.as_str() {
                "entities" => {
                    if let Some(re) = &re_entity { if !re.is_match(&e.key) {
                        let mut d = Dictionary::new();
                        d.set("level", "warning");
                        d.set("code", "DB009");
                        d.set("message", format!("Entity key '{}' should follow E-### format", e.key));
                        d.set("id", format!("{}.{}", e.collection, e.key));
                        d.set("path", e.path.clone());
                        let v: Variant = d.to_variant();
                        issues.push(&v);
                        warnings += 1;
                    }}
                }
                "statuses" => {
                    if let Some(re) = &re_status { if !re.is_match(&e.key) {
                        let mut d = Dictionary::new();
                        d.set("level", "warning");
                        d.set("code", "DB009");
                        d.set("message", format!("Status key '{}' should follow S-### format", e.key));
                        d.set("id", format!("{}.{}", e.collection, e.key));
                        d.set("path", e.path.clone());
                        let v: Variant = d.to_variant();
                        issues.push(&v);
                        warnings += 1;
                    }}
                }
                "tiles" => {
                    if let Some(re) = &re_tile { if !re.is_match(&e.key) {
                        let mut d = Dictionary::new();
                        d.set("level", "warning");
                        d.set("code", "DB009");
                        d.set("message", format!("Tile key '{}' should follow T-### format", e.key));
                        d.set("id", format!("{}.{}", e.collection, e.key));
                        d.set("path", e.path.clone());
                        let v: Variant = d.to_variant();
                        issues.push(&v);
                        warnings += 1;
                    }}
                }
                _ => {}
            }
        }

        // DB010 Future placeholder: ensure ability/status references exist already covered by DB002; keep for expansion

    // Summary counts already tracked above; warnings reserved for future rules.
        let mut summary = Dictionary::new();
        summary.set("errors", errors);
        summary.set("warnings", warnings);
    summary.set("total", errors + warnings);

        let mut out = Dictionary::new();
    out.set("issues", issues);
        out.set("summary", summary);
        out
    }
}

#[godot_api]
impl IRefCounted for ResourceDbBridge {
    fn init(base: Base<RefCounted>) -> Self {
    Self { base, entry_count: 0, collections: Vec::new(), updated_at: 0, index: Vec::new(), by_id: HashMap::new(), use_cache: true, verify_hash: 0.0, cache_manifest: CacheManifest::default(), cache_hits: 0, cache_changed: 0, cache_deleted: 0, timing_discover_ms: 0.0, timing_hash_ms: 0.0, timing_parse_ms: 0.0, timing_total_ms: 0.0 }
    }
}

fn hash_str(s: &str) -> u64 {
    use std::hash::{Hash, Hasher};
    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    s.hash(&mut hasher);
    hasher.finish()
}
