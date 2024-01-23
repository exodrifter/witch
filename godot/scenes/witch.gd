class_name Witch
extends Node

const DUPE_FLAGS := DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS

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
@onready var bits_badge_tier: BitsBadgeTierNotif = %BitsBadgeTier

@onready var bits_container: Node = bits_prefab.get_parent()
@onready var emotes_container: Node = emotes_prefab.get_parent()
@onready var chat_container: Node = message_prefab.get_parent()

var irc := WitchIRC.new()
var spawned_messages: Array[Message] = []

func _ready():
	# Setup prefabs
	bits_container.remove_child(bits_prefab)
	emotes_container.remove_child(emotes_prefab)
	chat_container.remove_child(message_prefab)
	chat_container.remove_child(raid_prefab)
	chat_container.remove_child(sub_prefab)
	chat_container.remove_child(sub_gift_prefab)
	chat_container.remove_child(sub_mystery_gift_prefab)
	chat_container.remove_child(bits_badge_tier)

	irc.join("hasanabi")

func _process(_delta):
	var messages = irc.poll()
	for message in messages:
		process_message(message)
		print(message)

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
				"bits_badge_tier":
					var notif: BitsBadgeTierNotif = bits_badge_tier.duplicate(DUPE_FLAGS)
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
			for message in spawned_messages:
				if message.channel_login == data.channel_login:
					message.modulate = Color.TRANSPARENT
		"user_banned":
			for message in spawned_messages:
				if message.channel_login == data.channel_login and \
						message.user_login == data.action.user_login:
					message.modulate = Color.TRANSPARENT
		"user_timed_out":
			for message in spawned_messages:
				if message.channel_login == data.channel_login and \
						message.user_login == data.action.user_login:
					message.modulate = Color.TRANSPARENT

func process_clear_msg(data: Dictionary) -> void:
	for message in spawned_messages:
		if message.channel_login == data.channel_login and \
				message.message_id == data.message_id:
			message.modulate = Color.TRANSPARENT

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
