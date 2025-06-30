class_name Vector4State
extends Resource

@export var position: Vector4
@export var velocity: Vector4

func _init(pos: Vector4 = Vector4.ZERO, vel: Vector4 = Vector4.ZERO) -> void:
	position = pos
	velocity = vel

func _to_string() -> String:
	return "<x: %.3v, x': %.3v>" % [position, velocity]
