## Base class for automating interpolation in a set-and-forget fashion.
##
## This class on its own doesn't do anything.
@icon("res://src/auto/auto.svg")
class_name Auto
extends RefCounted

## The type of interpolation to perform.
@export var mode: Mode

## The amount of time that has passed since the current interpolation started.
var elapsed: float

#region Internal

func _init(m: Mode) -> void:
	mode = m

func _to_string() -> String:
	return "%s, %.2f elapsed" % [mode, elapsed]

#endregion
