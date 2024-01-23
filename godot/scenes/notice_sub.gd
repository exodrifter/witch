class_name SubOrResubNotif
extends MarginContainer

const template: String = "[wave]{username} {sub_plan} {months}mo[/wave]"

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

## The name of the user who is subscribing or resubscribing.
var user_name: String:
	get:
		if data.has("sender") and data["sender"].has("name"):
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

## The number of cumulative months the user has been subbed.
var cumulative_months: int:
	get:
		if data.has("event") and data["event"].has("cumulative_months"):
			return data["event"]["cumulative_months"]
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
				"username": user_name,
				"sub_plan": "prime",
				"months": cumulative_months,
			})
		"1000":
			text.text = template.format({
				"username": user_name,
				"sub_plan": "t1",
				"months": cumulative_months,
			})
		"2000":
			text.text = template.format({
				"username": user_name,
				"sub_plan": "t2",
				"months": cumulative_months,
			})
		"3000":
			text.text = template.format({
				"username": user_name,
				"sub_plan": "t3",
				"months": cumulative_months,
			})
		_:
			text.text = template.format({
				"username": user_name,
				"sub_plan": sub_plan,
				"months": cumulative_months,
			})
