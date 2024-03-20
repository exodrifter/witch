use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_badge::*;
use super::witch_emote::*;
use super::witch_irc_message::*;
use super::witch_user_basics::*;

#[derive(GodotClass)]
pub struct WitchWhisperMessage {
    #[var]
    recipient_login: GString,
    #[var]
    sender: Gd<WitchUserBasics>,
    #[var]
    message_text: GString,
    #[var]
    name_color: Color,
    #[var]
    badges: Array<Gd<WitchBadge>>,
    #[var]
    emotes: Array<Gd<WitchEmote>>,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchWhisperMessage {
    pub fn from_message(msg: &WhisperMessage) -> WitchWhisperMessage {
        WitchWhisperMessage {
            recipient_login: msg.recipient_login.to_godot(),
            sender: WitchUserBasics::new_gd(&msg.sender),
            message_text: msg.message_text.to_godot(),
            name_color: conv_color(&msg.name_color),
            badges: WitchBadge::new_array(&msg.badges),
            emotes: WitchEmote::new_array(&msg.emotes),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}
