class_name Witch
extends Node

const DUPE_FLAGS := DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS

@onready var notif_player: AudioStreamPlayer = %Notif
@onready var listen_player: AudioStreamPlayer = %Listen
@onready var raid_player: SoundBankPlayer = %Raid
@onready var message_prefab: Message = %Message
@onready var chat_container: Control = message_prefab.get_parent()

var irc := WitchIRC.new()

func _ready():
	# Setup prefabs
	chat_container.remove_child(message_prefab)

	irc.join("exodrifter_")

func _process(_delta):
	var messages = irc.poll()
	for message in messages:
		process_message(message)

func process_message(message: Dictionary):
	match message.type:
		"privmsg":
			# Play the sound effect
			match message.message_text:
				"!listen":
					listen_player.play()
				"!raid":
					raid_player.play_random()
				_:
					notif_player.play()

			var message_control: Message = message_prefab.duplicate(DUPE_FLAGS)
			message_control.data = message
			chat_container.add_child(message_control)
			chat_container.move_child(message_control, 0)
			print(message)
