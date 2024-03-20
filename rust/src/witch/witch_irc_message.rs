use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;

#[derive(GodotClass)]
pub struct WitchIRCMessage {
    #[var]
    tags: Dictionary,
    #[var]
    prefix: Option<Gd<WitchIRCPrefix>>,
    #[var]
    command: GString,
    #[var]
    params: Array<GString>,
}

impl WitchIRCMessage {
    pub fn from_message(msg: &IRCMessage) -> WitchIRCMessage {
        WitchIRCMessage {
            tags: msg
                .tags
                .0
                .iter()
                .map(|(k, v)| (k.to_variant(), variant_or_nil(v)))
                .collect(),
            prefix: msg.prefix.as_ref().map(|a| WitchIRCPrefix::new_gd(&a)),
            command: msg.command.to_godot(),
            params: msg.params.iter().map(|a| a.to_godot()).collect(),
        }
    }
}

#[derive(GodotClass)]
pub struct WitchIRCPrefix {
    #[var]
    nick: GString,
    #[var]
    user: GString,
    #[var]
    host: GString,
}

impl WitchIRCPrefix {
    fn new(prefix: &IRCPrefix) -> WitchIRCPrefix {
        match prefix {
            IRCPrefix::HostOnly { host } => WitchIRCPrefix {
                nick: GString::new(),
                user: GString::new(),
                host: host.to_godot(),
            },
            IRCPrefix::Full { nick, user, host } => WitchIRCPrefix {
                nick: nick.to_godot(),
                user: user.as_ref().map_or(GString::new(), |x| x.to_godot()),
                host: host.as_ref().map_or(GString::new(), |x| x.to_godot()),
            },
        }
    }

    fn new_gd(prefix: &IRCPrefix) -> Gd<WitchIRCPrefix> {
        Gd::from_object(Self::new(prefix))
    }
}
