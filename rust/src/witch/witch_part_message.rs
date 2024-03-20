use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchPartMessage {
    #[var]
    channel_login: GString,
    #[var]
    user_login: GString,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchPartMessage {
    pub fn from_message(msg: &PartMessage) -> WitchPartMessage {
        WitchPartMessage {
            channel_login: msg.channel_login.to_godot(),
            user_login: msg.user_login.to_godot(),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}
