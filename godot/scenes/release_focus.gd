extends TextEdit

func _process(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		release_focus()
