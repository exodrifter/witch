use godot::prelude::*;
use twitch_irc::message::*;

pub fn conv_color(c: &Option<RGBColor>) -> Color {
    match c {
        Some(c) => Color::from_rgba8(c.r, c.g, c.b, u8::MAX),
        None => Color::TRANSPARENT_WHITE,
    }
}

pub fn conv_u64(n: u64) -> i64 {
    i64::try_from(n).unwrap_or(i64::MAX)
}
