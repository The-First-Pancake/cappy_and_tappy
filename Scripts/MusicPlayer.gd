extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	var title_music : AudioStreamPlayer = %Music as AudioStreamPlayer
	AudioManager.PlayMusic(title_music)
