class_name Chat
extends Control

@export_range(0, 1) var cull_at: float
@export var chat_message: PackedScene

@onready var log: AnimatedVBoxContainer = %Log
@onready var twitch: TwitchEventNode = %Twitch
@onready var image_cache: ImageCache = %ImageCache

func _on_twitch_chat_message(message_data: GMessageData) -> void:
	var msg: ChatMessage = chat_message.instantiate()
	log.add_child(msg)
	log.move_child(msg, 0)

	msg.image_cache = image_cache
	msg.message_data = message_data

	# Check for messages to prune
	for control: Control in log.positions.keys():
		if log.positions[control].desired.y > size.y * cull_at:
			if control.has_method("_request_destroy"):
				control.call("_request_destroy")
