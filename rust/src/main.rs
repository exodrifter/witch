mod witch_irc;

pub fn main() {
    tracing_subscriber::fmt::init();

    let mut irc = witch_irc::WitchIRC::new();
    let _ = irc._join("exodrifter_".to_owned());

    loop {
        let messages = irc._poll();
        for message in messages.iter() {
            println!("Message: {:?}", message)
        }
    }
}
