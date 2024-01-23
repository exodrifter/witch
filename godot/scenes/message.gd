class_name Message
extends Control

var witch: Witch = null
var emitted_emotes: bool = false
var data: Dictionary = {}:
	set(value):
		data = value
		setup()

@onready var color_bar = $ColorBar
@onready var text = $Text

## The UUID of the message.
var message_id: String:
	get:
		if data.has("message_id"):
			return data["message_id"]
		else:
			return "00000000-0000-0000-0000-000000000000"

## The name of the user who sent the message.
var user_name: String:
	get:
		if data.has("sender") and data["sender"].has("name"):
			return data["sender"]["name"]
		else:
			return ""

## The color of the user who sent the message.
var user_color: Color:
	get:
		if not data.has("name_color"):
			return Color.WHITE
		elif data["name_color"] == null:
			return Color.WHITE
		else:
			return data["name_color"]

## If true, this message was sent by a broadcaster.
var is_broadcaster: bool:
	get:
		# TODO: Check badges for broadcaster
		return user_name == "exodrifter_"

## If true, this message was sent by a mod.
var is_mod: bool:
	get:
		if data.has("source") and \
				data["source"].has("tags") and \
				data["source"]["tags"].has("mod"):
			return data["source"]["tags"]["mod"] == "1"
		else:
			return false

## If true, this message was sent by a vip.
var is_vip: bool:
	get:
		if data.has("source") and \
				data["source"].has("tags") and \
				data["source"]["tags"].has("vip"):
			return true
		else:
			return false

## If true, this message was made using the /me command.
var is_action: bool:
	get:
		if data.has("is_action"):
			return data["is_action"]
		else:
			return false

## The message the user sent.
var message_text: String:
	get:
		if data.has("message_text"):
			return data["message_text"]
		else:
			return ""

## The number of bits cheered with this message.
var bits: int:
	get:
		if data.has("bits") and data["bits"] != null:
			return data["bits"]
		else:
			return 0

func _ready() -> void:
	text.clear()

func _process(_delta) -> void:
	if global_position.y > 720:
		queue_free()

func setup() -> void:
	name = message_id
	setup_color_bar()
	setup_text()

func setup_color_bar() -> void:
	if is_broadcaster:
		color_bar.modulate = Color.RED
	elif is_mod:
		color_bar.modulate = Color.GREEN
	elif is_vip:
		color_bar.modulate = Color.PURPLE
	else:
		color_bar.modulate = Color.TRANSPARENT

func setup_text() -> void:
	text.clear()
	if data.is_empty():
		return

	if is_action:
		text.push_italics()

	# Show the user
	text.push_color(user_color)
	append_bbcode(user_name)
	if is_action:
		append_bbcode(" ")
	else:
		append_bbcode(": ")
		text.pop()

	# Show the message
	var missing_emotes = false
	var last = 0
	for emote in data["emotes"]:
		var start = emote["char_range"]["start"]
		var end = emote["char_range"]["end"]
		append_bbcode(message_text.substr(last, start - last))

		# Add the emote if it is loaded
		var tex = TwitchImageCache.get_emote(
			emote["id"],
			TwitchImageCache.ThemeMode.Dark,
			TwitchImageCache.EmoteSize.Small
		)
		if tex != null:
			text.add_image(tex, 0, 20)
		else:
			append_bbcode(message_text.substr(start, end - start))
			missing_emotes = true

		last = emote["char_range"]["end"]
	append_bbcode(message_text.substr(last, message_text.length() - last))

	text.pop_all()

	# Get notified when emotes are loaded if we're missing some
	if missing_emotes and not TwitchImageCache.emote_loaded.is_connected(setup):
		TwitchImageCache.emote_loaded.connect(setup)
	if not missing_emotes and TwitchImageCache.emote_loaded.is_connected(setup):
		TwitchImageCache.emote_loaded.disconnect(setup)
	if not missing_emotes and not emitted_emotes and witch != null:
		for emote in data["emotes"]:
			var tex = TwitchImageCache.get_emote(
				emote["id"],
				TwitchImageCache.ThemeMode.Dark,
				TwitchImageCache.EmoteSize.Small
			)
			witch.process_emote(tex)
			emitted_emotes = true

# Like `append_text`, but parses both open AND close bbcode tags instead of just
# open tags.
func append_bbcode(s: String) -> void:
	var arr = s.split("[", true, 1)
	text.append_text(arr[0])
	if arr.size() > 1:
		parse_bbcode_tag(arr[1])

func parse_bbcode_tag(s: String) -> void:
	var arr = s.split("]", true, 1)
	match arr[0]:
		"b":
			text.push_bold()
		"/b":
			text.pop()
		"i":
			text.push_italics()
		"/i":
			text.pop()
		"u":
			text.push_underline()
		"/u":
			text.pop()
		"s":
			text.push_strikethrough()
		"/s":
			text.pop()

	if arr.size() > 1:
		append_bbcode(arr[1])
