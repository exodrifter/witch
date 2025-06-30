## Automates a [float] value.
class_name AutoFloat
extends Auto

#region State

## The initial state of the current interpolation.
var initial: FloatState

## The target desired value of the current interpolation.
var desired: float:
	set(value):
		if desired != value:
			initial = current_state
			desired = value
			elapsed = 0

## The current value.
var current: float:
	get:
		return current_state.position

## The state of the current interpolation.
var current_state: FloatState:
	get:
		return mode.automate_float(initial, desired, elapsed)

#endregion

#region Functions

## Immediately use the specified value.
func reset_to(target: float) -> void:
	initial = current_state
	desired = target
	elapsed = 0

## Call this function every frame during [code]_process[/code] to update the
## internal state of the interpolation.
##
## Returns the current interpolated value after the [code]delta[/code] time is
## accounted for.
func update(delta: float) -> float:
	elapsed += delta
	return current

#endregion

#region Internal

func _init(initial_value: float, auto_mode: Mode) -> void:
	mode = auto_mode
	initial = FloatState.new(initial_value, 0)
	desired = initial_value

func _to_string() -> String:
	return "%s, float %s -> %s: %s" % \
		[super(), initial, desired, current_state]

#endregion
