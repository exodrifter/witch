class_name Witch
extends Node

enum Mode { Live, Replay }
@export var mode: Mode = Mode.Live
@export var channel: String = "exodrifter_"
@export var replay: String = ""

@onready var crash_player: AudioStreamPlayer = %CrashPlayer
@onready var listen_player: AudioStreamPlayer = %ListenPlayer
@onready var notif_player: AudioStreamPlayer = %NotifPlayer
@onready var raid_player: SoundBankPlayer = %RaidPlayer
@onready var sub_player: SoundBankPlayer = %SubPlayer
@onready var chat_log: ChatLog = $ChatLog

@onready var bits_prefab := preload("res://scenes/bit_particles/bit_particles.tscn")
@onready var emotes_prefab := preload("res://scenes/emote_particles.tscn")

# Live variables
var irc: WitchIRC
var live_irc_log: FileAccess
var live_image_cache: ImageCache

# Replay variables
var replay_irc_log: FileAccess
var replay_image_cache: ImageCache
var next_replay_line: String
var first_unix_time: float
var replay_ended: bool
var elapsed: float

func _ready():
	# Initialize based on what mode we're in
	match mode:
		Mode.Replay:
			pass
		Mode.Live:
			var now = Time.get_unix_time_from_system()
			var cutoff = now - 24*60*60
			var last_timestamp = null

			# Load all replays from the last 24 hours
			var directories = DirAccess.get_directories_at("user://replay")
			for directory in directories:
				var directory_parts = directory.split("-")
				var timestamp = Time.get_unix_time_from_datetime_dict({
					"year": directory_parts[0],
					"month": directory_parts[1],
					"day": directory_parts[2],
					"hour": directory_parts[3],
					"minute": directory_parts[4],
					"second": directory_parts[5],
				})
				var replay_path = "user://replay/{directory}/replay.txt".format({
					"directory": directory
				})

				if cutoff <= timestamp and FileAccess.file_exists(replay_path):
					var cache = ImageCache.new(
						"user://replay/{directory}/images/".format({
							"directory": directory
						}), false
					)
					cache.name = "Cache_" + directory
					add_child(cache)
					var replay_file = FileAccess.open(
						replay_path,
						FileAccess.READ
					)

					while not replay_file.eof_reached():
						var line = replay_file.get_line()
						if line == "":
							continue
						var parts = line.split(" ", true, 1)
						last_timestamp = float(parts[0])
						var next_irc = parts[1]
						var data = WitchIRC.parse(next_irc)
						process_message(data, cache, true)

			if last_timestamp != null:
				chat_log.add_notice(
					"🕒", Time.get_datetime_string_from_unix_time(floori(last_timestamp)),
					Color.DARK_SLATE_GRAY,
					Color.WHITE
				)

func _process(delta):
	match mode:
		Mode.Replay:
			# Open the replay file if we haven't already
			if replay_irc_log == null:
				if not replay.ends_with("/"):
					replay += "/"
				replay_irc_log = FileAccess.open(replay + "replay.txt", FileAccess.READ)
				replay_image_cache = ImageCache.new(replay + "images", false)
				replay_image_cache.name = "ReplayCache"
				add_child(replay_image_cache)
				if replay_irc_log != null:
					next_replay_line = replay_irc_log.get_line()
					first_unix_time = float(next_replay_line.split(" ", true, 1)[0])
					chat_log.add_notice(
						"⟲", Time.get_datetime_string_from_unix_time(floori(first_unix_time)),
						Color.YELLOW,
						Color.BLACK
					)
				elif not replay_ended:
					replay_ended = true
					chat_log.add_notice(
						"⚠", "REPLAY FAILED",
						Color.RED, Color.WHITE
					)

			if replay_ended:
				return

			# Replay lines
			while not replay_irc_log.eof_reached() and next_replay_line != "":
				var parts = next_replay_line.split(" ", true, 1)
				var next_unix = float(parts[0])
				var next_irc = parts[1]
				if first_unix_time + elapsed >= next_unix:
					var data = WitchIRC.parse(next_irc)
					process_message(data, replay_image_cache, false)
					next_replay_line = replay_irc_log.get_line()
				else:
					break

			spawn_emotes(replay_image_cache)

			# Show replay ended notice
			if replay_irc_log.eof_reached():
				replay_ended = true
				chat_log.add_notice(
					"⚠", "REPLAY ENDED",
					Color.YELLOW, Color.BLACK
				)

			elapsed += delta

		Mode.Live:
			# Connect if we haven't already
			if irc == null:
				irc = WitchIRC.new()
				irc.join(channel)

			# Make the log file if we haven't already
			if live_irc_log == null:
				var folder = "user://replay/{datetime}/".format({
					"datetime":
						Time.get_datetime_string_from_system(true)
							.replace(":", "-")
							.replace("T","-")
				})
				DirAccess.make_dir_recursive_absolute(folder)
				live_image_cache = ImageCache.new(folder + "images/", true)
				live_image_cache.name = "LiveImageCache"
				add_child(live_image_cache)
				live_irc_log = FileAccess.open(folder + "replay.txt", FileAccess.WRITE)

			# Get new messages
			var messages = irc.poll()
			for next_irc in messages:
				var data = WitchIRC.parse(next_irc)
				process_message(data, live_image_cache, false)
				live_irc_log.store_string("{time} {irc}\n".format({
					"time": Time.get_unix_time_from_system(),
					"irc": next_irc,
				}))
			live_irc_log.flush()

			spawn_emotes(live_image_cache)

#region Message Processing

func process_message(data: RefCounted, cache: ImageCache, silent: bool) -> void:
	if data is WitchClearChatMessage:
		process_clear_chat(data)
	elif data is WitchClearMessage:
		var msg := data as WitchClearMessage
		chat_log.remove_by_id(msg.channel_login, data.message_id)
	elif data is WitchJoinMessage:
		process_join(data)
	elif data is WitchPrivmsgMessage:
		process_privmsg(data, cache, silent)
	elif data is WitchUserNoticeMessage:
		process_user_notice(data, cache, silent)

func process_clear_chat(data: WitchClearChatMessage) -> void:
	match data.action.type:
		"chat_cleared":
			chat_log.remove_by_channel(data.channel_login)
			var notice: Entry = chat_log.add_notice(
				"⌫", "chat cleared",
				Color(.1, .1, .1), Color.WHITE
			)
			notice.name = "Clear Notice"
			notice.channel_login = data.channel_login
		"user_banned":
			chat_log.remove_by_user_login(
				data.channel_login,
				data.action.user_login
			)
			var notice = chat_log.add_notice(
				"🚫", "{user} banned".format({
					"user": data.action.user_login,
				}),
				Color(.1, .1, .1), Color.WHITE
			)
			notice.name = "Ban Notice"
			notice.channel_login = data.channel_login
		"user_timed_out":
			chat_log.remove_by_user_id(data.channel_login, data.action.user_id)
			var notice = chat_log.add_notice(
				"⏰", "{user} timeout {duration}s".format({
					"user": data.action.user_login,
					"duration": data.action.timeout_length,
				}),
				Color(.1, .1, .1), Color.WHITE
			)
			notice.name = "Timeout Notice"
			notice.channel_login = data.channel_login

func process_join(data: WitchJoinMessage) -> void:
	var notice = chat_log.add_notice(
		"🚪", "#{channel_login}".format({
			"channel_login": data.channel_login,
		}),
		Color.DARK_SLATE_GRAY, Color.WHITE
	)
	notice.channel_login = data.channel_login

func process_privmsg(data: WitchPrivmsgMessage, cache: ImageCache, silent: bool) -> void:
	# Check if this is a first-time chatter
	if data.source.tags.has("first-msg") and \
			data.source.tags["first-msg"] == "1":
		chat_log.add_notice(
			"✨", "{user}: {message}".format({
				"user": data.sender.name,
				"message": data.message_text
			}),
			Color.DODGER_BLUE, Color.WHITE
		).setup_with_privmsg(data)
	else:
		chat_log.add_privmsg(data, cache)

	match data.message_text.split(" ", true, 1)[0]:
		"!listen":
			if not silent:
				listen_player.play()
		"!don't":
			if not silent:
				crash_player.play()

		"!ns":
			var url = "https://exodrifter.itch.io/lost-contact"
			if not silent:
				notif_player.play()
				irc.say(channel, url)
			chat_log.add_notice("📣", url, Color.YELLOW, Color.BLACK)
		"!gd":
			var url = "https://store.steampowered.com/app/2310400/Gender_Dysphoria"
			if not silent:
				notif_player.play()
				irc.say(channel, url)
			chat_log.add_notice("📣", url, Color.YELLOW, Color.BLACK)

		"!discord":
			var url = "https://discord.com/invite/arqFQVt"
			if not silent:
				notif_player.play()
				irc.say(channel, url)
			chat_log.add_notice("📣", url, Color.YELLOW, Color.BLACK)
		"!kofi":
			var url = "https://ko-fi.com/exodrifter"
			if not silent:
				notif_player.play()
				irc.say(channel, url)
			chat_log.add_notice("📣", url, Color.YELLOW, Color.BLACK)
		"!bandcamp":
			var url = "https://music.exodrifter.space"
			if not silent:
				notif_player.play()
				irc.say(channel, url)
			chat_log.add_notice("📣", url, Color.YELLOW, Color.BLACK)
		"!patreon":
			var url = "https://www.patreon.com/exodrifter"
			if not silent:
				notif_player.play()
				irc.say(channel, url)
			chat_log.add_notice("📣", url, Color.YELLOW, Color.BLACK)

		_:
			if not silent:
				notif_player.play()

	if not silent:
		queue_emotes(data.emotes)
		spawn_bits(data.bits)

func process_user_notice(data: WitchUserNoticeMessage, cache: ImageCache, silent: bool) -> void:
	if data.event is WitchSubOrResubEvent:
		var event := data.event as WitchSubOrResubEvent
		if not silent:
			sub_player.play_random()
		chat_log.add_notice(
			"🟊", "[wave]{name} {type} {months}mo[/wave]".format({
				"name": data.sender.name,
				"type": _get_sub_plan(event.sub_plan),
				"months": event.cumulative_months,
			}),
			Color.PURPLE, Color.WHITE
		).setup_with_user_notice(data)
	elif data.event is WitchRaidEvent:
		var event := data.event as WitchRaidEvent
		if not silent:
			raid_player.play_random()
		chat_log.add_notice(
			"⚑", "[wave]{raider} +{viewers}👁[/wave]".format({
				"raider": data.sender.name,
				"viewers": event.viewer_count,
			}),
			Color.PURPLE, Color.WHITE
		).setup_with_user_notice(data)
	elif data.event is WitchSubGiftEvent:
		var event := data.event as WitchSubGiftEvent
		if not silent:
			sub_player.play_random()
		chat_log.add_notice(
			"📦", "[wave]{name} {type} {months}mo[/wave]".format({
				"name": data.sender.name,
				"type": _get_sub_plan(event.sub_plan),
				"months": event.cumulative_months,
			}),
			Color.PURPLE, Color.WHITE
		).setup_with_user_notice(data)
	elif data.event is WitchSubMysteryGiftEvent:
		var event := data.event as WitchSubGiftEvent
		chat_log.add_notice(
			"🚚", "[wave]{name} +{count}📦 {type}[/wave]".format({
				"name": data.sender.name,
				"count": event.mass_gift_count,
				"type": _get_sub_plan(event.sub_plan),
			}),
			Color.PURPLE, Color.WHITE
		).setup_with_user_notice(data)
	elif data.event is WitchAnonSubMysteryGiftEvent:
		var event := data.event as WitchAnonSubMysteryGiftEvent
		chat_log.add_notice(
			"🚚", "[wave]{name} +{count}📦 {type}[/wave]".format({
				"name": data.sender.name,
				"count": event.mass_gift_count,
				"type": _get_sub_plan(event.sub_plan),
			}),
			Color.PURPLE, Color.WHITE
		).setup_with_user_notice(data)
	elif data.event is WitchBitsBadgeTierEvent:
		var event := data.event as WitchBitsBadgeTierEvent
		chat_log.add_notice(
			"⬙", "[wave]{name} {threshold}![/wave]".format({
				"name": data.sender.name,
				"threshold": event.threshold,
			}),
			Color.PURPLE, Color.WHITE
		).setup_with_user_notice(data)
	else:
		if data.source.tags.has("msg-id") and \
				data.source.tags["msg-id"] == "announcement":
			if not silent:
				notif_player.play() # TODO: Announcement sound
				queue_emotes(data.emotes)
			chat_log.add_notice(
				"📣", "{name}: {message}".format({
					"name": data.sender.name,
					"message": data.message_text,
				}),
				_get_msg_param_color(data.source.tags["msg-param-color"]), Color.WHITE
			).setup_with_user_notice(data)
		else:
			# Treat unknown events like messages
			if data.has("message_text") and \
					data["message_text"] != null and \
					data["message_text"] != "":
				if not silent:
					notif_player.play()
					queue_emotes(data.emotes)
				chat_log.add_user_notice(data, cache)

#endregion

#region Helpers

func _get_msg_param_color(color: String) -> Color:
	match color:
		"BLUE":
			return Color.DARK_BLUE
		"GREEN":
			return Color.DARK_GREEN
		"ORANGE":
			return Color.DARK_ORANGE
		"PURPLE":
			return Color.PURPLE
		"PRIMARY":
			return Color(0.471, 0.435, 0.494) # TODO: Use channel color
		_:
			return Color(0.471, 0.435, 0.494) # TODO: Use channel color

func _get_sub_plan(sub_plan: String) -> String:
	match sub_plan:
		"Prime":
			return "prime"
		"1000":
			return "t1"
		"2000":
			return "t2"
		"3000":
			return "t3"
		_:
			return sub_plan

#endregion

#region Spawners

func spawn_bits(bits: int) -> void:
	if bits <= 0:
		return

	var emitter: GPUParticles2D = bits_prefab.instantiate()
	emitter.amount = bits
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	add_child(emitter)

var emotes_to_spawn: Dictionary = {}

func queue_emotes(emotes: Array[WitchEmote]) -> void:
	for emote in emotes:
		if emotes_to_spawn.has(emote.id):
			emotes_to_spawn[emote.id] += 1
		else:
			emotes_to_spawn[emote.id] = 1

func spawn_emotes(cache: ImageCache) -> void:
	var to_remove = []
	for emote_id in emotes_to_spawn:
		var tex = cache.get_emote(
			emote_id,
			ImageCache.ThemeMode.Dark,
			ImageCache.EmoteSize.Small
		)
		if tex != null:
			spawn_emote(tex, emotes_to_spawn[emote_id])
			to_remove.push_back(emote_id)

	for emote_id in to_remove:
		emotes_to_spawn.erase(emote_id)

func spawn_emote(emote: Texture2D, amount: int) -> void:
	if emote == null:
		return

	var emitter: GPUParticles2D = emotes_prefab.instantiate()
	emitter.texture = emote
	emitter.amount = amount
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	add_child(emitter)

#endregion
