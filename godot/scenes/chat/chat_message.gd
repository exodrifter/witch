class_name ChatMessage
extends Control

@onready var label: Label = %Name
@onready var message: ChatMessageBody = %MessageBody

var image_cache: ImageCache:
	set(value):
		if image_cache != value:
			image_cache = value
			queue_redraw()

var message_data: GMessageData:
	set(value):
		if message_data != value:
			message_data = value
			queue_redraw()

func _draw() -> void:
	label.text = message_data.chatter.name

	message.image_cache = image_cache
	message.message = message_data.message
