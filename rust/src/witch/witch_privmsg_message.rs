use godot::prelude::*;
use std::ops::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_badge::*;
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
    pub fn from_message(msg: &PrivmsgMessage) -> WitchPrivmsgMessage {
        WitchPrivmsgMessage {
            channel_login: msg.channel_login.to_godot(),
            channel_id: msg.channel_id.to_godot(),
            message_text: msg.message_text.to_godot(),
            is_action: msg.is_action,
            sender: Gd::from_object(WitchUserBasics::new(&msg.sender)),
            badge_info: WitchBadge::new_array(&msg.badge_info),
            badges: WitchBadge::new_array(&msg.badges),
            bits: i64::try_from(msg.bits.unwrap_or(0)).unwrap_or(i64::MAX),
            name_color: conv_color(&msg.name_color),
            emotes: WitchEmote::new_array(&msg.emotes),
            message_id: msg.message_id.to_godot(),
            server_timestamp: msg.server_timestamp.timestamp(),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}

#[derive(GodotClass)]
struct WitchEmote {
    #[var]
    id: GString,
    #[var]
    char_range: Gd<WitchRange>,
    #[var]
    code: GString,
}

impl WitchEmote {
    pub fn new(emote: &Emote) -> WitchEmote {
        WitchEmote {
            id: emote.id.to_godot(),
            char_range: Gd::from_object(WitchRange::new(&emote.char_range)),
            code: emote.code.to_godot(),
        }
    }

    pub fn new_array(vec: &Vec<Emote>) -> Array<Gd<WitchEmote>> {
        vec.iter()
            .map(|a| Gd::from_object(WitchEmote::new(a)))
            .collect()
    }
}

#[derive(GodotClass)]
struct WitchRange {
    #[var]
    start: i64,
    #[var]
    end: i64,
}

impl WitchRange {
    fn new(range: &Range<usize>) -> WitchRange {
        WitchRange {
            start: i64::try_from(range.start).unwrap_or(i64::MAX),
            end: i64::try_from(range.end).unwrap_or(i64::MAX),
        }
    }
}
