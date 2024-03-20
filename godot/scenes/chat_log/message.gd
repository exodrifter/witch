class_name Message
extends Entry

var color_bar: ColorRect:
	get:
		return $ColorBar

var text: RichTextLabel:
	get:
		return $Text

func setup_privmsg(cache: ImageCache, data: WitchPrivmsgMessage) -> void:
	setup_with_privmsg(data)

	if data.badges.any(func(a: WitchBadge): return a.name == "broadcaster"):
		color_bar.color = Color.RED
	elif data.source.tags.has("mod"):
		color_bar.color = Color.GREEN
	elif data.source.tags.has("vip"):
		color_bar.color = Color.PURPLE
	else:
		color_bar.color = Color.TRANSPARENT

	text.clear()

	if data.is_action:
		text.push_italics()

	# Show the user
	if data.name_color != Color.TRANSPARENT:
		text.push_color(data.name_color)
	else:
		text.push_color(Color.WHITE)
	append_bbcode(data.sender.name)
	if data.is_action:
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
	for emote in data.emotes:
		emote = emote as WitchEmote
		var start = emote.char_range.start
		var end = emote.char_range.end
		append_bbcode(data.message_text.substr(last, start - last))

		# Add the emote if it is loaded
		var tex = cache.get_emote(
			emote.id,
			ImageCache.ThemeMode.Dark,
			ImageCache.EmoteSize.Small
		)
		if tex != null:
			text.add_image(tex, 0, 20)
		else:
			append_bbcode(data.message_text.substr(start, end - start))
			missing_emotes = true

		last = emote.char_range.end
	append_bbcode(data.message_text.substr(last, data.message_text.length() - last))

	text.pop_all()

	# Get notified when emotes are loaded if we're missing some
	var setup = setup_privmsg.bind(data)
	if missing_emotes and not cache.emote_loaded.is_connected(setup):
		cache.emote_loaded.connect(setup)
	if not missing_emotes and cache.emote_loaded.is_connected(setup):
		cache.emote_loaded.disconnect(setup)

func setup_user_notice(cache: ImageCache, data: WitchUserNoticeMessage) -> void:
	setup_with_user_notice(data)

	if data.badges.any(func(a: WitchBadge): return a.name == "broadcaster"):
		color_bar.color = Color.RED
	elif data.source.tags.has("mod"):
		color_bar.color = Color.GREEN
	elif data.source.tags.has("vip"):
		color_bar.color = Color.PURPLE
	else:
		color_bar.color = Color.TRANSPARENT

	text.clear()

	if data.is_action:
		text.push_italics()

	# Show the user
	if data.name_color != Color.TRANSPARENT:
		text.push_color(data.name_color)
	else:
		text.push_color(Color.WHITE)
	append_bbcode(data.sender.name)
	if data.is_action:
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
	for emote in data.emotes:
		emote = emote as WitchEmote
		var start = emote.char_range.start
		var end = emote.char_range.end
		append_bbcode(data.message_text.substr(last, start - last))

		# Add the emote if it is loaded
		var tex = cache.get_emote(
			emote.id,
			ImageCache.ThemeMode.Dark,
			ImageCache.EmoteSize.Small
		)
		if tex != null:
			text.add_image(tex, 0, 20)
		else:
			append_bbcode(data.message_text.substr(start, end - start))
			missing_emotes = true

		last = emote.char_range.end
	append_bbcode(data.message_text.substr(last, data.message_text.length() - last))

	text.pop_all()

	# Get notified when emotes are loaded if we're missing some
	var setup = setup_privmsg.bind(data, cache)
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
