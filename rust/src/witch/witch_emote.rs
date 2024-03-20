use core::ops::*;
use godot::prelude::*;
use twitch_irc::message::*;

#[derive(GodotClass)]
pub struct WitchEmote {
    #[var]
    id: GString,
    #[var]
    char_range: Gd<WitchRange>,
    #[var]
    code: GString,
}

impl WitchEmote {
    pub fn new(emote: &Emote) -> Self {
        Self {
            id: emote.id.to_godot(),
            char_range: WitchRange::new_gd(&emote.char_range),
            code: emote.code.to_godot(),
        }
    }

    pub fn new_gd(emote: &Emote) -> Gd<Self> {
        Gd::from_object(Self::new(&emote))
    }

    pub fn new_array(vec: &Vec<Emote>) -> Array<Gd<Self>> {
        vec.iter().map(|a| Self::new_gd(a)).collect()
    }
}

#[derive(GodotClass)]
struct WitchRange {
    #[var]
    start: i64,
    #[var]
    end: i64,
}

impl WitchRange {
    fn new(range: &Range<usize>) -> Self {
        Self {
            start: i64::try_from(range.start).unwrap_or(i64::MAX),
            end: i64::try_from(range.end).unwrap_or(i64::MAX),
        }
    }

    fn new_gd(range: &Range<usize>) -> Gd<Self> {
        Gd::from_object(Self::new(&range))
    }
}
