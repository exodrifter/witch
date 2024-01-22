use godot::prelude::*;

struct ExowitchRust;

#[gdextension]
unsafe impl ExtensionLibrary for ExowitchRust {}

#[derive(GodotClass)]
#[class(init)]
struct Exowitch;

#[godot_api]
impl Exowitch {
    #[func]
    pub fn test() {
        godot_print!("Hello, world!"); // Prints to the Godot console
    }
}
