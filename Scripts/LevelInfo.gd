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
		var music: AudioStreamPlayer = %Music
		var environment: TileMapLayer = $Environment
		var background: TextureRect = $"Background Parallax/Background"
		var entrance_door: Door = $"Entrance Door"
		var exit_door: Door = $"Exit Door"
		
		
		if temple_type == TEMPLE_TYPE.EGYPT:
			music.stream = preload("res://Sound/Music/the pharaoh's curse.wav")
			music.volume_db = -9
			environment.tile_set = preload("res://Art/Tilemaps/Tilemap_Egypt.tres")
			background.texture = preload("res://Art/Tilemaps/Background_Egypt.png")
			entrance_door.door_frame_texture = preload("res://Art/Sprites/egypt/door_diffuse.png")
			exit_door.door_frame_texture = preload("res://Art/Sprites/egypt/door_diffuse.png")
			

@export var dark: bool = false:
	set(new_val):
		dark = new_val
		var dark_layer: CanvasModulate = $"Dark Layer"
		var overhead_light: Node2D = $"Overhead Light"
		var night_light: PointLight2D = $Camera2D/UI/NightLight
		
		dark_layer.visible = dark
		overhead_light.visible = !dark
		night_light.visible = dark

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
