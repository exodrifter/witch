use godot::prelude::*;
use twitch_irc::message::*;

use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchClearChatMessage {
    #[var]
    channel_login: GString,
    #[var]
    channel_id: GString,
    #[var]
    action: Gd<WitchClearChatAction>,
    #[var]
    server_timestamp: i64,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchClearChatMessage {
    pub fn from_message(msg: &ClearChatMessage) -> WitchClearChatMessage {
        WitchClearChatMessage {
            channel_login: msg.channel_login.to_godot(),
            channel_id: msg.channel_id.to_godot(),
            action: Gd::from_object(WitchClearChatAction::new(&msg.action)),
            server_timestamp: msg.server_timestamp.timestamp(),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}

#[derive(GodotClass)]
pub struct WitchClearChatAction {
    #[var]
    action_type: WitchClearChatActionType,
    #[var]
    user_login: GString,
    #[var]
    user_id: GString,
    #[var]
    timeout_length: i64,
}

impl WitchClearChatAction {
    fn new(action: &ClearChatAction) -> WitchClearChatAction {
        match action {
            ClearChatAction::ChatCleared => WitchClearChatAction {
                action_type: WitchClearChatActionType::ChatCleared,
                user_login: GString::new(),
                user_id: GString::new(),
                timeout_length: 0,
            },

            ClearChatAction::UserBanned {
                user_login,
                user_id,
            } => WitchClearChatAction {
                action_type: WitchClearChatActionType::UserBanned,
                user_login: user_login.to_godot(),
                user_id: user_id.to_godot(),
                timeout_length: 0,
            },

            ClearChatAction::UserTimedOut {
                user_login,
                user_id,
                timeout_length,
            } => WitchClearChatAction {
                action_type: WitchClearChatActionType::UserTimedOut,
                user_login: user_login.to_godot(),
                user_id: user_id.to_godot(),
                timeout_length: i64::try_from(timeout_length.as_secs()).unwrap_or(i64::MAX),
            },
        }
    }
}

#[derive(Var)]
#[repr(i64)]
enum WitchClearChatActionType {
    ChatCleared = 0,
    UserBanned = 1,
    UserTimedOut = 2,
}
