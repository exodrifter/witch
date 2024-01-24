## Base class for all chat log entries
class_name Entry
extends Control

## The channel this entry was sent in.
var channel_login: String = ""
## The message id of this entry.
var message_id: String = ""
## The id of the user who sent this message.
var sender_id: String = ""
## The login of the user who sent this message.
var sender_login: String = ""

## Sets up the entry metadata using a privmsg.
func setup_with_privmsg(data: Dictionary) -> void:
	channel_login = data["channel_login"]
	message_id = data["message_id"]
	sender_id = data["sender"]["id"]
	sender_login = data["sender"]["login"]
	name = message_id

## Sets up the entry metadata using a user notice.
func setup_with_user_notice(data: Dictionary) -> void:
	channel_login = data["channel_login"]
	message_id = data["message_id"]
	sender_id = data["sender"]["id"]
	sender_login = data["sender"]["login"]
	name = message_id

func _process(_delta) -> void:
	if global_position.y > get_viewport().size.y:
		queue_free()
