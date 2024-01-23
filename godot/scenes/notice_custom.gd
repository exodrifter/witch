## Class for arbitrary notifications
class_name CustomNotif
extends MarginContainer

var text: String:
	get:
		return label.text
	set(value):
		label.text = value

@onready var label = $HBoxContainer/MarginContainer/VBoxContainer/Text
