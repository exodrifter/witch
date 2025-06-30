## Automates a value in radians.
##
## The value is wrapped to be within the range [code][0, TAU)[/code]
class_name AutoRadians
extends Auto

#region State

## The initial state of the current interpolation.
var initial: FloatState

## The target desired value of the current interpolation.
var desired: float:
	set(value):
		var from := current_state

		# Discard extra rotations
		var n: int = 0
		if from.position < 0 && value < 0:
			n = maxi(ceili(from.position/TAU), ceili(value/TAU))
		if from.position > 0 && value > 0:
			n = mini(floori(from.position/TAU), floori(value/TAU))
		from.position = from.position - n * TAU
		value = value - n * TAU

		if desired != value:
			initial = from
			desired = value
			elapsed = 0

## The current value.
var current: float:
	get:
		return current_state.position

## The state of the current interpolation.
var current_state: FloatState:
	get:
		var from := FloatState.new(initial.position, initial.velocity)
		var to := desired

		var result := mode.automate_float(from, to, elapsed)
		return result

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
