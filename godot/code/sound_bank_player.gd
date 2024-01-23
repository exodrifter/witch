class_name SoundBankPlayer
extends Node

@export var bank: SoundBank
@export var volume_db: float

func play_random():
	var player = AudioStreamPlayer.new()
	player.stream = bank.random()
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)

	player.play()
