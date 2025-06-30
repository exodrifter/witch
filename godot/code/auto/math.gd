class_name Math
extends Node

static func lerp_wrapf(from: float, to: float, min_bound: float, max_bound: float, t: float) -> float:
	return from + wrap_difference(from, to, min_bound, max_bound) * t;

## Given that `a` and `b` are in the range [`min_bound`, `max_bound`), give the
## signed distance with the lowest absolute magnitude going from `a` to `b`.
static func wrap_difference(a: float, b: float, min_bound: float, max_bound: float) -> float:
	# Make sure that b > a
	var _range := max_bound - min_bound
	if b < a:
		b += _range

	# If the difference is greater than half the _range, then it's shorter to go
	# the other way around.
	var diff := b - a
	if diff > _range / 2:
		diff = diff - _range

	return diff
