use godot::prelude::*;
use twitch_irc::message::*;

pub fn variant_or_nil(a: &Option<impl ToGodot>) -> Variant {
    match a {
        Some(a) => a.to_variant(),
        None => Variant::nil(),
    }
}

pub fn conv_color(c: &RGBColor) -> Color {
    Color::from_rgba8(c.r, c.g, c.b, u8::MAX)
}
