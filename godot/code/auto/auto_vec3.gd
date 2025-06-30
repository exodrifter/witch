## Automates a [Vector3] value.
class_name AutoVector3
extends Auto

#region State

## The initial state of the current interpolation.
var initial: Vector3State

## The target desired value of the current interpolation.
var desired: Vector3:
	set(value):
		if desired != value:
			initial = current_state
			desired = value
			elapsed = 0

## The current value.
var current: Vector3:
	get:
		return current_state.position

## The state of the current interpolation.
var current_state: Vector3State:
	get:
		return mode.automate_vec3(initial, desired, elapsed)

#endregion

#region Functions

## Immediately use the specified value.
func reset_to(target: Vector3) -> void:
	initial = current_state
	desired = target
	elapsed = 0

## Call this function every frame during [code]_process[/code] to update the
## internal state of the interpolation.
##
## Returns the current interpolated value after the [code]delta[/code] time is
## accounted for.
func update(delta: float) -> Vector3:
	elapsed += delta
	return current

#endregion

#region Internal

func _init(initial_value: Vector3, auto_mode: Mode) -> void:
	mode = auto_mode
	initial = Vector3State.new(initial_value, Vector3.ZERO)
	desired = initial_value

func _to_string() -> String:
	return "%s, Vector3 %s -> %s: %s" % \
		[super(), initial, desired, current_state]

#endregion
