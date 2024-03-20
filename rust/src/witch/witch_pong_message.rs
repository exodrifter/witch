use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchPongMessage {
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchPongMessage {
    pub fn from_message(msg: &PongMessage) -> WitchPongMessage {
        WitchPongMessage {
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}
