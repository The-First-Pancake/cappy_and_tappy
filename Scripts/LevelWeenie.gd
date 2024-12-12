@tool
class_name LevelWeenie
extends Control

var level_idx : int = 1

@export var scene_to_load: PackedScene:
	set(new_val):
		scene_to_load = new_val
		if is_node_ready():
			update_level_name()

@export var override_text: String = ""
@export var endless: bool = false

@onready var start_sound: AudioStreamPlayer = $StartGameFx
var level_title: Label:
	get:
		return $"Level Title"
@onready var completed_flames: Node2D = $CompletedFlames

var unlocked: bool = false

func update_level_name() -> void:
	var level_name: String = override_text
	if override_text == "":
		level_name = scene_to_load.resource_path.get_file().get_basename()
		level_name = level_name.get_slice(".",0)
		level_name = level_name.right(-12)
		level_name = level_name.capitalize()
		name = "Level - " + level_name
	level_title.text = level_name

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_level_name()
	
	if Engine.is_editor_hint():
		return
	
	if !GameManager.levels.has(scene_to_load):
		GameManager.levels.append(scene_to_load)
	
	level_idx = get_index()
	
	if level_idx == 0:
		#call_deferred("grab_focus") TODO: Idk what this did, but it was causing a lot of warnings
		unlocked = true
	else:
		var levels_in_this_world: Array[Node] = get_parent().get_children()
		var previous_level: LevelWeenie = levels_in_this_world[level_idx-1] as LevelWeenie
		if GameManager.current_save.is_level_complete(previous_level.scene_to_load):
			unlocked = true
	

	if (GameManager.current_save.is_level_complete(scene_to_load) or endless):
		unlocked = true
		completed_flames.show()
	
	if !unlocked:
		modulate.r /= 3
		modulate.g /= 3
		modulate.b /= 3
	if (!endless):
		var idol_1: TextureRect = $"HBoxContainer/Idol 1"
		var idol_2: TextureRect = $"HBoxContainer/Idol 2"
		var idol_3: TextureRect = $"HBoxContainer/Idol 3"
		var idols_collected : int = GameManager.current_save.how_many_idols(scene_to_load)
		if (idols_collected >= 1):
			idol_1.show()
		if (idols_collected >= 2):
			idol_1.show()
			idol_2.show()
		if (idols_collected >= 3):
			idol_1.show()
			idol_2.show()
			idol_3.show()

	if (endless):
		var high_score_idol: Label = $"HBoxContainer/High Score Idol"
		var high_score_height: Label = $"HBoxContainer/High Score Height"
		high_score_idol.text = "%02d"%GameManager.current_save.endless_high_idols
		high_score_height.text = "%03d"%GameManager.current_save.endless_high_height

	pass # Replace with function body.

func _on_mouse_entered() -> void:
	if Engine.is_editor_hint():
		return
	if !unlocked:
		return
	modulate.r /= 2
	modulate.g /= 2
	modulate.b /= 2

func _on_mouse_exited() -> void:
	if Engine.is_editor_hint():
		return
	if !unlocked:
		return
	modulate.r *= 2
	modulate.g *= 2
	modulate.b *= 2

func _on_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if !unlocked:
		return
	if event.is_action_pressed("drop_block"):	
		AudioManager.PlayAudio(start_sound)
		GameManager.load_level_from_packed(scene_to_load)
