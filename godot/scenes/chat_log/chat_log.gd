## Manages entries in a chat log.
class_name ChatLog
extends Node

@onready var chat_container: Container = $Container

@onready var message_prefab := preload("res://scenes/chat_log/message.tscn")
@onready var notice_prefab := preload("res://scenes/chat_log/notice.tscn")

## A reference to every valid entry in the chat log.
var entries: Dictionary = {}

#region Adding entries

## Adds an entry to the chat log.
func _add_entry(prefab: PackedScene) -> Node:
	var entry = prefab.instantiate()
	chat_container.add_child(entry)
	chat_container.move_child(entry, 0)

	var id = entry.get_instance_id()
	var erase = func(): entries.erase(id)
	entry.tree_exited.connect(erase)
	entries[entry.get_instance_id()] = entry

	return entry

## Adds a private message to the chat log.
func add_privmsg(data: WitchPrivmsgMessage, cache: ImageCache) -> Entry:
	var message: Message = _add_entry(message_prefab)
	message.setup_privmsg(cache, data)
	return message

func add_user_notice(data: WitchUserNoticeMessage, cache: ImageCache) -> Entry:
	var message: Message = _add_entry(message_prefab)
	message.setup_user_notice(cache, data)
	return message

## Adds a notice to the chat log.
func add_notice(icon: String, text: String, bg: Color, fg: Color) -> Entry:
	var notice: Notice = _add_entry(notice_prefab)
	notice.icon = "[center]" + icon + "[/center]"
	notice.text = text
	notice.bg_color = bg
	notice.fg_color = fg
	return notice

#endregion

#region Removing entries

## Removes all entries from a specific channel from the chat log.
func remove_by_channel(channel_login: String) -> void:
	for entry in entries.values():
		entry = entry as Entry
		if entry.channel_login == channel_login:
			entry.modulate = Color.TRANSPARENT

## Removes a specific entry from the chat log.
func remove_by_id(channel_login: String, message_id: String) -> void:
	for entry in entries.values():
		entry = entry as Entry
		if entry.channel_login == channel_login and \
				entry.message_id == message_id:
			entry.modulate = Color.TRANSPARENT

## Removes all entries from a specific user by their id.
func remove_by_user_id(channel_login: String, sender_id: String) -> void:
	for entry in entries.values():
		entry = entry as Entry
		if entry.channel_login == channel_login and \
				entry.sender_id == sender_id:
			entry.modulate = Color.TRANSPARENT

## Removes all entries from a specific user by their login.
func remove_by_user_login(channel_login: String, sender_login: String) -> void:
	for entry in entries.values():
		entry = entry as Entry
		if entry.channel_login == channel_login and \
				entry.sender_login == sender_login:
			entry.modulate = Color.TRANSPARENT

#endregion
