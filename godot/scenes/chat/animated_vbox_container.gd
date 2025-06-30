class_name AnimatedVBoxContainer
extends VBoxContainer

var positions: Dictionary[Control, AutoVector2]

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			# Prune cached positions we don't need anymore
			var cached_keys := positions.keys()
			for c in get_children():
				cached_keys.erase(c)
			for key in cached_keys:
				positions.erase(key)

			# Copy the positions that the VBoxContainer determined
			for c in get_children():
				if c is not Control or c.visible == false:
					continue

				var control: Control = c
				if positions.has(control):
					positions[control].desired = control.position
				else:
					positions[control] = AutoVector2.new(
						control.position,
						CriticalDampingMode.new(10)
					)

				# Set the controls back to the old position
				control.position = positions[control].current

func _process(delta: float) -> void:
	# Animated the position of the children
	for c in get_children():
		if c is not Control:
			continue

		var control: Control = c
		if not positions.has(control):
			continue

		control.position = positions[control].update(delta)
