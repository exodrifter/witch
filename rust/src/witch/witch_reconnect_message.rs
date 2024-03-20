use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchReconnectMessage {
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchReconnectMessage {
    pub fn from_message(msg: &ReconnectMessage) -> WitchReconnectMessage {
        WitchReconnectMessage {
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}
