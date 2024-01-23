class_name RaidNotif
extends MarginContainer

const template: String = "[wave]{username} +{viewer_count}👁[/wave]"

var data: Dictionary = {}:
	set(value):
		data = value
		setup()

@onready var text = $HBoxContainer/MarginContainer/VBoxContainer/Text

## The UUID of the message.
var message_id: String:
	get:
		if data.has("message_id"):
			return data["message_id"]
		else:
			return "00000000-0000-0000-0000-000000000000"

## The name of the user who sent the notice.
var user_name: String:
	get:
		if data.has("sender") and data["sender"].has("name"):
			return data["sender"]["name"]
		else:
			return ""

## The number of viewers that raided
var viewer_count: int:
	get:
		if data.has("event") and data["event"].has("viewer_count"):
			return data["event"]["viewer_count"]
		else:
			return 0

func _ready() -> void:
	text.clear()

func _process(_delta) -> void:
	if global_position.y > 720:
		queue_free()

func setup() -> void:
	name = message_id
	setup_text()

func setup_text():
	text.text = template.format({
		"username": user_name,
		"viewer_count": viewer_count,
	})
