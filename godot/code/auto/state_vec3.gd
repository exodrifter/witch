class_name Vector3State
extends Resource

@export var position: Vector3
@export var velocity: Vector3

func _init(pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO) -> void:
	position = pos
	velocity = vel

func _to_string() -> String:
	return "<x: %.3v, x': %.3v>" % [position, velocity]
