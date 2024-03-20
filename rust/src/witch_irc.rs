use async_trait::async_trait;
use chrono::DateTime;
use core::num::ParseIntError;
use godot::engine::file_access::*;
use godot::engine::FileAccess;
use godot::prelude::*;
use tokio::sync::mpsc::UnboundedReceiver;
use twitch_irc::ClientConfig;
use twitch_irc::login::{RefreshingLoginCredentials, TokenStorage, UserAccessToken};
use twitch_irc::message::*;
use twitch_irc::SecureTCPTransport;
use twitch_irc::transport::tcp::TCPTransport;
use twitch_irc::transport::tcp::TLS;
use twitch_irc::TwitchIRCClient;
use twitch_irc::validate::Error;

use crate::witch::conv_message;

#[derive(GodotClass)]
pub struct WitchIRC {
    // We need to hold onto this value, otherwise the incoming_messages
    // receiver will fail/exit
    _tokio_runtime: tokio::runtime::Runtime,

    client: TwitchIRCClient<SecureTCPTransport, RefreshingLoginCredentials<CustomTokenStorage>>,
    incoming_messages: UnboundedReceiver<ServerMessage>,
}

#[godot_api]
impl IRefCounted for WitchIRC {
    fn init(_: Base<RefCounted>) -> Self {
        WitchIRC::new()
    }
}

#[godot_api]
impl WitchIRC {
    #[func]
    fn join(&mut self, channel: String) -> Dictionary {
        match self._join(channel) {
            Ok(()) => dict! {
                "type": "success",
            },
            Err(Error::InvalidCharacter { login, position, character }) => dict! {
                "type": "invalid_character",
                "login": login,
                "position": usize_to_godot(position),
                "character": character.to_string(),
            },
            Err(Error::TooLong { login }) => dict! {
                "type": "too_long",
                "login": login,
            },
            Err(Error::TooShort { login }) => dict! {
                "type": "too_short",
                "login": login,
            },
        }
    }

    #[func]
    fn poll(&mut self) -> Array<Variant> {
        vec_to_array(&self._poll())
    }

    #[func]
    fn parse(source: String) -> Gd<RefCounted> {
        match WitchIRC::_parse(&source) {
            Ok(msg) => conv_message(&msg),
            Err(err) => conv_error(&err),
        }
    }

    #[func]
    fn say(&mut self, channel_login: String, message: String) -> Dictionary {
        match self._say(&channel_login, &message) {
            Ok(()) => dict! {
                "type": "success",
            },
            Err(err) => dict! {
                "type": "error",
                "error": err.to_string(),
            }
        }
    }
}

impl WitchIRC {
    pub fn new() -> Self {
        let tr = tokio::runtime::Runtime::new().unwrap();
        let (incoming_messages, client) = tr.block_on(async {
            let storage = CustomTokenStorage;
            let (client_id, client_secret) = CustomTokenStorage::load_secrets().unwrap();
            let credentials = RefreshingLoginCredentials::init(client_id, client_secret, storage);
            let config = ClientConfig::new_simple(credentials);
            let (incoming_messages, client) =
                TwitchIRCClient::<SecureTCPTransport, RefreshingLoginCredentials<CustomTokenStorage>>::new(config);
            (incoming_messages, client)
        });

        WitchIRC { _tokio_runtime: tr, incoming_messages, client }
    }

    pub fn _join(&mut self, channel: String) -> Result<(), Error> {
        self.client.join(channel)
    }

    pub fn _poll(&mut self) -> Vec<String> {
        let mut vec = Vec::new();
        while let Ok(message) = self.incoming_messages.try_recv() {
            vec.push(IRCMessage::from(message).as_raw_irc());
        }
        vec
    }

    pub fn _parse(source: &str) -> Result<ServerMessage, IRCParseError> {
        match IRCMessage::parse(source) {
            Ok(irc) => Ok(ServerMessage::try_from(irc).unwrap()),
            Err(err) => Err(err),
        }
    }

    pub fn _say(&mut self, channel_login: &str, message: &str) -> Result<(), twitch_irc::Error<TCPTransport<TLS>, RefreshingLoginCredentials<CustomTokenStorage>>> {
        self._tokio_runtime.block_on(async {
            self.client.say(channel_login.to_string(), message.to_string()).await
        })
    }
}

#[derive(GodotClass)]
struct WitchIRCParseError {
    #[var]
    error_type: GString,
}

impl WitchIRCParseError {
    fn new(str: &str) -> Self {
        Self {
            error_type: str.to_godot(),
        }
    }
}

fn conv_error(err: &IRCParseError) -> Gd<RefCounted> {
    Gd::from_object(match err {
        IRCParseError::NoSpaceAfterTags => WitchIRCParseError::new("no_space_after_tags"),
        IRCParseError::EmptyTagsDeclaration => WitchIRCParseError::new("empty_tags_declaration"),
        IRCParseError::NoSpaceAfterPrefix => WitchIRCParseError::new("no_space_after_prefix"),
        IRCParseError::EmptyPrefixDeclaration => {
            WitchIRCParseError::new("empty_prefix_declaration")
        }
        IRCParseError::MalformedCommand => WitchIRCParseError::new("malformed_command"),
        IRCParseError::TooManySpacesInMiddleParams => {
            WitchIRCParseError::new("too_many_spaces_in_middle_params")
        }
        IRCParseError::NewlinesInMessage => WitchIRCParseError::new("newlines_in_message"),
    })
    .upcast()
}

// Authentication

#[derive(Debug)]
pub struct CustomTokenStorage;

impl CustomTokenStorage {
    fn load_secrets() -> Result<(String, String), String> {
        match FileAccess::open("user://secrets.txt".into(), ModeFlags::READ) {
            None => Err("Cannot open file".to_owned()),
            Some(file) => {
                let client_id = file.get_line().to_string();
                let client_secret = file.get_line().to_string();
                Ok((client_id, client_secret))
            }
        }
    }
}

#[async_trait]
impl TokenStorage for CustomTokenStorage {
    type LoadError = String;
    type UpdateError = String;

    async fn load_token(&mut self) -> Result<UserAccessToken, Self::LoadError> {
        match FileAccess::open("user://tokens.txt".into(), ModeFlags::READ) {
            None => Err("Cannot open file".to_owned()),
            Some(file) => {
                let access_token = file.get_line();
                let refresh_token = file.get_line();
                let created_at = str::parse::<i64>(&file.get_line().to_string())
                    .map_err(|x: ParseIntError| x.to_string())
                    .map(|x| DateTime::from_timestamp(x, 0))?
                    .unwrap();
                let expires_at = str::parse(&file.get_line().to_string())
                    .map_err(|x: ParseIntError| x.to_string())?;
                let expires_at = {
                    if expires_at < 0 {
                        None
                    }
                    else {
                        DateTime::from_timestamp(expires_at, 0)
                    }
                };

                Ok(UserAccessToken {
                    access_token: access_token.to_string(),
                    refresh_token: refresh_token.to_string(),
                    created_at,
                    expires_at,
                })
            },
        }
    }

    async fn update_token(&mut self, token: &UserAccessToken) -> Result<(), Self::UpdateError> {
        match FileAccess::open("user://tokens.txt".into(), ModeFlags::WRITE) {
            None => Err("Cannot open file".to_owned()),
            Some(mut file) => {
                file.store_line(token.access_token.clone().into());
                file.store_line(token.refresh_token.clone().into());
                file.store_line(token.created_at.timestamp().to_string().into());
                file.store_line(token.expires_at.map(|t| t.timestamp()).unwrap_or(-1).to_string().into());
                Ok(())
            },
        }
    }
}

// Helpers

fn usize_to_godot(n: usize) -> u64 {
    u64::try_from(n).unwrap_or(u64::MAX)
}

fn vec_to_array(vec: &Vec<impl ToGodot>) -> Array<Variant> {
    vec.iter().map(|a| a.to_variant()).collect()
}
