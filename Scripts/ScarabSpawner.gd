extends Node2D

const SCARAB_BEETLE = preload("res://Prefabs/Spawn On Blocks/Scarab_Beetle.tscn")

@onready var scarab_spawn_timer: Timer = $"Scarab Spawn Timer"

func spawn_scarab() -> void:
	var new_scarab: Node2D = SCARAB_BEETLE.instantiate()
	add_child(new_scarab)
	new_scarab.global_position = global_position
