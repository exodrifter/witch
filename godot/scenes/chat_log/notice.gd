## Class for notices.
class_name Notice
extends Entry

@onready var _background: ColorRect = $Background
@onready var _icon: RichTextLabel = $MarginContainer/HBoxContainer/IconContainer/Icon
@onready var _text: RichTextLabel = $MarginContainer/HBoxContainer/TextContainer/Text

## The icon to use for the notice.
var icon: String:
	get:
		return _icon.text
	set(value):
		_icon.text = value

## The message of the notice.
var text: String:
	get:
		return _text.text
	set(value):
		_text.text = value

## The color of the notice background.
var bg_color: Color:
	get:
		return _background.modulate
	set(value):
		_background.modulate = value

## The color of the notice text.
var fg_color: Color:
	set(value):
		_icon.modulate = value
		_text.modulate = value
