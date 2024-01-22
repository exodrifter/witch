## A sound bank is a way to store and retrieve a random sound to play.
class_name SoundBank
extends Resource

## A list of sounds to play
@export var sounds: Array[AudioStream]

func random() -> AudioStream: 
	var index = randi_range(0, sounds.size() - 1)
	return sounds[index]
