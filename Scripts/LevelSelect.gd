class_name LevelSelect
extends Control

@export var temples: Array[Control] = []
@onready var temple_container: Container = $"MarginContainer/VBoxContainer/Temple Container"
@onready var next_temple_button: Button = $"Next Temple Button"
@onready var previous_temple_button: Button = $"Previous Temple Button"


func _ready() -> void:
	change_temple(GameManager.current_temple)
	#var i: int = 0
	#for level: PackedScene in GameManager.levels:
		#var spawned_obj : LevelWeenie = weenie_prefab.instantiate() as LevelWeenie
		#i += 1
		#spawned_obj.level_idx = i
		#spawned_obj.scene_to_load = level
		#weenie_container.add_child(spawned_obj)
		#if i == 0:
			#spawned_obj.grab_focus()

func change_temple(idx: int = 0) -> void:
	if idx < 0 or idx >= temples.size():
		print("Tried to switch to world #", idx, " but that world don't exist!")
		return
	GameManager.current_temple = idx
	var i: int = 0
	for temple: Control in temples:
		if idx == i:
			temple.visible = true
			temple.reparent(temple_container)
			temple_container.move_child(temple,0)
			
		else:
			temple.visible = false
		i+= 1
	
	previous_temple_button.visible = idx != 0
	next_temple_button.visible = idx != temples.size()-1

func next_temple() -> void:
	change_temple(GameManager.current_temple + 1)

func previous_temple() -> void:
	change_temple(GameManager.current_temple - 1)
