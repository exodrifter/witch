use godot::prelude::*;
use twitch_irc::message::*;

#[derive(GodotClass)]
pub struct WitchBadge {
    #[var]
    name: GString,
    #[var]
    version: GString,
}

impl WitchBadge {
    pub fn new(badge: &Badge) -> WitchBadge {
        WitchBadge {
            name: badge.name.to_godot(),
            version: badge.version.to_godot(),
        }
    }

    pub fn new_array(vec: &Vec<Badge>) -> Array<Gd<WitchBadge>> {
        vec.iter()
            .map(|a| Gd::from_object(WitchBadge::new(a)))
            .collect()
    }
}
