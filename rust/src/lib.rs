use godot::prelude::*;
pub mod witch_irc;

struct ExowitchRust;

#[gdextension]
unsafe impl ExtensionLibrary for ExowitchRust {}
