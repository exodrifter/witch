## Defines an interpolation mode which uses a critically damped spring to
## interpolate to a target value.
##
## The equation to get the new position as a function of time using a critically
## damped spring is:
##
## [codeblock]
## # x₀  = initial position
## # x'₀ = initial velocity
## # ω   = the square root of the spring constant divided by the mass at the end
##         of the spring
## # t   = the elapsed time
##
## (x₀ + (x'₀ + x₀ω) × t) × e^-ωt
## [/codeblock]
##
## See:[br]
## - http://mathproofs.blogspot.com/2013/07/critically-damped-spring-smoothing.html[br]
## - https://github.com/RobotLocomotion/drake/blob/01f0a85994c75b5ab4602707b57be0bed18a4389/multibody/benchmarks/mass_damper_spring/mass_damper_spring_analytical_solution.cc#L34[br]
class_name CriticalDampingMode
extends Mode

## The square root of the spring constant divided by the mass at the end of the
## spring, or [code]sqrt(k/mass)[/code].
@export var w: float

func automate_float(from: FloatState, to: float, elapsed: float) -> FloatState:
	var A: float = (from.position - to)
	var B: float = from.velocity + w * (from.position - to)

	var factor1: float = A + B * elapsed
	var factor2: float = exp(-w * elapsed)
	var new_position := to + (factor1 * factor2)

	var factor1Dt: float = B
	var factor2Dt: float = -w * exp(-w * elapsed);
	var new_velocity := factor1Dt * factor2 + factor1 * factor2Dt;

	return FloatState.new(new_position, new_velocity)

func automate_vec2(from: Vector2State, to: Vector2, elapsed: float) -> Vector2State:
	var A: Vector2 = (from.position - to)
	var B: Vector2 = from.velocity + w * (from.position - to)

	var factor1: Vector2 = A + B * elapsed
	var factor2: float = exp(-w * elapsed)
	var new_position := to + (factor1 * factor2)

	var factor1Dt: Vector2 = B
	var factor2Dt: float = -w * exp(-w * elapsed);
	var new_velocity := factor1Dt * factor2 + factor1 * factor2Dt;

	return Vector2State.new(new_position, new_velocity)

func automate_vec3(from: Vector3State, to: Vector3, elapsed: float) -> Vector3State:
	var A: Vector3 = (from.position - to)
	var B: Vector3 = from.velocity + w * (from.position - to)

	var factor1: Vector3 = A + B * elapsed
	var factor2: float = exp(-w * elapsed)
	var new_position := to + (factor1 * factor2)

	var factor1Dt: Vector3 = B
	var factor2Dt: float = -w * exp(-w * elapsed);
	var new_velocity := factor1Dt * factor2 + factor1 * factor2Dt;

	return Vector3State.new(new_position, new_velocity)

func automate_vec4(from: Vector4State, to: Vector4, elapsed: float) -> Vector4State:
	var A: Vector4 = (from.position - to)
	var B: Vector4 = from.velocity + w * (from.position - to)

	var factor1: Vector4 = A + B * elapsed
	var factor2: float = exp(-w * elapsed)
	var new_position := to + (factor1 * factor2)

	var factor1Dt: Vector4 = B
	var factor2Dt: float = -w * exp(-w * elapsed);
	var new_velocity := factor1Dt * factor2 + factor1 * factor2Dt;

	return Vector4State.new(new_position, new_velocity)

#region Internal

func _init(_w: float = 1) -> void:
	w = _w

func _to_string() -> String:
	return "CriticalDamping (in %.2f seconds at max speed)" % 0

#endregion
