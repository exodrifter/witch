## Base class for defining an automation mode which interpolates to a target
## value.
##
## This class on its own will not do any automation.
class_name Mode
extends Resource

func automate_float(_from: FloatState, to: float, _elapsed: float) -> FloatState:
	return FloatState.new(to, 0)

func automate_vec2(_from: Vector2State, to: Vector2, _elapsed: float) -> Vector2State:
	return Vector2State.new(to, Vector2.ZERO)

func automate_vec3(_from: Vector3State, to: Vector3, _elapsed: float) -> Vector3State:
	return Vector3State.new(to, Vector3.ZERO)

func automate_vec4(_from: Vector4State, to: Vector4, _elapsed: float) -> Vector4State:
	return Vector4State.new(to, Vector4.ZERO)

func _to_string() -> String:
	return "No Automation Mode"
