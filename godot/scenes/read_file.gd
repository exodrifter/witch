extends RichTextLabel

@export var path: String = \
	"/home/exodrifter/.local/share/vlc/np_artist_title.txt"

const REFRESH_TIME: float = 1
var elapsed: float

func _ready():
	read_file()

func _process(delta):
	elapsed += delta
	while elapsed >= REFRESH_TIME:
		elapsed -= REFRESH_TIME
		read_file()

func read_file():
	var file := FileAccess.open(path, FileAccess.READ)
	text = file.get_as_text(true)
