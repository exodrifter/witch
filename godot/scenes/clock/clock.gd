extends MarginContainer

@onready var label: Label = %Label

func _process(_delta: float) -> void:
	var unix := Time.get_unix_time_from_system()
	var datetime := Time.get_datetime_dict_from_unix_time(unix)
	label.text = "{year}-{month}-{day} {hour}:{minute}:{second}".format({
		"year": "%04d" % datetime["year"],
		"month": "%02d" % datetime["month"],
		"day": "%02d" % datetime["day"],
		"hour": "%02d" % datetime["hour"],
		"minute": "%02d" % datetime["minute"],
		"second": "%02d" % datetime["second"],
	})
