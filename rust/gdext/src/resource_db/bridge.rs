use godot::prelude::*;
use crate::resource_db::types::{stats_dict, Entry};
use crate::resource_db::search::{tokenize, entry_matches};
use std::collections::HashMap;
use serde::{Serialize, Deserialize};
use godot::classes::{FileAccess};
use godot::classes::file_access::ModeFlags;

#[derive(Serialize, Deserialize)]
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
}

#[godot_api]
impl ResourceDbBridge {
    /// Scans provided root directories and updates internal stats.
    /// For Phase 1, this is a stub that verifies headless invocation.
    #[func]
    pub fn build_index(&mut self, root_dirs: PackedStringArray) -> i64 {
        // Phase 2: load entries from each root's index.json (fixtures format)
        self.collections.clear();
        self.index.clear();
        self.by_id.clear();
        let len = root_dirs.len();
        for i in 0..len {
            if let Some(root) = root_dirs.get(i) {
                let p = format!("{}/index.json", root.to_string());
                if let Some(fa) = FileAccess::open(p.as_str(), ModeFlags::READ) {
                    let s: String = fa.get_as_text().to_string();
                    if let Ok(snapshot) = serde_json::from_str::<Snapshot>(&s) {
                        for se in snapshot.entries.into_iter() {
                            let id = format!("{}.{}", se.collection, se.key);
                            let entry = Entry{
                                collection: se.collection.clone(),
                                key: se.key.clone(),
                                title: se.title,
                                tags: se.tags,
                                path: se.path,
                                refs: se.refs,
                                meta: Dictionary::new(),
                            };
                            self.by_id.insert(id, self.index.len());
                            self.index.push(entry);
                        }
                    }
                }
            }
        }
        // Rebuild collections from entries
        let mut set = std::collections::BTreeSet::<String>::new();
        for e in &self.index { set.insert(e.collection.clone()); }
        for c in set { self.collections.push(c.into()); }
        self.entry_count = self.index.len() as i64;
        self.updated_at = 0;
        self.entry_count
    }

    #[func]
    pub fn stats(&self) -> Dictionary {
        stats_dict(self.entry_count, self.collections.clone(), self.updated_at)
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
    let warnings: i64 = 0;

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

        // Build id map for ref checks
        let mut id_set: std::collections::HashSet<String> = std::collections::HashSet::new();
        for e in &self.index {
            id_set.insert(format!("{}.{}", e.collection, e.key));
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
                // warnings += 1; // keep warnings as 0 unless strict is desired later
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
        fn dfs(node: &String, adj: &HashMap<String, Vec<String>>, visited: &mut std::collections::HashSet<String>, stack: &mut Vec<String>, out: &mut Array<Variant>, err_count: &mut i64) {
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
                        // warnings would be +1 if tracked
                    }
                    dfs(n, adj, visited, stack, out, err_count);
                }
            }
            stack.pop();
        }
        let mut visited = std::collections::HashSet::<String>::new();
        for k in adj.keys() {
            let mut stack = Vec::<String>::new();
            dfs(k, &adj, &mut visited, &mut stack, &mut issues, &mut (0i64));
        }

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
    Self { base, entry_count: 0, collections: Vec::new(), updated_at: 0, index: Vec::new(), by_id: HashMap::new() }
    }
}
