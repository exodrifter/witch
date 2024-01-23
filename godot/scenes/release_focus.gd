extends TextEdit

@onready var note = $"../../.."

func _process(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		release_focus()

	if text == "":
		note.self_modulate = Color.TRANSPARENT
	else:
		note.self_modulate = Color.WHITE
