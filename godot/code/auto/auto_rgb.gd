## Automates the RGB components of a [Color] value.
class_name AutoRGB
extends Auto

#region State

## The initial state of the current interpolation.
var initial: Vector4State

## The target desired value of the current interpolation.
var desired: Color:
	set(value):
		if desired != value:
			initial = current_state
			desired = value
			elapsed = 0

## The current value.
var current: Color:
	get:
		return _vec4_to_rgb(current_state.position)

## The state of the current interpolation.
var current_state: Vector4State:
	get:
		return mode.automate_vec4(initial, _rgb_to_vec4(desired), elapsed)

#endregion

#region Functions

## Immediately use the specified value.
func reset_to(target: Color) -> void:
	initial = current_state
	desired = target
	elapsed = 0

## Call this function every frame during [code]_process[/code] to update the
## internal state of the interpolation.
##
## Returns the current interpolated value after the [code]delta[/code] time is
## accounted for.
func update(delta: float) -> Color:
	elapsed += delta
	return current

#endregion

#region Internal

func _init(initial_value: Color, auto_mode: Mode) -> void:
	mode = auto_mode
	initial = Vector4State.new(_rgb_to_vec4(initial_value), Vector4.ZERO)
	desired = initial_value

func _to_string() -> String:
	return "%s, RGB Color %s -> %s: %s" % \
		[super(), initial, desired, current_state]

func _vec4_to_rgb(v: Vector4) -> Color:
	return Color(v.x, v.y, v.z, v.w)

func _rgb_to_vec4(c: Color) -> Vector4:
	return Vector4(c.r, c.g, c.b, c.a)

#endregion
