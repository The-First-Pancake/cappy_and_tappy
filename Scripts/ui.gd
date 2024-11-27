class_name UI
extends Node2D

@export var idol_label : Label = null
@export var height_label : Label = null
@export var idol_icons: Array[Sprite2D] = []



var starting_dist : int = 0

var player_to_exit_dist : int:
	get:
		return round((GameManager.player.global_position.distance_to(GameManager.exit_door.global_position) - 50) / 50)

func _ready() -> void:
	await get_tree().process_frame
	starting_dist = player_to_exit_dist

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (is_instance_valid(GameManager.player)):
		for i in range(3):
			if i < GameManager.player.idols_collected:
				idol_icons[i].self_modulate = Color.WHITE
			else:
				idol_icons[i].self_modulate = Color(1, 1, 1, 0.129)
				

		height_label.text = "%02d"%player_to_exit_dist + "m"
