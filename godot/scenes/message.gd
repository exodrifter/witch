extends RichTextLabel

var data: Dictionary = {}:
	set(value):
		data = value
		setup()

## The name of the user who sent the message.
var user_name: String:
	get:
		return data["sender"]["name"]

## The color of the user who sent the message.
var user_color: Color:
	get:
		if data["name_color"] == null:
			return Color.WHITE
		else:
			return data["name_color"]

## The message the user sent.
var message_text: String:
	get:
		return data["message_text"]

## The UUID of the message.
var message_id: String:
	get:
		return data["message_id"]

func _ready():
	setup()

func setup() -> void:
	clear()
	if data.is_empty():
		return

	push_color(user_color)
	append_text(user_name)
	pop()

	append_text(" ")
	append_text(message_text)
