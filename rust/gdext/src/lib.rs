use godot::prelude::*;

mod hello_node;
mod resource_db;
#[allow(unused_imports)]
use resource_db::bridge::ResourceDbBridge; // referenced so Godot registers it

struct GdextExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GdextExtension {}
