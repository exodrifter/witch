class_name Witch
extends Node

const DUPE_FLAGS := DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS

enum Mode { Live, Replay }
@export var mode: Mode = Mode.Live
@export var channel: String = "exodrifter_"
@export var replay_file: String = ""

@onready var crash_player: AudioStreamPlayer = %CrashPlayer
@onready var listen_player: AudioStreamPlayer = %ListenPlayer
@onready var notif_player: AudioStreamPlayer = %NotifPlayer
@onready var raid_player: SoundBankPlayer = %RaidPlayer
@onready var sub_player: SoundBankPlayer = %SubPlayer
@onready var chat_log: ChatLog = $ChatLog

@onready var bits_prefab: GPUParticles2D = %BitParticles
@onready var emotes_prefab: GPUParticles2D = %EmoteParticles

@onready var bits_container: Node = bits_prefab.get_parent()
@onready var emotes_container: Node = emotes_prefab.get_parent()

# Live variables
var irc: WitchIRC
var live_irc_log: FileAccess

# Replay variables
var replay_irc_log: FileAccess
var next_replay_line: String
var first_unix_time: float
var replay_ended: bool
var elapsed: float

func _ready():
	# Setup prefabs
	bits_container.remove_child(bits_prefab)
	emotes_container.remove_child(emotes_prefab)

func _process(delta):
	match mode:
		Mode.Replay:
			# Open the replay file if we haven't already
			if replay_irc_log == null:
				replay_irc_log = FileAccess.open(replay_file, FileAccess.READ)
				if replay_irc_log != null:
					next_replay_line = replay_irc_log.get_line()
					first_unix_time = float(next_replay_line.split(" ", true, 1)[0])
					chat_log.add_notice(
						"⟲", Time.get_datetime_string_from_unix_time(floori(first_unix_time)),
						Color.YELLOW,
						Color.BLACK
					)
				else:
					replay_ended = true
					chat_log.add_notice(
						"⚠", "REPLAY FAILED",
						Color.RED, Color.WHITE
					)

			# Replay lines
			while not replay_irc_log.eof_reached():
				var parts = next_replay_line.split(" ", true, 1)
				var next_unix = float(parts[0])
				var next_irc = parts[1]
				if first_unix_time + elapsed >= next_unix:
					var data = WitchIRC.parse(next_irc)
					process_message(data)
					next_replay_line = replay_irc_log.get_line()
				else:
					break

			# Show replay ended notice
			if replay_irc_log.eof_reached() and not replay_ended:
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
				DirAccess.make_dir_absolute("user://replay")
				var path = "user://replay/{datetime}.txt".format({
					"datetime":
						Time.get_datetime_string_from_system(true)
							.replace(":", "-")
							.replace("T","-")
				})
				live_irc_log = FileAccess.open(path, FileAccess.WRITE)

			# Get new messages
			var messages = irc.poll()
			for next_irc in messages:
				var data = WitchIRC.parse(next_irc)
				process_message(data)
				live_irc_log.store_string("{time} {irc}\n".format({
					"time": Time.get_unix_time_from_system(),
					"irc": next_irc,
				}))
			live_irc_log.flush()

	spawn_emotes()

#region Message Processing

func process_message(data: Dictionary) -> void:
	match data.type:
		"clear_chat":
			process_clear_chat(data)

		"clear_msg":
			chat_log.remove_by_id(data.channel_login, data.message_id)

		"privmsg":
			# Play the sound effect
			match data.message_text.split(" ", true, 1)[0]:
				"!listen":
					listen_player.play()
				"!don't":
					crash_player.play()
				_:
					notif_player.play()

			chat_log.add_message(data).setup_with_privmsg(data)
			queue_emotes(data)

			if data.has("bits") and data.bits != null:
				spawn_bits(data.bits)

		"user_notice":
			process_notice(data)

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

func process_notice(data: Dictionary) -> void:
	match data.event.type:
		"sub_or_resub":
			sub_player.play_random()
			chat_log.add_notice(
				"⭐", "[wave]{name} {type} {months}mo[/wave]".format({
					"name": data.sender.name,
					"type": data.event.sub_plan,
					"months": data.event.cumulative_months,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"raid":
			raid_player.play_random()
			chat_log.add_notice(
				"⚑", "[wave]{raider} +{viewers}👁[/wave]".format({
					"raider": data.sender.name,
					"viewers": data.event.viewer_count,
				}),
				Color.PURPLE, Color.WHITE
			).setup_with_user_notice(data)
		"sub_gift":
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
				chat_log.add_message(data).setup_with_user_notice(data)
				queue_emotes(data)

#endregion

#region Spawners

func spawn_bits(bits: int) -> void:
	if bits <= 0:
		return

	var emitter: GPUParticles2D = bits_prefab.duplicate(DUPE_FLAGS)
	emitter.amount = bits
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	bits_container.add_child(emitter)

var emotes_to_spawn: Dictionary = {}

func queue_emotes(data: Dictionary) -> void:
	if not data.has("emotes"):
		return

	for emote in data["emotes"]:
		if emotes_to_spawn.has(emote["id"]):
			emotes_to_spawn[emote["id"]] += 1
		else:
			emotes_to_spawn[emote["id"]] = 1

func spawn_emotes() -> void:
	var to_remove = []
	for emote_id in emotes_to_spawn:
		var tex = TwitchImageCache.get_emote(
			emote_id,
			TwitchImageCache.ThemeMode.Dark,
			TwitchImageCache.EmoteSize.Small
		)
		if tex != null:
			spawn_emote(tex, emotes_to_spawn[emote_id])
			to_remove.push_back(emote_id)

	for emote_id in to_remove:
		emotes_to_spawn.erase(emote_id)

func spawn_emote(emote: Texture2D, amount: int) -> void:
	if emote == null:
		return

	var emitter: GPUParticles2D = emotes_prefab.duplicate(DUPE_FLAGS)
	emitter.texture = emote
	emitter.amount = amount
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	emotes_container.add_child(emitter)

#endregion
