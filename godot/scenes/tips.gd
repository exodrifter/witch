extends RichTextLabel

const TIP_SECONDS: float = 30

@export var tips_path: String = "user://tips.txt"

var tips: Array[String] = []
var current_index: int
var elapsed: float

func _ready():
	var file := FileAccess.open(tips_path, FileAccess.READ)
	while not file.eof_reached():
		var tip = file.get_line().strip_edges()
		if tip != "":
			tips.push_back(tip)

	if tips.size() == 0:
		queue_free()
	else:
		show_tip()

	if tips.size() == 1:
		process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta):
	elapsed += delta
	while elapsed >= TIP_SECONDS:
		elapsed -= TIP_SECONDS
		current_index += 1
		if current_index >= tips.size():
			current_index = 0
		show_tip()

func show_tip():
	text = "[right]" + tips[current_index] + "[/right]"
