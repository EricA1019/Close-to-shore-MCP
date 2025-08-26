use godot::prelude::*;

mod hello_node;

struct GdextExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GdextExtension {}
