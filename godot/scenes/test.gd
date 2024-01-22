extends Node

var irc := WitchIRC.new()

func _ready():
	irc.join("exodrifter_")

func _process(_delta):
	var messages = irc.poll()
	if messages != []:
		print(messages)
