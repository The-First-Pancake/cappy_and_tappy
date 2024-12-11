@tool
class_name  LevelInfo
extends Node2D

enum TEMPLE_TYPE{
	AZTEC,
	EGYPT,
	CAVE,
}


@export var temple_type: TEMPLE_TYPE = TEMPLE_TYPE.AZTEC:
	set(new_val):
		temple_type = new_val
		if not is_inside_tree():
			return
		update_temple_type()

func update_temple_type() -> void:
	var music_player: AudioStreamPlayer = %Music
	var environment: TileMapLayer = $Environment
	var background: TextureRect = $"Background Parallax/Background"
	var entrance_door: Door = $"Entrance Door"
	var exit_door: Door = $"Exit Door"
	
	if temple_type == TEMPLE_TYPE.AZTEC:
		if !override_music:
			music_player.stream = preload("res://Sound/Music/music_main.wav")
			music_player.volume_db = -7
		environment.tile_set = preload("res://Art/Tilemaps/Tilemap_Brown Bricks.tres")
		background.texture = preload("res://Art/Sprites/Backgrounds/background.png")
		entrance_door.door_frame_texture = preload("res://Art/Sprites/door/Door_Foreground.png")
		exit_door.door_frame_texture = preload("res://Art/Sprites/door/Door_Foreground.png")
	
	if temple_type == TEMPLE_TYPE.EGYPT:
		if !override_music:
			music_player.stream = preload("res://Sound/Music/the pharaoh's curse.wav")
			music_player.volume_db = -9
		environment.tile_set = preload("res://Art/Tilemaps/Tilemap_Egypt.tres")
		background.texture = preload("res://Art/Tilemaps/Background_Egypt.png")
		entrance_door.door_frame_texture = preload("res://Art/Sprites/egypt/door_diffuse.png")
		exit_door.door_frame_texture = preload("res://Art/Sprites/egypt/door_diffuse.png")

@export var dark: bool = false:
	set(new_val):
		dark = new_val
		if not is_inside_tree():
			return
		update_lights()

func update_lights() -> void:
	var dark_layer: CanvasModulate = $"Dark Layer"
	var night_light: PointLight2D = $Camera2D/UI/NightLight
	
	dark_layer.visible = dark
	night_light.visible = dark

@export var override_music: AudioStream = null:
	set (new_val):
		override_music = new_val
		if not is_inside_tree():
			return
		set_music_to_override()

func set_music_to_override() -> void:
	if override_music:
		var music_player: AudioStreamPlayer = %Music
		music_player.stream = override_music

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_temple_type()
	update_lights()
	set_music_to_override()
	GameManager.level_info = self
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
