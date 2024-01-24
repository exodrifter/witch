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

func process_message(data: Dictionary, cache: ImageCache, silent: bool) -> void:
	match data.type:
		"clear_chat":
			process_clear_chat(data)
		"clear_msg":
			chat_log.remove_by_id(data.channel_login, data.message_id)
		"join":
			process_join(data)

		"privmsg":
			chat_log.add_message(data, cache).setup_with_privmsg(data)

			if not silent:
				match data.message_text.split(" ", true, 1)[0]:
					"!listen":
						listen_player.play()
					"!don't":
						crash_player.play()
					_:
						notif_player.play()

				queue_emotes(data)
				if data.has("bits") and data.bits != null:
					spawn_bits(data.bits)

		"user_notice":
			process_user_notice(data, cache, silent)

func process_clear_chat(data: Dictionary) -> void:
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

func process_join(data: Dictionary) -> void:
	var notice = chat_log.add_notice(
		"🚪", "#{channel_login} {user_login}".format({
			"channel_login": data.channel_login,
			"user_login": data.user_login,
		}),
		Color.DARK_SLATE_GRAY, Color.WHITE
	)
	notice.channel_login = data.channel_login

func process_user_notice(data: Dictionary, cache: ImageCache, silent: bool) -> void:
	match data.event.type:
		"sub_or_resub":
			if not silent:
				sub_player.play_random()
			chat_log.add_notice(
				"🟊", "[wave]{name} {type} {months}mo[/wave]".format({
					"name": data.sender.name,
					"type": data.event.sub_plan,
					"months": data.event.cumulative_months,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"raid":
			if not silent:
				raid_player.play_random()
			chat_log.add_notice(
				"⚑", "[wave]{raider} +{viewers}👁[/wave]".format({
					"raider": data.sender.name,
					"viewers": data.event.viewer_count,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"sub_gift":
			if not silent:
				sub_player.play_random()
			chat_log.add_notice(
				"📦", "[wave]{name} {type} {months}mo[/wave]".format({
					"name": data.sender.name,
					"type": data.event.sub_plan,
					"months": data.event.cumulative_months,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"sub_mystery_gift":
			chat_log.add_notice(
				"🚚", "[wave]{name} +{count}📦 {type}[/wave]".format({
					"name": data.sender.name,
					"count": data.event.mass_gift_count,
					"type": data.event.sub_plan,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"anon_sub_mystery_gift":
			chat_log.add_notice(
				"🚚", "[wave]{name} +{count}📦 {type}[/wave]".format({
					"name": data.sender.name,
					"count": data.event.mass_gift_count,
					"type": data.event.sub_plan,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"bits_badge_tier_prefab":
			chat_log.add_notice(
				"⬙", "[wave]{name} {threshold}![/wave]".format({
					"name": data.sender.name,
					"threshold": data.event.threshold,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		_:
			# Treat unknown events like messages
			if data.has("message_text") and \
					data["message_text"] != null and \
					data["message_text"] != "":
				chat_log.add_message(data, cache).setup_with_user_notice(data)
				if not silent:
					queue_emotes(data)

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

func queue_emotes(data: Dictionary) -> void:
	if not data.has("emotes"):
		return

	for emote in data["emotes"]:
		if emotes_to_spawn.has(emote["id"]):
			emotes_to_spawn[emote["id"]] += 1
		else:
			emotes_to_spawn[emote["id"]] = 1

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
