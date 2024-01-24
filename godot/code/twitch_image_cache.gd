class_name ImageCache
extends Node

signal emote_loaded(cache: ImageCache)

const URL: String = "https://static-cdn.jtvnw.net"

var client: HTTPClient
var response: PackedByteArray = []
var tasks: Array[Dictionary] = []

var cache_path: String
var cache: Dictionary

func _init(path: String) -> void:
	client = HTTPClient.new()
	client.connect_to_host(URL)
	if not path.ends_with("/"):
		path += "/"
	cache_path = path

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
	if not tasks.is_empty():
		var task = tasks.front()
		var path : String = "/emoticons/v2/{id}/static/{theme}/{size}".format({
			"id": task.emote_id,
			"theme": theme_mode_str(task.theme),
			"size": emote_size_str(task.size),
		})
		client.request(HTTPClient.METHOD_GET, path, ["Accept: image/png"])

func process_image() -> void:
	if response.is_empty():
		return
	var task = tasks.pop_front()
	print("Processing image for task ", task)

	# Write the texture to the memory cache
	cache[task] = make_texture(response)

	# Write the texture to the disk cache
	var disk_path = cache_path + "{theme}/{size}/".format({
		"theme": theme_mode_str(task.theme),
		"size": emote_size_str(task.size),
	})
	DirAccess.make_dir_recursive_absolute(disk_path)
	var file = FileAccess.open(
		disk_path + task.emote_id + ".png",
		FileAccess.WRITE
	)
	file.store_buffer(response)
	file.close()

	response.clear()
	emote_loaded.emit(self)

func get_emote(emote_id: String, theme: ThemeMode, size: EmoteSize) -> Texture2D:
	var task = {
		"emote_id": emote_id,
		"theme": theme,
		"size": size,
	}

	# Load from memory cache
	if cache.has(task):
		return cache[task]

	# Load from disk cache
	var disk_path = cache_path + "{theme}/{size}/{emote_id}.png".format({
		"theme": theme_mode_str(task.theme),
		"size": emote_size_str(task.size),
		"emote_id": emote_id,
	})
	if FileAccess.file_exists(disk_path):
		var bytes = FileAccess.get_file_as_bytes(disk_path)
		var texture = make_texture(bytes)
		cache[task] = texture
		return texture

	# Add the task to the queue
	if tasks.find(task) == -1:
		tasks.append(task)
	return null

func make_texture(bytes: PackedByteArray) -> ImageTexture:
	# Write the texture to the memory cache
	var img := Image.new()
	img.load_png_from_buffer(bytes)
	var texture := ImageTexture.new()
	texture.set_image(img)
	return texture

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
