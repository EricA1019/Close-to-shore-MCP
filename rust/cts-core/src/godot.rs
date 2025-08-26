use std::path::PathBuf;

/// Common paths and utilities for working with Godot projects
pub struct GodotProject {
    pub root: PathBuf,
}

impl GodotProject {
    pub fn new(root: PathBuf) -> Self {
        Self { root }
    }

    pub fn project_file(&self) -> PathBuf {
        self.root.join("project.godot")
    }

    pub fn scripts_dir(&self) -> PathBuf {
        self.root.join("scripts")
    }

    pub fn scenes_dir(&self) -> PathBuf {
        self.root.join("scenes")
    }

    pub fn tests_dir(&self) -> PathBuf {
        self.root.join("tests")
    }

    pub fn addons_dir(&self) -> PathBuf {
        self.root.join("addons")
    }

    pub fn is_valid_project(&self) -> bool {
        self.project_file().exists()
    }
}
