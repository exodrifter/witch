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
    pub fn new(emote: &Emote) -> WitchEmote {
        WitchEmote {
            id: emote.id.to_godot(),
            char_range: Gd::from_object(WitchRange::new(&emote.char_range)),
            code: emote.code.to_godot(),
        }
    }

    pub fn new_array(vec: &Vec<Emote>) -> Array<Gd<WitchEmote>> {
        vec.iter()
            .map(|a| Gd::from_object(WitchEmote::new(a)))
            .collect()
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
    fn new(range: &Range<usize>) -> WitchRange {
        WitchRange {
            start: i64::try_from(range.start).unwrap_or(i64::MAX),
            end: i64::try_from(range.end).unwrap_or(i64::MAX),
        }
    }
}
