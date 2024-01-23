class_name Witch
extends Node

const DUPE_FLAGS := DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS

enum Mode { Live, Replay }
@export var mode: Mode = Mode.Live
@export var channel: String = "exodrifter_"
@export var replay_file: String = ""

@onready var notif_player: AudioStreamPlayer = %NotifPlayer
@onready var listen_player: AudioStreamPlayer = %ListenPlayer
@onready var raid_player: SoundBankPlayer = %RaidPlayer
@onready var sub_player: SoundBankPlayer = %SubPlayer

@onready var bits_prefab: GPUParticles2D = %BitParticles
@onready var emotes_prefab: GPUParticles2D = %EmoteParticles
@onready var message_prefab: Message = %Message
@onready var raid_prefab: RaidNotif = %Raid
@onready var sub_prefab: SubOrResubNotif = %SubOrResub
@onready var sub_gift_prefab: SubGiftNotif = %SubGift
@onready var sub_mystery_gift_prefab: SubMysteryGiftNotif = %SubMysteryGift
@onready var bits_badge_tier_prefab: BitsBadgeTierNotif = %BitsBadgeTier
@onready var notice_prefab: Notice = %Notice

@onready var bits_container: Node = bits_prefab.get_parent()
@onready var emotes_container: Node = emotes_prefab.get_parent()
@onready var chat_container: Node = message_prefab.get_parent()

var spawned_messages: Array[Message] = []

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
	chat_container.remove_child(message_prefab)
	chat_container.remove_child(raid_prefab)
	chat_container.remove_child(sub_prefab)
	chat_container.remove_child(sub_gift_prefab)
	chat_container.remove_child(sub_mystery_gift_prefab)
	chat_container.remove_child(bits_badge_tier_prefab)
	chat_container.remove_child(notice_prefab)

func _process(delta):
	match mode:
		Mode.Replay:
			# Open the replay file if we haven't already
			if replay_irc_log == null:
				replay_irc_log = FileAccess.open(replay_file, FileAccess.READ)
				if replay_irc_log != null:
					next_replay_line = replay_irc_log.get_line()
					first_unix_time = float(next_replay_line.split(" ", true, 1)[0])
					spawn_notice(
						"⟲", Time.get_datetime_string_from_unix_time(floori(first_unix_time)),
						Color.YELLOW,
						Color.BLACK
					)
				else:
					replay_ended = true
					spawn_notice(
						"⚠", "REPLAY FAILED",
						Color.RED, Color.WHITE
					)

			# Replay lines
			while not replay_irc_log.eof_reached():
				var parts = next_replay_line.split(" ", true, 1)
				var next_unix = int(parts[0])
				var next_irc = parts[1]
				if first_unix_time + elapsed >= next_unix:
					var data = WitchIRC.parse(next_irc.rstrip("\n"))
					process_message(data)
					next_replay_line = replay_irc_log.get_line()
				else:
					break

			# Show replay ended notice
			if replay_irc_log.eof_reached() and not replay_ended:
				replay_ended = true
				spawn_notice(
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
				var path = "user://{datetime}.txt".format({
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

func process_message(data: Dictionary) -> void:
	match data.type:
		"clear_chat":
			process_clear_chat(data)

		"clear_msg":
			process_clear_msg(data)

		"privmsg":
			# Play the sound effect
			match data.message_text:
				"!listen":
					listen_player.play()
				_:
					notif_player.play()

			var message: Message = message_prefab.duplicate(DUPE_FLAGS)
			chat_container.add_child(message)
			chat_container.move_child(message, 0)
			message.witch = self
			message.data = data
			spawned_messages.push_back(message)

			spawn_bits(message.bits)

		"user_notice":
			match data.event.type:
				"sub_or_resub":
					sub_player.play_random()
					var notif: SubOrResubNotif = sub_prefab.duplicate(DUPE_FLAGS)
					chat_container.add_child(notif)
					chat_container.move_child(notif, 0)
					notif.data = data
				"raid":
					raid_player.play_random()
					var notif: RaidNotif = raid_prefab.duplicate(DUPE_FLAGS)
					chat_container.add_child(notif)
					chat_container.move_child(notif, 0)
					notif.data = data
				"sub_gift":
					sub_player.play_random()
					var notif: SubGiftNotif = sub_gift_prefab.duplicate(DUPE_FLAGS)
					chat_container.add_child(notif)
					chat_container.move_child(notif, 0)
					notif.data = data
				"sub_mystery_gift":
					var notif: SubMysteryGiftNotif = sub_mystery_gift_prefab.duplicate(DUPE_FLAGS)
					chat_container.add_child(notif)
					chat_container.move_child(notif, 0)
					notif.is_anonymous = false
					notif.data = data
				"anon_sub_mystery_gift":
					var notif: SubMysteryGiftNotif = sub_mystery_gift_prefab.duplicate(DUPE_FLAGS)
					chat_container.add_child(notif)
					chat_container.move_child(notif, 0)
					notif.is_anonymous = true
					notif.data = data
				"bits_badge_tier_prefab":
					var notif: BitsBadgeTierNotif = bits_badge_tier_prefab.duplicate(DUPE_FLAGS)
					chat_container.add_child(notif)
					chat_container.move_child(notif, 0)
					notif.data = data
				_:
					# Treat unknown events like messages
					if data.has("message_text") and \
							data["message_text"] != null and \
							data["message_text"] != "":
						var message: Message = message_prefab.duplicate(DUPE_FLAGS)
						chat_container.add_child(message)
						chat_container.move_child(message, 0)
						message.witch = self
						message.data = data

func process_clear_chat(data: Dictionary) -> void:
	match data.action.type:
		"chat_cleared":
			spawn_notice(
				"⌫", "chat cleared",
				Color(.1, .1, .1), Color.WHITE
			)
			for message in spawned_messages:
				if message.channel_login == data.channel_login:
					message.modulate = Color.TRANSPARENT
		"user_banned":
			spawn_notice(
				"🚫", "{user} banned".format({
					"user": data.action.user_login,
				}),
				Color(.1, .1, .1), Color.WHITE
			)
			for message in spawned_messages:
				if message.channel_login == data.channel_login and \
						message.user_login == data.action.user_login:
					message.modulate = Color.TRANSPARENT
		"user_timed_out":
			spawn_notice(
				"⏰", "{user} timeout {duration}s".format({
					"user": data.action.user_login,
					"duration": data.action.timeout_length,
				}),
				Color(.1, .1, .1), Color.WHITE
			)
			for message in spawned_messages:
				if message.channel_login == data.channel_login and \
						message.user_id == data.action.user_id:
					message.modulate = Color.TRANSPARENT

func process_clear_msg(data: Dictionary) -> void:
	for message in spawned_messages:
		if message.channel_login == data.channel_login and \
				message.message_id == data.message_id:
			message.modulate = Color.TRANSPARENT

#region Spawners

func spawn_bits(bits: int) -> void:
	if bits <= 0:
		return

	var emitter: GPUParticles2D = bits_prefab.duplicate(DUPE_FLAGS)
	emitter.amount = bits
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	bits_container.add_child(emitter)

func spawn_emote(emote: Texture2D) -> void:
	if emote == null:
		return

	var emitter: GPUParticles2D = emotes_prefab.duplicate(DUPE_FLAGS)
	emitter.texture = emote
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	emotes_container.add_child(emitter)

func spawn_notice(icon: String, text: String, bg: Color, fg: Color) -> void:
	var notice: Notice = notice_prefab.duplicate(DUPE_FLAGS)
	chat_container.add_child(notice)
	chat_container.move_child(notice, 0)
	notice.icon = "[center]" + icon + "[/center]"
	notice.text = text
	notice.bg_color = bg
	notice.fg_color = fg

#endregion
