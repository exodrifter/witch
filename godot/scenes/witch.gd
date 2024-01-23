class_name Witch
extends Node

const DUPE_FLAGS := DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS

@onready var notif_player: AudioStreamPlayer = %Notif
@onready var listen_player: AudioStreamPlayer = %Listen
@onready var raid_player: SoundBankPlayer = %Raid

@onready var bits_prefab: GPUParticles2D = %BitParticles
@onready var emotes_prefab: GPUParticles2D = %EmoteParticles
@onready var message_prefab: Message = %Message

@onready var bits_container: Node = bits_prefab.get_parent()
@onready var emotes_container: Node = emotes_prefab.get_parent()
@onready var chat_container: Node = message_prefab.get_parent()

var irc := WitchIRC.new()

func _ready():
	# Setup prefabs
	bits_container.remove_child(bits_prefab)
	emotes_container.remove_child(emotes_prefab)
	chat_container.remove_child(message_prefab)

	irc.join("exodrifter_")

func _process(_delta):
	var messages = irc.poll()
	for message in messages:
		process_message(message)

func process_message(data: Dictionary) -> void:
	match data.type:
		"privmsg":
			# Play the sound effect
			match data.message_text:
				"!listen":
					listen_player.play()
				"!raid":
					raid_player.play_random()
				_:
					notif_player.play()

			var message: Message = message_prefab.duplicate(DUPE_FLAGS)
			chat_container.add_child(message)
			chat_container.move_child(message, 0)
			message.witch = self
			message.data = data

			process_bits(message.bits)

func process_bits(bits: int) -> void:
	if bits <= 0:
		return

	var emitter: GPUParticles2D = bits_prefab.duplicate(DUPE_FLAGS)
	emitter.amount = bits
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	bits_container.add_child(emitter)

func process_emote(emote: Texture2D) -> void:
	if emote == null:
		return

	var emitter: GPUParticles2D = emotes_prefab.duplicate(DUPE_FLAGS)
	emitter.texture = emote
	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	emotes_container.add_child(emitter)
