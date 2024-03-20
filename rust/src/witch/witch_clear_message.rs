use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchClearMessage {
    #[var]
    channel_login: GString,
    #[var]
    sender_login: GString,
    #[var]
    message_id: GString,
    #[var]
    message_text: GString,
    #[var]
    is_action: bool,
    #[var]
    server_timestamp: i64,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchClearMessage {
    pub fn new(msg: &ClearMsgMessage) -> Self {
        Self {
            channel_login: msg.channel_login.to_godot(),
            sender_login: msg.sender_login.to_godot(),
            message_id: msg.message_id.to_godot(),
            message_text: msg.message_text.to_godot(),
            is_action: msg.is_action,
            server_timestamp: msg.server_timestamp.timestamp(),
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &ClearMsgMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
