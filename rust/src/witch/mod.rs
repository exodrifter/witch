mod helper;
pub mod witch_badge;
pub mod witch_clear_chat_message;
pub mod witch_clear_message;
pub mod witch_emote;
pub mod witch_global_user_state_message;
pub mod witch_irc_message;
pub mod witch_join_message;
pub mod witch_notice_message;
pub mod witch_part_message;
pub mod witch_ping_message;
pub mod witch_pong_message;
pub mod witch_privmsg_message;
pub mod witch_reconnect_message;
pub mod witch_room_state_message;
pub mod witch_user_basics;
pub mod witch_user_notice_message;
pub mod witch_user_state_message;
pub mod witch_whisper_message;

pub use witch_badge::*;
pub use witch_clear_chat_message::*;
pub use witch_clear_message::*;
pub use witch_emote::*;
pub use witch_global_user_state_message::*;
pub use witch_irc_message::*;
pub use witch_join_message::*;
pub use witch_notice_message::*;
pub use witch_part_message::*;
pub use witch_ping_message::*;
pub use witch_pong_message::*;
pub use witch_privmsg_message::*;
pub use witch_reconnect_message::*;
pub use witch_room_state_message::*;
pub use witch_user_basics::*;
pub use witch_user_notice_message::*;
pub use witch_user_state_message::*;
pub use witch_whisper_message::*;

use godot::prelude::*;
use twitch_irc::message::*;

pub fn conv_message(msg: &ServerMessage) -> Gd<RefCounted> {
    match msg {
        ServerMessage::ClearChat(msg) => WitchClearChatMessage::new_gd(msg).upcast(),
        ServerMessage::ClearMsg(msg) => WitchClearMessage::new_gd(msg).upcast(),
        ServerMessage::GlobalUserState(msg) => WitchGlobalUserStateMessage::new_gd(msg).upcast(),
        ServerMessage::Join(msg) => WitchJoinMessage::new_gd(msg).upcast(),
        ServerMessage::Notice(msg) => WitchNoticeMessage::new_gd(msg).upcast(),
        ServerMessage::Part(msg) => WitchPartMessage::new_gd(msg).upcast(),
        ServerMessage::Ping(msg) => WitchPingMessage::new_gd(msg).upcast(),
        ServerMessage::Pong(msg) => WitchPongMessage::new_gd(msg).upcast(),
        ServerMessage::Privmsg(msg) => WitchPrivmsgMessage::new_gd(msg).upcast(),
        ServerMessage::Reconnect(msg) => WitchReconnectMessage::new_gd(msg).upcast(),
        ServerMessage::RoomState(msg) => WitchRoomStateMessage::new_gd(msg).upcast(),
        ServerMessage::UserNotice(msg) => WitchUserNoticeMessage::new_gd(msg).upcast(),
        ServerMessage::UserState(msg) => WitchUserStateMessage::new_gd(msg).upcast(),
        ServerMessage::Whisper(msg) => WitchWhisperMessage::new_gd(msg).upcast(),
        msg => WitchIRCMessage::new_gd(&IRCMessage::from(msg.clone())).upcast(),
    }
}
