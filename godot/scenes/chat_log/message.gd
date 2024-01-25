class_name Message
extends Entry

var data: Dictionary = {}:
	set(value):
		data = value

@onready var color_bar = $ColorBar
@onready var text = $Text

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
		if data.has("badges"):
			for badge in data["badges"]:
				if badge.has("name") and badge["name"] == "broadcaster":
					return true
		return false

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

func setup(cache: ImageCache) -> void:
	setup_color_bar()
	setup_text(cache)

func setup_color_bar() -> void:
	if is_broadcaster:
		color_bar.color = Color.RED
	elif is_mod:
		color_bar.color = Color.GREEN
	elif is_vip:
		color_bar.color = Color.PURPLE
	else:
		color_bar.color = Color.TRANSPARENT

func setup_text(cache: ImageCache) -> void:
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

	# Highlight the message
	if data.source.tags.has("msg-id") and data.source.tags["msg-id"]:
		text.push_bgcolor(Color(0.459, 0.369, 0.737))

	# Show the message
	var missing_emotes = false
	var last = 0
	for emote in data["emotes"] if data.has("emotes") else []:
		var start = emote["char_range"]["start"]
		var end = emote["char_range"]["end"]
		append_bbcode(message_text.substr(last, start - last))

		# Add the emote if it is loaded
		var tex = cache.get_emote(
			emote["id"],
			ImageCache.ThemeMode.Dark,
			ImageCache.EmoteSize.Small
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
	if missing_emotes and not cache.emote_loaded.is_connected(setup):
		cache.emote_loaded.connect(setup)
	if not missing_emotes and cache.emote_loaded.is_connected(setup):
		cache.emote_loaded.disconnect(setup)

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
