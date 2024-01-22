extends Node

const DUPE_FLAGS = DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS

@onready var message_prefab = %Message
@onready var chat_container = message_prefab.get_parent()

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
			var message_control = message_prefab.duplicate(DUPE_FLAGS)
			message_control.data = message
			chat_container.add_child(message_control)
			print(message)
