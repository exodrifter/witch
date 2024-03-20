use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_badge::*;
use super::witch_emote::*;
use super::witch_irc_message::*;
use super::witch_user_basics::*;

#[derive(GodotClass)]
pub struct WitchPrivmsgMessage {
    #[var]
    channel_login: GString,
    #[var]
    channel_id: GString,
    #[var]
    message_text: GString,
    #[var]
    is_action: bool,
    #[var]
    sender: Gd<WitchUserBasics>,
    #[var]
    badge_info: Array<Gd<WitchBadge>>,
    #[var]
    badges: Array<Gd<WitchBadge>>,
    #[var]
    bits: i64,
    #[var]
    name_color: Color,
    #[var]
    emotes: Array<Gd<WitchEmote>>,
    #[var]
    message_id: GString,
    #[var]
    server_timestamp: i64,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchPrivmsgMessage {
    pub fn new(msg: &PrivmsgMessage) -> Self {
        Self {
            channel_login: msg.channel_login.to_godot(),
            channel_id: msg.channel_id.to_godot(),
            message_text: msg.message_text.to_godot(),
            is_action: msg.is_action,
            sender: WitchUserBasics::new_gd(&msg.sender),
            badge_info: WitchBadge::new_array(&msg.badge_info),
            badges: WitchBadge::new_array(&msg.badges),
            bits: conv_u64(msg.bits.unwrap_or(0)),
            name_color: conv_color(&msg.name_color),
            emotes: WitchEmote::new_array(&msg.emotes),
            message_id: msg.message_id.to_godot(),
            server_timestamp: msg.server_timestamp.timestamp(),
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &PrivmsgMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
