class_name Chat
extends Control

@export var chat_message: PackedScene

@onready var twitch: TwitchEventNode = %Twitch
@onready var image_cache: ImageCache = %ImageCache

func _on_twitch_chat_message(message_data: GMessageData) -> void:
	print(message_data.chatter.name + " " + message_data.message.text)
	var msg: ChatMessage = chat_message.instantiate()
	add_child(msg)
	move_child(msg, 0)

	msg.image_cache = image_cache
	msg.message_data = message_data
