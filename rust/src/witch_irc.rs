use godot::prelude::*;
use std::collections::*;
use tokio::sync::mpsc::UnboundedReceiver;
use twitch_irc::ClientConfig;
use twitch_irc::login::StaticLoginCredentials;
use twitch_irc::message::*;
use twitch_irc::message::ClearChatAction::*;
use twitch_irc::message::ServerMessage::*;
use twitch_irc::SecureTCPTransport;
use twitch_irc::TwitchIRCClient;
use twitch_irc::validate::Error;

#[derive(GodotClass)]
pub struct WitchIRC {
    // We need to hold onto this value, otherwise the incoming_messages
    // receiver will fail/exit
    _tokio_runtime: tokio::runtime::Runtime,

    client: TwitchIRCClient<SecureTCPTransport, StaticLoginCredentials>,
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
    fn poll(&mut self) -> Array<Dictionary> {
        self._poll().iter().map(conv_message).collect()
    }
}

impl WitchIRC {
    pub fn new() -> Self {
        let tr = tokio::runtime::Runtime::new().unwrap();
        let (incoming_messages, client) = tr.block_on(async {
            let config = ClientConfig::default();
            let (incoming_messages, client) =
                TwitchIRCClient::<SecureTCPTransport, StaticLoginCredentials>::new(config);
            (incoming_messages, client)
        });

        WitchIRC { _tokio_runtime: tr, incoming_messages, client }
    }

    pub fn _join(&mut self, channel: String) -> Result<(), Error> {
        self.client.join(channel)
    }

    pub fn _poll(&mut self) -> Vec<ServerMessage> {
        let mut vec = Vec::new();
        while let Ok(message) = self.incoming_messages.try_recv() {
            vec.push(message);
        }
        vec
    }
}

fn conv_message(msg: &ServerMessage) -> Dictionary {
    match msg {
        ClearChat(msg) => dict! {
            "type": "clear_chat",
            "channel_login": msg.channel_login.to_variant(),
            "channel_id": msg.channel_id.to_variant(),
            "action": match &msg.action {
                ChatCleared => dict! {
                    "type": "chat_cleared"
                },
                UserBanned {user_login, user_id} => dict! {
                    "type": "user_banned",
                    "user_login": user_login.to_variant(),
                    "user_id": user_id.to_variant(),
                },
                ClearChatAction::UserTimedOut { user_login, user_id, timeout_length } => dict! {
                    "type": "user_timed_out",
                    "user_login": user_login.to_variant(),
                    "user_id": user_id.to_variant(),
                    "timeout_length": timeout_length.as_secs(),
                },
            },
            "server_timestamp": msg.server_timestamp.timestamp(),
            "source": conv_source(&msg.source)
        },
        ClearMsg(msg) => dict! {
            "type": "clear_msg",
            "channel_login": msg.channel_login.to_variant(),
            "sender_login": msg.sender_login.to_variant(),
            "message_id": msg.message_id.to_variant(),
            "message_text": msg.message_text.to_variant(),
            "is_action": msg.is_action,
            "server_timestamp": msg.server_timestamp.timestamp(),
            "source": conv_source(&msg.source)
        },
        GlobalUserState(msg) => dict!{
            "type": "global_user_state",
            "user_id": msg.user_id.to_variant(),
            "user_name": msg.user_name.to_variant(),
            "badge_info": map_vec_to_array(&msg.badge_info, &conv_badge),
            "badges": map_vec_to_array(&msg.badges, &conv_badge),
            "emote_sets": hashset_to_array(&msg.emote_sets),
            "name_color": conv_or_nil(&msg.name_color, &conv_color),
            "source": conv_source(&msg.source)
        },
        Join(msg) => dict! {
            "type": "join",
            "channel_login": msg.channel_login.to_variant(),
            "user_login": msg.user_login.to_variant(),
            "source": conv_source(&msg.source)
        },
        Notice(msg) => dict! {
            "type": "notice",
            "channel_login": variant_or_nil(&msg.channel_login),
            "message_text": msg.message_text.to_variant(),
            "message_id": variant_or_nil(&msg.message_id),
            "source": conv_source(&msg.source)
        },
        Part(msg) => dict! {
            "type": "part",
            "channel_login": msg.channel_login.to_variant(),
            "user_login": msg.user_login.to_variant(),
            "source": conv_source(&msg.source)
        },
        Ping(msg) => dict!{
            "type": "ping",
            "source": conv_source(&msg.source),
        },
        Pong(msg) => dict!{
            "type": "pong",
            "source": conv_source(&msg.source),
        },
        Privmsg(msg) => dict!{
            "type": "privmsg",
            "channel_login": msg.channel_login.to_variant(),
            "channel_id": msg.channel_id.to_variant(),
            "message_text": msg.message_text.to_variant(),
            "is_action": msg.is_action,
            "sender": conv_sender(&msg.sender),
            "badge_info": map_vec_to_array(&msg.badge_info, &conv_badge),
            "badges": map_vec_to_array(&msg.badges, &conv_badge),
            "bits": variant_or_nil(&msg.bits),
            "name_color": conv_or_nil(&msg.name_color, &conv_color),
            "emotes": map_vec_to_array(&msg.emotes, &conv_emote),
            "message_id": msg.message_id.to_variant(),
            "server_timestamp": msg.server_timestamp.timestamp(),
            "source": conv_source(&msg.source)
        },
        Reconnect(msg) => dict!{
            "type": "reconnect",
            "source": conv_source(&msg.source)
        },
        RoomState(msg) => dict!{
            "type": "room_state",
            "channel_login": msg.channel_login.to_variant(),
            "channel_id": msg.channel_id.to_variant(),
            "emote_only": variant_or_nil(&msg.emote_only),
            "followers_only": conv_or_nil(&msg.follwers_only, &conv_follwers_only),
            "r9k": variant_or_nil(&msg.r9k),
            "slow_mode": conv_or_nil(&msg.slow_mode, &|a| a.as_secs()),
            "subscribers_only": variant_or_nil(&msg.subscribers_only),
            "source": conv_source(&msg.source)
        },
        UserNotice(msg) => dict!{
            "type": "user_notice",
            "channel_login": msg.channel_login.to_variant(),
            "channel_id": msg.channel_id.to_variant(),
            "sender": conv_sender(&msg.sender),
            "message_text": variant_or_nil(&msg.message_text),
            "system_message": msg.system_message.to_variant(),
            "event": conv_event(&msg.event),
            "event_id": msg.event_id.to_variant(),
            "badge_info": map_vec_to_array(&msg.badge_info, &conv_badge),
            "badges": map_vec_to_array(&msg.badges, &conv_badge),
            "emotes": map_vec_to_array(&msg.emotes, &conv_emote),
            "name_color": conv_or_nil(&msg.name_color, &conv_color),
            "message_id": msg.message_id.to_variant(),
            "server_timestamp": msg.server_timestamp.timestamp(),
            "source": conv_source(&msg.source)
        },
        UserState(msg) => dict!{
            "type": "user_state",
            "channel_login": msg.channel_login.to_variant(),
            "user_name": msg.user_name.to_variant(),
            "badge_info": map_vec_to_array(&msg.badge_info, &conv_badge),
            "badges": map_vec_to_array(&msg.badges, &conv_badge),
            "emote_sets": hashset_to_array(&msg.emote_sets),
            "name_color": conv_or_nil(&msg.name_color, &conv_color),
            "source": conv_source(&msg.source)
        },
        Whisper(msg) => dict!{
            "type": "whisper",
            "recipient_login": msg.recipient_login.to_variant(),
            "sender": conv_sender(&msg.sender),
            "message_text": msg.message_text.to_variant(),
            "name_color": conv_or_nil(&msg.name_color, &conv_color),
            "badges": map_vec_to_array(&msg.badges, &conv_badge),
            "emotes": map_vec_to_array(&msg.emotes, &conv_emote),
            "source": conv_source(&msg.source)
        },
        msg => dict! {
            "type": "unknown",
            "source": conv_source(&IRCMessage::from(msg.clone())),
        }
    }
}

fn conv_badge(badge: &Badge) -> Dictionary {
    dict! {
        "name": badge.name.to_variant(),
        "version": badge.version.to_variant(),
    }
}

fn conv_color(c: &RGBColor) -> Color {
    Color::from_rgba8(c.r, c.g, c.b, u8::MAX)
}

fn conv_emote(emote: &Emote) -> Dictionary {
    dict! {
        "id": emote.id.to_variant(),
        "char_range": dict! {
            "start": usize_to_godot(emote.char_range.start),
            "end": usize_to_godot(emote.char_range.end),
        },
        "code": emote.code.to_variant(),
    }
}

fn conv_event(notice: &UserNoticeEvent) -> Dictionary {
    match notice {
        UserNoticeEvent::SubOrResub{is_resub, cumulative_months, streak_months, sub_plan, sub_plan_name} => dict!{
            "type": "sub_or_resub",
            "is_resub": is_resub.to_variant(),
            "cumulative_months": cumulative_months.to_variant(),
            "streak_months": variant_or_nil(streak_months),
            "sub_plan": sub_plan.to_variant(),
            "sub_plan_name": sub_plan_name.to_variant(),
        },
        UserNoticeEvent::Raid{viewer_count, profile_image_url} => dict!{
            "type": "raid",
            "viewer_count": viewer_count.to_variant(),
            "profile_image_url": profile_image_url.to_variant(),
        },
        UserNoticeEvent::SubGift{is_sender_anonymous, cumulative_months, recipient, sub_plan, sub_plan_name, num_gifted_months} => dict!{
            "type": "sub_gift",
            "is_sender_anonymous": is_sender_anonymous.to_variant(),
            "cumulative_months": cumulative_months.to_variant(),
            "recipient": conv_sender(recipient),
            "sub_plan": sub_plan.to_variant(),
            "sub_plan_name": sub_plan_name.to_variant(),
            "num_gifted_months": num_gifted_months.to_variant(),
        },
        UserNoticeEvent::SubMysteryGift{mass_gift_count, sender_total_gifts, sub_plan} => dict!{
            "type": "sub_mystery_gift",
            "mass_gift_count": mass_gift_count.to_variant(),
            "sender_total_gifts": sender_total_gifts.to_variant(),
            "sub_plan": sub_plan.to_variant(),
        },
        UserNoticeEvent::AnonSubMysteryGift{mass_gift_count, sub_plan} => dict!{
            "type": "anon_sub_mystery_gift",
            "mass_gift_count": mass_gift_count.to_variant(),
            "sub_plan": sub_plan.to_variant(),
        },
        UserNoticeEvent::GiftPaidUpgrade{gifter_login, gifter_name, promotion} => dict!{
            "type": "gift_paid_upgrade",
            "gifter_login": gifter_login.to_variant(),
            "gifter_name": gifter_name.to_variant(),
            "promotion": conv_or_nil(promotion, &conv_promotion)
        },
        UserNoticeEvent::AnonGiftPaidUpgrade{promotion} => dict!{
            "type": "anon_gift_paid_upgrade",
            "promotion": conv_or_nil(promotion, &conv_promotion)
        },
        UserNoticeEvent::Ritual{ritual_name} => dict!{
            "type": "ritual",
            "ritual_name": ritual_name.to_variant(),
        },
        UserNoticeEvent::BitsBadgeTier{threshold} => dict!{
            "type": "bits_badge_tier",
            "threshold": threshold.to_variant(),
        },
        _ => dict!{
            "type": "unknown",
        }
    }
}

fn conv_follwers_only(mode: &FollowersOnlyMode) -> Dictionary {
    match mode {
        FollowersOnlyMode::Disabled => dict! {
            "type": "disabled",
        },
        FollowersOnlyMode::Enabled(duration) => dict! {
            "type": "enabled",
            "duration": duration.as_secs(),
        },
    }
}

fn conv_irc_prefix(prefix: &IRCPrefix) -> Dictionary {
    match prefix {
        IRCPrefix::HostOnly {host} => dict! {
            "type": "host_only",
            "host": host.to_variant(),
        },
        IRCPrefix::Full {nick, user, host} => dict! {
            "type": "full",
            "nick": nick.to_variant(),
            "user": variant_or_nil(user),
            "host": variant_or_nil(host),
        },
    }
}

fn conv_irc_tags(tags: &IRCTags) -> Dictionary {
    tags.0.iter().map(|(k,v)| (k.to_variant(), variant_or_nil(v))).collect()
}

fn conv_promotion(promo: &SubGiftPromo) -> Dictionary {
    dict!{
        "total_gifts": promo.total_gifts.to_variant(),
        "promo_name": promo.promo_name.to_variant(),
    }
}

fn conv_sender(sender: &TwitchUserBasics) -> Dictionary {
    dict! {
        "id": sender.id.to_variant(),
        "login": sender.id.to_variant(),
        "name": sender.name.to_variant(),
    }
}

fn conv_source(source: &IRCMessage) -> Dictionary {
    dict! {
        "tags": conv_irc_tags(&source.tags),
        "prefix": conv_or_nil(&source.prefix, &conv_irc_prefix),
        "command": source.command.to_variant(),
        "params": vec_to_array(&source.params),
    }
}

// Helpers

fn usize_to_godot(n: usize) -> u64 {
    u64::try_from(n).unwrap_or(u64::MAX)
}

fn conv_or_nil<T, V: ToGodot>(a: &Option<T>, func: &dyn Fn(&T) -> V) -> Variant {
    match a {
        Some(a) => func(a).to_variant(),
        None => Variant::nil(),
    }
}

fn variant_or_nil(a: &Option<impl ToGodot>) -> Variant {
    match a {
        Some(a) => a.to_variant(),
        None => Variant::nil(),
    }
}

fn hashset_to_array(hashset: &HashSet<impl ToGodot>) -> Array<Variant> {
    hashset.iter().map(|a| a.to_variant()).collect()
}

fn vec_to_array(vec: &Vec<impl ToGodot>) -> Array<Variant> {
    vec.iter().map(|a| a.to_variant()).collect()
}

fn map_vec_to_array<T, V: ToGodot>(vec: &Vec<T>, func: &dyn Fn(&T) -> V) -> Array<Variant> {
    vec.iter().map(|a| func(a).to_variant()).collect()
}
