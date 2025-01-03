extends Button

var speaker_on_texture: Texture2D = preload("res://Art/Sprites/UI/music.svg")
var speaker_off_texture: Texture2D = preload("res://Art/Sprites/UI/music-off.svg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_texture()

func update_texture() -> void:
	var texture_rect: TextureRect = $TextureRect

	if GameManager.current_save.setting_music_mute:
		texture_rect.texture = speaker_off_texture
	else:
		texture_rect.texture = speaker_on_texture
		

func toggle_mute() -> void:
	AudioManager.toggle_music_mute()
	update_texture()
