//! Contains helpers for converting Rust types to those used by Godot.
use godot::prelude::*;
use twitch_irc::message::*;

/// Godot cannot handle nullable colors but none of the Twitch colors have an
/// opacity value, so we use the transparent color instead of null.
pub fn conv_color(c: &Option<RGBColor>) -> Color {
    match c {
        Some(c) => Color::from_rgba8(c.r, c.g, c.b, u8::MAX),
        None => Color::TRANSPARENT_WHITE,
    }
}

/// Godot has no unsigned integer type but we also don't expect any of our `u64`
/// values to exceed the maximum value of an `i64`.
pub fn conv_u64(n: u64) -> i64 {
    i64::try_from(n).unwrap_or(i64::MAX)
}

/// Converts any optional value into a Variant.
pub fn variant_or_nil(a: &Option<impl ToGodot>) -> Variant {
    match a {
        Some(a) => a.to_variant(),
        None => Variant::nil(),
    }
}
