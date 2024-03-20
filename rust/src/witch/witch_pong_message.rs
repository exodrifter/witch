use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchPongMessage {
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchPongMessage {
    pub fn new(msg: &PongMessage) -> Self {
        Self {
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &PongMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
