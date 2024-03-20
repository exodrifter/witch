use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_badge::*;
use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchUserStateMessage {
    #[var]
    channel_login: GString,
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

impl WitchUserStateMessage {
    pub fn new(msg: &UserStateMessage) -> Self {
        Self {
            channel_login: msg.channel_login.to_godot(),
            user_name: msg.user_name.to_godot(),
            badge_info: WitchBadge::new_array(&msg.badge_info),
            badges: WitchBadge::new_array(&msg.badges),
            emote_sets: msg.emote_sets.iter().map(|a| a.to_godot()).collect(),
            name_color: conv_color(&msg.name_color),
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &UserStateMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
