class_name ImageCache
extends Node

@export var twitch: TwitchEventNode

var cache: Dictionary = {}

func get_emote_1x(fragment: GFragments) -> Variant:
	if not cache.has(fragment.text):
		var url := twitch.get_emote_url_1x(fragment)
		cache[fragment.text] = twitch.get_generic_emote_texture_from_url(url)
	return cache[fragment.text]

func get_emote_2x(fragment: GFragments) -> Variant:
	if not cache.has(fragment.text):
		var url := twitch.get_emote_url_2x(fragment)
		cache[fragment.text] = twitch.get_generic_emote_texture_from_url(url)
	return cache[fragment.text]

func get_emote_3x(fragment: GFragments) -> Variant:
	if not cache.has(fragment.text):
		var url := twitch.get_emote_url_3x(fragment)
		cache[fragment.text] = twitch.get_generic_emote_texture_from_url(url)
	return cache[fragment.text]
