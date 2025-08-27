use godot::prelude::*;

#[derive(Clone, Debug)]
pub struct Entry {
    pub collection: String,
    pub key: String,
    pub title: String,
    pub tags: Vec<String>,
    pub path: String,
    pub refs: Vec<String>,
    pub meta: Dictionary,
}

impl Entry {
    pub fn to_dict(&self) -> Dictionary {
        let mut d = Dictionary::new();
        d.set("collection", self.collection.clone());
        d.set("key", self.key.clone());
        d.set("title", self.title.clone());
        let mut arr = Array::<GString>::new();
        for t in &self.tags {
            arr.push(t.as_str());
        }
        d.set("tags", arr);
        d.set("path", self.path.clone());
        let mut rarr = Array::<GString>::new();
        for r in &self.refs {
            rarr.push(r.as_str());
        }
        d.set("refs", rarr);
        d.set("meta", self.meta.clone());
        d
    }
}

#[derive(Clone, Debug)]
pub struct Issue {
    pub level: String,  // "error" | "warning"
    pub code: String,
    pub message: String,
    pub path: String,
    pub ref_id: Option<String>,
}

pub fn stats_dict(total_entries: i64, collections: Vec<GString>, updated_at: i64) -> Dictionary {
    let mut d = Dictionary::new();
    d.set("total_entries", total_entries);
    let mut arr = Array::<GString>::new();
    for c in collections {
        let owned: String = c.to_string();
        arr.push(owned.as_str());
    }
    d.set("collections", arr);
    d.set("updated_at", updated_at);
    d
}
