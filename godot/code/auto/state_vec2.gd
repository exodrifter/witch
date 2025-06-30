class_name Vector2State
extends Resource

@export var position: Vector2
@export var velocity: Vector2

func _init(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO) -> void:
	position = pos
	velocity = vel

func _to_string() -> String:
	return "<x: %.3v, x': %.3v>" % [position, velocity]
