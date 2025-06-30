## Defines an interpolation mode which half-life decays to a target value.
##
## [codeblock]
## # a = initial position
## # b = target position
## # h = the half life
## # t = the elapsed time
##
## b + (b - a) * (1 - 0.5^(t/h))
## [/codeblock]
##
## Taking the derivative to find the new velocity as a function of time yields:
##
## [codeblock]
## 2^(-t/h) * (ln(2) * (b-a) / h)
## [/codeblock]
class_name HalfLifeMode
extends Mode

func automate_float(from: FloatState, to: float, elapsed: float) -> FloatState:
	var t: float = 1 - pow(0.5, elapsed / half_life)
	var new_position: float = lerpf(from.position, to, t)
	var new_velocity: float = \
			pow(2, -elapsed / half_life) * \
			(log(2) * (to-from.position) / half_life)
	return FloatState.new(new_position, new_velocity)

func automate_vec2(from: Vector2State, to: Vector2, elapsed: float) -> Vector2State:
	var t: float = 1 - pow(0.5, elapsed / half_life)
	var new_position: Vector2 = from.position.lerp(to, t)
	var new_velocity: Vector2 = \
			pow(2, -elapsed / half_life) * \
			(log(2) * (to-from.position) / half_life)
	return Vector2State.new(new_position, new_velocity)

func automate_vec3(from: Vector3State, to: Vector3, elapsed: float) -> Vector3State:
	var t: float = 1 - pow(0.5, elapsed / half_life)
	var new_position: Vector3 = from.position.lerp(to, t)
	var new_velocity: Vector3 = \
			pow(2, -elapsed / half_life) * \
			(log(2) * (to-from.position) / half_life)
	return Vector3State.new(new_position, new_velocity)

func automate_vec4(from: Vector4State, to: Vector4, elapsed: float) -> Vector4State:
	var t: float = 1 - pow(0.5, elapsed / half_life)
	var new_position: Vector4 = from.position.lerp(to, t)
	var new_velocity: Vector4 = \
			pow(2, -elapsed / half_life) * \
			(log(2) * (to-from.position) / half_life)
	return Vector4State.new(new_position, new_velocity)

#region Internal

## The half-life of the old value.
##
## For example, if [code]half_life[/code] is [code]1[/code], after one second
## you would be 50% of the way to the new value and after two seconds you would
## be 75% of the way there.
@export var half_life: float

## Exponentially decay to a new value by 50% every [code]x[/code] seconds.
func _init(x: float = 1) -> void:
	half_life = x

func _to_string() -> String:
	return "HalfLife (%.2f seconds)" % half_life

#endregion
