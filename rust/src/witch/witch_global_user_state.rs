use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_irc_message::*;
use super::witch_badge::*;

#[derive(GodotClass)]
pub struct WitchGlobalUserStateMessage {
    #[var]
    user_id: GString,
    #[var]
    user_name: GString,
    #[var]
    badge_info: Array<Gd<WitchBadge>>,
    #[var]
    badges: Array<Gd<WitchBadge>>,
    #[var]
    emote_sets: Array<GString>,
    #[var]
    name_color: Color,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchGlobalUserStateMessage {
    pub fn from_message(msg: &GlobalUserStateMessage) -> WitchGlobalUserStateMessage {
        WitchGlobalUserStateMessage {
            user_id: msg.user_id.to_godot(),
            user_name: msg.user_name.to_godot(),
            badge_info: WitchBadge::new_array(&msg.badge_info),
            badges: WitchBadge::new_array(&msg.badges),
            emote_sets: msg.emote_sets.iter().map(|x| x.to_godot()).collect(),
            name_color: msg
                .name_color
                .map_or(Color::TRANSPARENT_WHITE, |x| conv_color(&x)),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}
