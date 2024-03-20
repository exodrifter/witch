use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchReconnectMessage {
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchReconnectMessage {
    pub fn new(msg: &ReconnectMessage) -> Self {
        Self {
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &ReconnectMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
