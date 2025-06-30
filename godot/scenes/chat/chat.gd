class_name Chat
extends Control

@export var cull_at: float = 800
@export var chat_message: PackedScene

@onready var chat_log: AnimatedVBoxContainer = %Log
@onready var twitch: TwitchEventNode = %Twitch
@onready var image_cache: ImageCache = %ImageCache

func _on_twitch_chat_message(message_data: GMessageData) -> void:
	var msg: ChatMessage = chat_message.instantiate()
	chat_log.add_child(msg)
	chat_log.move_child(msg, 0)

	msg.image_cache = image_cache
	msg.message_data = message_data

	await get_tree().process_frame

	# Check for messages to prune
	for control: Control in chat_log.positions.keys():
		if chat_log.positions[control].desired.y > size.y:
			if control.has_method("_request_destroy"):
				control.call("_request_destroy")
