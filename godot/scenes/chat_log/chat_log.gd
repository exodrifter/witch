## Manages entries in a chat log.
class_name ChatLog
extends Node

@onready var chat_container: Container = $Container
@onready var message_prefab: Message = %Message
@onready var notice_prefab: Notice = %Notice

## A reference to every valid entry in the chat log.
var entries: Dictionary = {}

func _ready():
	# Setup prefabs
	chat_container.remove_child(message_prefab)
	chat_container.remove_child(notice_prefab)

#region Adding entries

## Adds an entry to the chat log.
func _add_entry(prefab: Node) -> Node:
	var entry = prefab.duplicate()
	chat_container.add_child(entry)
	chat_container.move_child(entry, 0)

	var id = entry.get_instance_id()
	var erase = func(): entries.erase(id)
	entry.tree_exited.connect(erase)
	entries[entry.get_instance_id()] = entry

	return entry

## Adds a message to the chat log.
func add_message(data: Dictionary) -> void:
	var message: Message = _add_entry(message_prefab)
	message.data = data

## Adds a notice to the chat log.
func add_notice(icon: String, text: String, bg: Color, fg: Color) -> void:
	var notice: Notice = _add_entry(notice_prefab)
	notice.icon = "[center]" + icon + "[/center]"
	notice.text = text
	notice.bg_color = bg
	notice.fg_color = fg

#endregion

#region Removing entries

## Removes all entries from a specific channel from the chat log.
func remove_by_channel(channel_login: String) -> void:
	for entry in entries.values():
		if "channel_login" in entry:
			if entry.channel_login == channel_login:
				entry.modulate = Color.TRANSPARENT

## Removes a specific entry from the chat log.
func remove_by_id(channel_login: String, message_id: String) -> void:
	for entry in entries.values():
		if "channel_login" in entry and "message_id" in entry:
			if entry.channel_login == channel_login and \
					entry.message_id == message_id:
				entry.modulate = Color.TRANSPARENT

## Removes all entries from a specific user by their id.
func remove_by_user_id(channel_login: String, user_id: String) -> void:
	for entry in entries.values():
		if "channel_login" in entry and "user_id" in entry:
			if entry.channel_login == channel_login and \
					entry.user_id == user_id:
				entry.modulate = Color.TRANSPARENT

## Removes all entries from a specific user by their login.
func remove_by_user_login(channel_login: String, user_login: String) -> void:
	for entry in entries.values():
		if "channel_login" in entry and "user_login" in entry:
			if entry.channel_login == channel_login and \
					entry.user_login == user_login:
				entry.modulate = Color.TRANSPARENT

#endregion
