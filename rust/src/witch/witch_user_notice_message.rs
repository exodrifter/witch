use godot::prelude::*;
use twitch_irc::message::*;

use super::helper::*;
use super::witch_badge::*;
use super::witch_emote::*;
use super::witch_irc_message::*;
use super::witch_user_basics::*;

#[derive(GodotClass)]
pub struct WitchUserNoticeMessage {
    #[var]
    channel_login: GString,
    #[var]
    channel_id: GString,
    #[var]
    sender: Gd<WitchUserBasics>,
    #[var]
    message_text: GString,
    #[var]
    system_message: GString,
    #[var]
    event: Option<Gd<RefCounted>>,
    #[var]
    event_id: GString,
    #[var]
    badge_info: Array<Gd<WitchBadge>>,
    #[var]
    badges: Array<Gd<WitchBadge>>,
    #[var]
    emotes: Array<Gd<WitchEmote>>,
    #[var]
    name_color: Color,
    #[var]
    message_id: GString,
    #[var]
    server_timestamp: i64,
    #[var]
    source: Gd<WitchIRCMessage>,
}

impl WitchUserNoticeMessage {
    pub fn from_message(msg: &UserNoticeMessage) -> WitchUserNoticeMessage {
        WitchUserNoticeMessage {
            channel_login: msg.channel_login.to_godot(),
            channel_id: msg.channel_id.to_godot(),
            sender: WitchUserBasics::new_gd(&msg.sender),
            message_text: msg
                .message_text
                .as_ref()
                .map_or(GString::new(), |a| a.to_godot()),
            system_message: msg.system_message.to_godot(),
            event: conv_event(&msg.event),
            event_id: msg.event_id.to_godot(),
            badge_info: WitchBadge::new_array(&msg.badge_info),
            badges: WitchBadge::new_array(&msg.badges),
            emotes: WitchEmote::new_array(&msg.emotes),
            name_color: conv_color(&msg.name_color),
            message_id: msg.message_id.to_godot(),
            server_timestamp: msg.server_timestamp.timestamp(),
            source: Gd::from_object(WitchIRCMessage::from_message(&msg.source)),
        }
    }
}

#[derive(GodotClass)]
struct WitchSubOrResubEvent {
    #[var]
    is_resub: bool,
    #[var]
    cumulative_months: i64,
    #[var]
    streak_months: i64,
    #[var]
    sub_plan: GString,
    #[var]
    sub_plan_name: GString,
}

#[derive(GodotClass)]
struct WitchRaidEvent {
    #[var]
    viewer_count: i64,
    #[var]
    profile_image_url: GString,
}

#[derive(GodotClass)]
struct WitchSubGiftEvent {
    #[var]
    is_sender_anonymous: bool,
    #[var]
    cumulative_months: i64,
    #[var]
    recipient: Gd<WitchUserBasics>,
    #[var]
    sub_plan: GString,
    #[var]
    sub_plan_name: GString,
    #[var]
    num_gifted_months: i64,
}

#[derive(GodotClass)]
struct WitchSubMysteryGiftEvent {
    #[var]
    mass_gift_count: i64,
    #[var]
    sender_total_gifts: i64,
    #[var]
    sub_plan: GString,
}

#[derive(GodotClass)]
struct WitchAnonSubMysteryGiftEvent {
    #[var]
    mass_gift_count: i64,
    #[var]
    sub_plan: GString,
}

#[derive(GodotClass)]
struct WitchGiftPaidUpgradeEvent {
    #[var]
    gifter_login: GString,
    #[var]
    gifter_name: GString,
    #[var]
    promotion: Option<Gd<WitchSubGiftPromo>>,
}

#[derive(GodotClass)]
struct WitchAnonGiftPaidUpgradeEvent {
    #[var]
    promotion: Option<Gd<WitchSubGiftPromo>>,
}

#[derive(GodotClass)]
struct WitchRitualEvent {
    #[var]
    ritual_name: GString,
}

#[derive(GodotClass)]
struct WitchBitsBadgeTierEvent {
    #[var]
    threshold: i64,
}

#[derive(GodotClass)]
struct WitchSubGiftPromo {
    #[var]
    total_gifts: i64,
    #[var]
    promo_name: GString,
}

impl WitchSubGiftPromo {
    fn new(promo: &SubGiftPromo) -> WitchSubGiftPromo {
        WitchSubGiftPromo {
            total_gifts: conv_u64(promo.total_gifts),
            promo_name: promo.promo_name.to_godot(),
        }
    }

    fn new_gd(promo: &SubGiftPromo) -> Gd<WitchSubGiftPromo> {
        Gd::from_object(Self::new(&promo))
    }
}

fn conv_event(msg: &UserNoticeEvent) -> Option<Gd<RefCounted>> {
    match msg {
        UserNoticeEvent::SubOrResub {
            is_resub,
            cumulative_months,
            streak_months,
            sub_plan,
            sub_plan_name,
        } => Some(
            Gd::from_object(WitchSubOrResubEvent {
                is_resub: *is_resub,
                cumulative_months: conv_u64(*cumulative_months),
                streak_months: streak_months.map_or(0, |a| conv_u64(a)),
                sub_plan: sub_plan.to_godot(),
                sub_plan_name: sub_plan_name.to_godot(),
            })
            .upcast(),
        ),

        UserNoticeEvent::Raid {
            viewer_count,
            profile_image_url,
        } => Some(
            Gd::from_object(WitchRaidEvent {
                viewer_count: conv_u64(*viewer_count),
                profile_image_url: profile_image_url.to_godot(),
            })
            .upcast(),
        ),

        UserNoticeEvent::SubGift {
            is_sender_anonymous,
            cumulative_months,
            recipient,
            sub_plan,
            sub_plan_name,
            num_gifted_months,
        } => Some(
            Gd::from_object(WitchSubGiftEvent {
                is_sender_anonymous: *is_sender_anonymous,
                cumulative_months: conv_u64(*cumulative_months),
                recipient: WitchUserBasics::new_gd(recipient),
                sub_plan: sub_plan.to_godot(),
                sub_plan_name: sub_plan_name.to_godot(),
                num_gifted_months: conv_u64(*num_gifted_months),
            })
            .upcast(),
        ),

        UserNoticeEvent::SubMysteryGift {
            mass_gift_count,
            sender_total_gifts,
            sub_plan,
        } => Some(
            Gd::from_object(WitchSubMysteryGiftEvent {
                mass_gift_count: conv_u64(*mass_gift_count),
                sender_total_gifts: conv_u64(*sender_total_gifts),
                sub_plan: sub_plan.to_godot(),
            })
            .upcast(),
        ),

        UserNoticeEvent::AnonSubMysteryGift {
            mass_gift_count,
            sub_plan,
        } => Some(
            Gd::from_object(WitchAnonSubMysteryGiftEvent {
                mass_gift_count: conv_u64(*mass_gift_count),
                sub_plan: sub_plan.to_godot(),
            })
            .upcast(),
        ),

        UserNoticeEvent::GiftPaidUpgrade {
            gifter_login,
            gifter_name,
            promotion,
        } => Some(
            Gd::from_object(WitchGiftPaidUpgradeEvent {
                gifter_login: gifter_login.to_godot(),
                gifter_name: gifter_name.to_godot(),
                promotion: promotion.as_ref().map(|a| WitchSubGiftPromo::new_gd(a)),
            })
            .upcast(),
        ),

        UserNoticeEvent::AnonGiftPaidUpgrade { promotion } => Some(
            Gd::from_object(WitchAnonGiftPaidUpgradeEvent {
                promotion: promotion.as_ref().map(|a| WitchSubGiftPromo::new_gd(a)),
            })
            .upcast(),
        ),

        UserNoticeEvent::Ritual { ritual_name } => Some(
            Gd::from_object(WitchRitualEvent {
                ritual_name: ritual_name.to_godot(),
            })
            .upcast(),
        ),

        UserNoticeEvent::BitsBadgeTier { threshold } => Some(
            Gd::from_object(WitchBitsBadgeTierEvent {
                threshold: conv_u64(*threshold),
            })
            .upcast(),
        ),

        _ => None,
    }
}
