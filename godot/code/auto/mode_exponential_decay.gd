## Defines an interpolation mode which exponentially decays to a new value.
##
## The equation to get the new position as a function of time using exponential
## decay is:
##
## [codeblock]
## # a = initial position
## # b = target position
## # p = the amount of decay
## # t = the elapsed time
##
## b + (b - a) * (1 - p^t)
## [/codeblock]
##
## Taking the derivative to find the new velocity as a function of time yields:
##
## [codeblock]
## (b - a) * p^t
## [/codeblock]
class_name ExponentialDecayMode
extends Mode

func automate_float(from: FloatState, to: float, elapsed: float) -> FloatState:
	var weight: float = pow(p, elapsed)
	var new_position: float = lerpf(from.position, to, 1 - weight)
	var new_velocity: float = (from.position - to) * weight
	return FloatState.new(new_position, new_velocity)

func automate_vec2(from: Vector2State, to: Vector2, elapsed: float) -> Vector2State:
	var weight: float = pow(p, elapsed)
	var new_position: Vector2 = from.position.lerp(to, 1 - weight)
	var new_velocity: Vector2 = (from.position - to) * weight
	return Vector2State.new(new_position, new_velocity)

func automate_vec3(from: Vector3State, to: Vector3, elapsed: float) -> Vector3State:
	var weight: float = pow(p, elapsed)
	var new_position: Vector3 = from.position.lerp(to, 1 - weight)
	var new_velocity: Vector3 = (from.position - to) * weight
	return Vector3State.new(new_position, new_velocity)

func automate_vec4(from: Vector4State, to: Vector4, elapsed: float) -> Vector4State:
	var weight: float = pow(p, elapsed)
	var new_position: Vector4 = from.position.lerp(to, 1 - weight)
	var new_velocity: Vector4 = (from.position - to) * weight
	return Vector4State.new(new_position, new_velocity)

#region Internal

## The amount of decay.
##
## For example, if [code]p[/code] is [code]0.25[/code], after one second you
## would be 75% of the way to the new value and after two seconds you would
## be 93.75% of the way there.
@export_range(0, 1, 0.01) var p: float

## Exponentially decay to a new value by keeping a proportion [code]_p[/code] of
## the original value every second.
func _init(_p: float = 0.5) -> void:
	p = _p

func _to_string() -> String:
	return "ExponentialDecay (%.2f per second)" % p

#endregion
