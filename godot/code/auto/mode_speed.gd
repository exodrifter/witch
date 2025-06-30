## Defines an automation mode which interpolates to a target value at a fixed
## speed.
class_name SpeedMode
extends Mode

func automate_float(from: FloatState, to: float, elapsed: float) -> FloatState:
	if is_zero_approx(speed):
		return FloatState.new(from.position, 0)

	var time: float = absf(from.position - to) / speed
	if is_zero_approx(time):
		return FloatState.new(to, 0)

	var weight: float = clampf(elapsed / time, 0, 1)
	var new_position: float = lerp(from.position, to, weight)
	var new_velocity: float = signf(new_position - to) * speed
	return FloatState.new(new_position, new_velocity)

func automate_vec2(from: Vector2State, to: Vector2, elapsed: float) -> Vector2State:
	if is_zero_approx(speed):
		return Vector2State.new(from.position, Vector2.ZERO)
	else:
		var time: float = from.position.distance_to(to) / speed
		var weight: float = clampf(elapsed / time, 0, 1)

		var new_position: Vector2 = lerp(from.position, to, weight)
		var new_velocity: Vector2
		if is_equal_approx(weight, 1):
			new_velocity = Vector2.ZERO
		else:
			new_velocity = from.position.direction_to(to) * speed

		return Vector2State.new(new_position, new_velocity)

func automate_vec3(from: Vector3State, to: Vector3, elapsed: float) -> Vector3State:
	if is_zero_approx(speed):
		return Vector3State.new(from.position, Vector3.ZERO)
	else:
		var time: float = from.position.distance_to(to) / speed
		var weight: float = clampf(elapsed / time, 0, 1)

		var new_position: Vector3 = lerp(from.position, to, weight)
		var new_velocity: Vector3
		if is_equal_approx(weight, 1):
			new_velocity = Vector3.ZERO
		else:
			new_velocity = from.position.direction_to(to) * speed

		return Vector3State.new(new_position, new_velocity)

func automate_vec4(from: Vector4State, to: Vector4, elapsed: float) -> Vector4State:
	if is_zero_approx(speed):
		return Vector4State.new(from.position, Vector4.ZERO)
	else:
		var time: float = from.position.distance_to(to) / speed
		var weight: float = clampf(elapsed / time, 0, 1)

		var new_position: Vector4 = lerp(from.position, to, weight)
		var new_velocity: Vector4
		if is_equal_approx(weight, 1):
			new_velocity = Vector4.ZERO
		else:
			new_velocity = from.position.direction_to(to) * speed

		return Vector4State.new(new_position, new_velocity)

#region Internal

## The speed in units per second.
##
## For example, if [code]s[/code] is [code].5[/code] and your starting value is
## [code]1[/code] and your target value is [code]2[/code], then after one second
## you would have a value of [code]1.5[/code] and after two seconds you would
## have a value of [code]2[/code].
@export var speed: float

## Linearly interpolate at some fixed speed [code]s[/code] in units per
## second.
func _init(s: float = 0) -> void:
	speed = s

func _to_string() -> String:
	return "Speed (%.2f units per second)" % speed

#endregion
