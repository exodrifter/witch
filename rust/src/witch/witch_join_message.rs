use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchJoinMessage {
    #[var]
    channel_login: GString,
    #[var]
    user_login: GString,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchJoinMessage {
    pub fn new(msg: &JoinMessage) -> Self {
        Self {
            channel_login: msg.channel_login.to_godot(),
            user_login: msg.user_login.to_godot(),
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &JoinMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
