use godot::prelude::*;
use twitch_irc::message::*;

#[derive(GodotClass)]
pub struct WitchUserBasics {
    #[var]
    id: GString,
    #[var]
    login: GString,
    #[var]
    name: GString,
}

impl WitchUserBasics {
    pub fn new(sender: &TwitchUserBasics) -> WitchUserBasics {
        WitchUserBasics {
            id: sender.id.to_godot(),
            login: sender.id.to_godot(),
            name: sender.name.to_godot(),
        }
    }
}
