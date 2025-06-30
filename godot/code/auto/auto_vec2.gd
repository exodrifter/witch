## Automates a [Vector2] value.
class_name AutoVector2
extends Auto

#region State

## The initial state of the current interpolation.
var initial: Vector2State

## The target desired value of the current interpolation.
var desired: Vector2:
	set(value):
		if desired != value:
			initial = current_state
			desired = value
			elapsed = 0

## The current value.
var current: Vector2:
	get:
		return current_state.position

## The state of the current interpolation.
var current_state: Vector2State:
	get:
		return mode.automate_vec2(initial, desired, elapsed)

#endregion

#region Functions

## Immediately use the specified value.
func reset_to(target: Vector2) -> void:
	initial = current_state
	desired = target
	elapsed = 0

## Call this function every frame during [code]_process[/code] to update the
## internal state of the interpolation.
##
## Returns the current interpolated value after the [code]delta[/code] time is
## accounted for.
func update(delta: float) -> Vector2:
	elapsed += delta
	return current

#endregion

#region Internal

func _init(initial_value: Vector2, auto_mode: Mode) -> void:
	mode = auto_mode
	initial = Vector2State.new(initial_value, Vector2.ZERO)
	desired = initial_value

func _to_string() -> String:
	return "%s, Vector2 %s -> %s: %s" % \
		[super(), initial, desired, current_state]

#endregion
