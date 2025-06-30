class_name AnimatedVBoxContainer
extends VBoxContainer

var positions: Dictionary[Control, AutoVector2]

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
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

func _ready() -> void:
	child_exiting_tree.connect(
		func(node: Node) -> void:
			positions.erase(node)
	)

func _process(delta: float) -> void:
	# Animated the position of the children
	for c in get_children():
		if c is not Control:
			continue

		var control: Control = c
		if not positions.has(control):
			continue

		control.position = positions[control].update(delta)
