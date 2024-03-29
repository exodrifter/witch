use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchNoticeMessage {
    #[var]
    channel_login: GString,
    #[var]
    message_text: GString,
    #[var]
    message_id: GString,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchNoticeMessage {
    pub fn new(msg: &NoticeMessage) -> Self {
        Self {
            channel_login: msg
                .channel_login
                .as_ref()
                .map_or(GString::new(), |a| a.to_godot()),
            message_text: msg.message_text.to_godot(),
            message_id: msg
                .message_id
                .as_ref()
                .map_or(GString::new(), |a| a.to_godot()),
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &NoticeMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}
