use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_irc_message::*;

#[derive(GodotClass)]
pub struct WitchRoomStateMessage {
    #[var]
    channel_login: GString,
    #[var]
    channel_id: GString,
    #[var]
    emote_only: WitchToggle,
    #[var]
    followers_only: Option<Gd<WitchFollowersOnlyMode>>,
    #[var]
    r9k: WitchToggle,
    #[var]
    slow_mode: i64,
    #[var]
    subscribers_only: WitchToggle,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchRoomStateMessage {
    pub fn from_message(msg: &RoomStateMessage) -> WitchRoomStateMessage {
        WitchRoomStateMessage {
            channel_login: msg.channel_login.to_godot(),
            channel_id: msg.channel_id.to_godot(),
            emote_only: WitchToggle::new(&msg.emote_only),
            followers_only: msg
                .follwers_only
                .as_ref()
                .map(|a| WitchFollowersOnlyMode::new_gd(&a)),
            r9k: WitchToggle::new(&msg.r9k),
            slow_mode: msg.slow_mode.map_or(0, |a| conv_u64(a.as_secs())),
            subscribers_only: WitchToggle::new(&msg.subscribers_only),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}

#[derive(Var)]
#[repr(i64)]
enum WitchToggle {
    Same = 0,
    False = 1,
    True = 2,
}

impl WitchToggle {
    fn new(a: &Option<bool>) -> WitchToggle {
        match a {
            Some(true) => WitchToggle::True,
            Some(false) => WitchToggle::False,
            None => WitchToggle::Same,
        }
    }
}

#[derive(GodotClass)]
struct WitchFollowersOnlyMode {
    #[var]
    enabled: bool,
    #[var]
    duration: i64,
}

impl WitchFollowersOnlyMode {
    fn new(a: &FollowersOnlyMode) -> WitchFollowersOnlyMode {
        match a {
            FollowersOnlyMode::Disabled => WitchFollowersOnlyMode {
                enabled: false,
                duration: 0,
            },
            FollowersOnlyMode::Enabled(duration) => WitchFollowersOnlyMode {
                enabled: true,
                duration: conv_u64(duration.as_secs()),
            },
        }
    }

    fn new_gd(a: &FollowersOnlyMode) -> Gd<WitchFollowersOnlyMode> {
        Gd::from_object(Self::new(&a))
    }
}
