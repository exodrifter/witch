class_name FloatState
extends Resource

@export var position: float
@export var velocity: float

func _init(pos: float = 0, vel: float = 0) -> void:
	position = pos
	velocity = vel

func _to_string() -> String:
	return "<x: %.3f, x': %.3f>" % [position, velocity]
