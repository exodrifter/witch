use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchClearChatMessage {
    #[var]
    channel_login: GString,
    #[var]
    channel_id: GString,
    #[var]
    action: Gd<RefCounted>,
    #[var]
    server_timestamp: i64,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchClearChatMessage {
    pub fn new(msg: &ClearChatMessage) -> Self {
        Self {
            channel_login: msg.channel_login.to_godot(),
            channel_id: msg.channel_id.to_godot(),
            action: conv_clear_chat_action(&msg.action),
            server_timestamp: msg.server_timestamp.timestamp(),
            source: WitchIRCMessage::new_gd(&msg.source),
        }
    }

    pub fn new_gd(msg: &ClearChatMessage) -> Gd<Self> {
        Gd::from_object(Self::new(&msg))
    }
}

#[derive(GodotClass)]
pub struct WitchChatClearedAction;

#[derive(GodotClass)]
pub struct WitchUserBannedAction {
    #[var]
    user_login: GString,
    #[var]
    user_id: GString,
}

#[derive(GodotClass)]
pub struct WitchUserTimedOutAction {
    #[var]
    user_login: GString,
    #[var]
    user_id: GString,
    #[var]
    timeout_length: i64,
}

fn conv_clear_chat_action(action: &ClearChatAction) -> Gd<RefCounted> {
    match action {
        ClearChatAction::ChatCleared =>
            Gd::from_object(WitchChatClearedAction {}).upcast(),

        ClearChatAction::UserBanned {
            user_login,
            user_id,
        } => Gd::from_object(WitchUserBannedAction {
            user_login: user_login.to_godot(),
            user_id: user_id.to_godot(),
        }).upcast(),

        ClearChatAction::UserTimedOut {
            user_login,
            user_id,
            timeout_length,
        } => Gd::from_object(WitchUserTimedOutAction {
            user_login: user_login.to_godot(),
            user_id: user_id.to_godot(),
            timeout_length: conv_u64(timeout_length.as_secs()),
        }).upcast(),
    }
}
