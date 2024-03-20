use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchPingMessage {
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchPingMessage {
    pub fn from_message(msg: &PingMessage) -> WitchPingMessage {
        WitchPingMessage {
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}
