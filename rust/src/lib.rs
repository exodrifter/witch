use godot::prelude::*;
pub mod witch;

struct ExowitchRust;

#[gdextension]
unsafe impl ExtensionLibrary for ExowitchRust {}
