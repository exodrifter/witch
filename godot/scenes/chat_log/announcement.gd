class_name Announcement
extends Entry

@onready var background = $Background
@onready var header_text = %HeaderText
@onready var announcement_text = %AnnouncementText

## The header of the announcement.
var header: String:
	get:
		return header_text.text
	set(value):
		header_text.text = value

## The content of the announcement.
var text: String:
	get:
		return announcement_text.text
	set(value):
		announcement_text.text = value

## The color of the announcement.
var color: Color:
	get:
		return background.color
	set(value):
		background.color = value
