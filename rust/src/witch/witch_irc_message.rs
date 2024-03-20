use godot::prelude::*;
use twitch_irc::message::*;

#[derive(GodotClass)]
pub struct WitchIRCMessage {
    #[var]
    tags: Dictionary,
    #[var]
    prefix: Gd<WitchIRCPrefix>,
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
                .map(|(k, v)| {
                    (
                        k.to_variant(),
                        v.as_ref().map_or(Variant::nil(), |x| x.to_variant()),
                    )
                })
                .collect(),
            prefix: Gd::from_object(match &msg.prefix {
                Some(IRCPrefix::HostOnly { host }) => WitchIRCPrefix::host_only(&host),
                Some(IRCPrefix::Full { nick, user, host }) => {
                    WitchIRCPrefix::full(&nick, &user, &host)
                }
                None => WitchIRCPrefix::none(),
            }),
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
    fn host_only(host: &String) -> WitchIRCPrefix {
        WitchIRCPrefix {
            nick: GString::new(),
            user: GString::new(),
            host: host.to_godot(),
        }
    }

    fn full(nick: &String, user: &Option<String>, host: &Option<String>) -> WitchIRCPrefix {
        WitchIRCPrefix {
            nick: nick.to_godot(),
            user: user.as_ref().map_or(GString::new(), |x| x.to_godot()),
            host: host.as_ref().map_or(GString::new(), |x| x.to_godot()),
        }
    }

    fn none() -> WitchIRCPrefix {
        WitchIRCPrefix {
            nick: GString::new(),
            user: GString::new(),
            host: GString::new(),
        }
    }
}
