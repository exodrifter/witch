class_name Message
extends RichTextLabel

var data: Dictionary = {}:
	set(value):
		data = value
		setup()

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
	setup()

func _process(_delta) -> void:
	if global_position.y > 720:
		queue_free()

func setup() -> void:
	clear()
	if data.is_empty():
		return

	name = message_id

	if is_action:
		push_italics()

	# Show the user
	push_color(user_color)
	append_bbcode(user_name)
	if is_action:
		append_bbcode(" ")
	else:
		append_bbcode(": ")
		pop()

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
			add_image(tex, 0, 20)
		else:
			append_bbcode(message_text.substr(start, end - start))
			missing_emotes = true

		last = emote["char_range"]["end"]
	append_bbcode(message_text.substr(last, message_text.length() - last))

	if is_action:
		pop() # End color
		pop() # End italics

	# Get notified when emotes are loaded if we're missing some
	if missing_emotes and not TwitchImageCache.emote_loaded.is_connected(setup):
		TwitchImageCache.emote_loaded.connect(setup)
	if not missing_emotes and TwitchImageCache.emote_loaded.is_connected(setup):
		TwitchImageCache.emote_loaded.disconnect(setup)

# Like `append_text`, but parses both open AND close bbcode tags instead of just
# open tags.
func append_bbcode(str: String) -> void:
	var arr = str.split("[", true, 1)
	append_text(arr[0])
	if arr.size() > 1:
		parse_bbcode_tag(arr[1])

func parse_bbcode_tag(str: String) -> void:
	var arr = str.split("]", true, 1)
	match arr[0]:
		"b":
			push_bold()
		"/b":
			pop()
		"i":
			push_italics()
		"/i":
			pop()
		"u":
			push_underline()
		"/u":
			pop()
		"s":
			push_strikethrough()
		"/s":
			pop()
	if arr.size() > 1:
		append_bbcode(arr[1])
