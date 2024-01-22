extends Node

signal emote_loaded

const URL: String = "https://static-cdn.jtvnw.net"

var client: HTTPClient = HTTPClient.new()
var response: PackedByteArray = []
var queue: Array[String] = []

var cache: Dictionary

func _init() -> void:
	client.connect_to_host(URL)

func _process(_delta) -> void:
	client.poll()
	
	var status = client.get_status()
	if status != HTTPClient.STATUS_BODY:
		process_image()

	match client.get_status():
		HTTPClient.STATUS_DISCONNECTED:
			reconnect()
		HTTPClient.STATUS_RESOLVING:
			pass # Waiting for the hostname to resolve
		HTTPClient.STATUS_CANT_RESOLVE:
			pass # TODO: Try to reconnect
		HTTPClient.STATUS_CONNECTING:
			pass # Waiting for the connection to be made
		HTTPClient.STATUS_CANT_CONNECT:
			pass # TODO: Try to reconnect
		HTTPClient.STATUS_CONNECTED:
			request_next_image()
		HTTPClient.STATUS_REQUESTING:
			pass # Waiting for the request to complete
		HTTPClient.STATUS_BODY:
			response += client.read_response_body_chunk()
		HTTPClient.STATUS_CONNECTION_ERROR:
			reconnect()
		HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			pass # TODO: Try to reconnect

func reconnect() -> void:
	client.connect_to_host(URL)

func request_next_image() -> void:
	if not queue.is_empty():
		client.request(
			HTTPClient.METHOD_GET,
			queue.front(),
			["Accept: image/png"]
		)

func process_image() -> void:
	if response.is_empty():
		return

	var img := Image.new()
	img.load_png_from_buffer(response)
	response.clear()

	var path = queue.pop_front()
	var texture := ImageTexture.new()
	texture.set_image(img)
	cache[path] = texture

	emote_loaded.emit()

func get_emote(emote_id: String, theme: ThemeMode, size: EmoteSize) -> Texture2D:
	var path : String = "/emoticons/v2/{id}/static/{theme}/{size}".format({
		"id": emote_id,
		"theme": theme_mode_str(theme),
		"size": emote_size_str(size),
	})

	if cache.has(path):
		return cache[path]
	else:
		if queue.find(path) == -1:
			queue.append(path)
		return null

#region Enumerations

enum ThemeMode { Light, Dark }

func theme_mode_str(theme: ThemeMode) -> String:
	match theme:
		ThemeMode.Light:
			return "light"
		ThemeMode.Dark:
			return "dark"

	assert(false, "unknown theme mode")
	return "dark"

enum EmoteSize { Small, Medium, Large }

func emote_size_str(size: EmoteSize) -> String:
	match size:
		EmoteSize.Small:
			return "1.0"
		EmoteSize.Medium:
			return "2.0"
		EmoteSize.Large:
			return "3.0"

	assert(false, "unknown emote size")
	return "1.0"

#endregion
