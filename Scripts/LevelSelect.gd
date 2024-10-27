class_name LevelSelect
extends Control

@export var worlds: Array[Control] = []
@onready var world_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var next_world_button: Button = $"Next World Button"
@onready var previous_world_button: Button = $"Previous World Button"

func _ready() -> void:
	change_worlds(GameManager.current_world)
	#var i: int = 0
	#for level: PackedScene in GameManager.levels:
		#var spawned_obj : LevelWeenie = weenie_prefab.instantiate() as LevelWeenie
		#i += 1
		#spawned_obj.level_idx = i
		#spawned_obj.scene_to_load = level
		#weenie_container.add_child(spawned_obj)
		#if i == 0:
			#spawned_obj.grab_focus()

func change_worlds(idx: int = 0) -> void:
	if idx < 0 or idx >= worlds.size():
		print("Tried to switch to world #", idx, " but that world don't exist!")
		return
	GameManager.current_world = idx
	var i: int = 0
	for world: Control in worlds:
		if idx == i:
			world.visible = true
			world.reparent(world_container)
			world_container.move_child(world,0)
			
		else:
			world.visible = false
		i+= 1
	
	previous_world_button.visible = idx != 0
	next_world_button.visible = idx != worlds.size()-1

func next_world() -> void:
	change_worlds(GameManager.current_world + 1)

func previous_world() -> void:
	change_worlds(GameManager.current_world - 1)
