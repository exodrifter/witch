class_name SoundBankPlayer
extends AudioStreamPlayer

@export var bank: SoundBank

func play_random():
	stream = bank.random()
	play()
