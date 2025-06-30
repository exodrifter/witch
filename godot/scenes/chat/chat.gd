class_name Chat
extends Control

@export var chat_message: PackedScene

@onready var log: Container = %Log
@onready var twitch: TwitchEventNode = %Twitch
@onready var image_cache: ImageCache = %ImageCache

func _on_twitch_chat_message(message_data: GMessageData) -> void:
	var msg: ChatMessage = chat_message.instantiate()
	log.add_child(msg)
	log.move_child(msg, 0)

	msg.image_cache = image_cache
	msg.message_data = message_data
