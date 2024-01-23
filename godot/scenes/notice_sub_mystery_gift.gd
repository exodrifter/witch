class_name SubMysteryGiftNotif
extends MarginContainer

const template: String = "[wave]{username}+{mass_gift_count}📦 {sub_plan}[/wave]"

var is_anonymous: bool = false:
	set(value):
		is_anonymous = value
		setup()

var data: Dictionary = {}:
	set(value):
		data = value
		setup()

@onready var text = $HBoxContainer/VBoxContainer/Text

## The UUID of the message.
var message_id: String:
	get:
		if data.has("message_id"):
			return data["message_id"]
		else:
			return "00000000-0000-0000-0000-000000000000"

## The name of the user gifting the subs.
var user_name: String:
	get:
		if is_anonymous:
			return ""
		elif data.has("sender") and data["sender"].has("name"):
			return data["sender"]["name"]
		else:
			return ""

## The sub plan the user subbed to.
var sub_plan: String:
	get:
		if data.has("event") and data["event"].has("sub_plan"):
			return data["event"]["sub_plan"]
		else:
			return ""

## The number of gifted subs.
var mass_gift_count: int:
	get:
		if data.has("event") and data["event"].has("mass_gift_count"):
			return data["event"]["mass_gift_count"]
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
	match sub_plan:
		"Prime":
			text.text = template.format({
				"username": user_name + (" " if user_name != "" else ""),
				"mass_gift_count": mass_gift_count,
				"sub_plan": "prime",
			})
		"1000":
			text.text = template.format({
				"username": user_name + (" " if user_name != "" else ""),
				"mass_gift_count": mass_gift_count,
				"sub_plan": "t1",
			})
		"2000":
			text.text = template.format({
				"username": user_name + (" " if user_name != "" else ""),
				"mass_gift_count": mass_gift_count,
				"sub_plan": "t2",
			})
		"3000":
			text.text = template.format({
				"username": user_name + (" " if user_name != "" else ""),
				"mass_gift_count": mass_gift_count,
				"sub_plan": "t3",
			})
		_:
			text.text = template.format({
				"username": user_name + (" " if user_name != "" else ""),
				"mass_gift_count": mass_gift_count,
				"sub_plan": sub_plan,
			})
