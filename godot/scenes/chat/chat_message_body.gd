class_name ChatMessageBody
extends RichTextLabel

var image_cache: ImageCache:
	set(value):
		if image_cache != value:
			image_cache = value
			queue_redraw()

var message: GMessage:
	set(value):
		if message != value:
			message = value
			queue_redraw()

func _draw() -> void:
	# Avoid triggering another redraw from changing the text.
	if get_meta("message_text", "") == message.text:
		return
	set_meta("message_text", message.text)

	text = ""
	for fragment in message.fragments:
		if fragment.is_any_emote():
			add_image(image_cache.get_emote_1x(fragment), 30, 30)
		else:
			add_text(fragment.text)
