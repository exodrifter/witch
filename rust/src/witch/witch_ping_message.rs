use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchPingMessage {
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchPingMessage {
    pub fn new(msg: &PingMessage) -> Self {
        Self {
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &PingMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
