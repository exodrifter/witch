extends GPUParticles2D

var kill_switch: bool = false

func _process(delta):
	if kill_switch and emitting == false:
		queue_free()
