extends Node

var player : Player = null
var level_info : LevelInfo = null
var entrance_door : Door = null
var exit_door : Door = null
var is_in_menu : bool = false

const GRID_SIZE: float = 50

var levels : Array[PackedScene] = []

var current_level : PackedScene = null
var level_select_scene: PackedScene:
	get:
		if OS.has_feature('demo'):
			return load("res://Levels/LevelSelect_Demo_Edition.tscn")
		else:
			return load("res://Levels/LevelSelect.tscn")
var splash_screen_scene: PackedScene = preload("res://Levels/SplashScreen.tscn")
var leaderboard_scene: PackedScene = preload("res://Levels/Leaderboard.tscn")
var pause_menu_prefab: PackedScene = preload("res://Levels/Pause Menu.tscn")
const SAVE_PATH: String = "user://save.tres"
var current_save: GameSave = null
var currently_held_object: Node2D = null
var time_since_level_loaded: float = 0
var time_since_unpause: float = 0
var current_temple: int = 0

var objects_hovering: Array[Node] = []

var current_level_info: LevelInfo:
	get:
		return get_tree().current_scene as LevelInfo

signal loading_new_scene
signal loaded_new_scene
signal game_paused

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var silentwolf_api_file: FileAccess = FileAccess.open("res://Keys/SilentwolfAPI.txt", FileAccess.READ)
	if !silentwolf_api_file:
		push_error("No API key for silentwolf found. Add folder to resources called 'Keys' and put SilentwolfAPI.txt into it")
		#get_tree().quit()
	var silentwolf_api_key: String = silentwolf_api_file.get_as_text().split("\n")[0]
	SilentWolf.configure({
		"api_key": silentwolf_api_key,
		"game_id": "Cappy&Tappy",
		"log_level": 1 #what level of info do we want printed about connectivity
	})

	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH) as GameSave
		if current_save == null: # if old save type, we have to reset
			setup_new_save()
	else:
		setup_new_save()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_since_level_loaded += delta
	time_since_unpause += delta
	
	
	if Input.is_action_just_pressed("skip_level"):
		if get_tree().current_scene is not Control: #don't allow skip in menus
			level_complete()
	#if Input.is_action_just_pressed("restart"): 
		#if get_tree().current_scene is not Control: #don't allow restart in menus
			#restart_level()
	if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("controller_start"):
		if get_tree().current_scene.name == "LevelSelect":
			load_level_from_packed(splash_screen_scene)
			return
		elif get_tree().current_scene.name != "SplashScreen":
			if !get_tree().paused:
				toggle_pause(true)
			else:
				toggle_pause(false)
	if Input.is_action_just_pressed("escape"):
		if get_tree().current_scene.name == "SplashScreen":
			if OS.get_name() != "Web":
				get_tree().quit()
	
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
var victory_screen_scene: PackedScene = preload("res://Levels/victory_screen.tscn")

func restart_level() -> void:
	loading_new_scene.emit()
	toggle_pause(false)
	get_tree().reload_current_scene()
	loaded_new_scene.emit()
	time_since_level_loaded = 0

var pause_menu: CanvasLayer = null
func toggle_pause(on: bool = true) -> void:
	if on: #pause
		if !get_tree().paused:
			pause_menu = pause_menu_prefab.instantiate() as CanvasLayer
			pause_menu.follow_viewport_enabled = false #for some god forsaken reason this makes the pause menu follow the viewport. One would think the opposite would be true. I have no words. This took me like an hour
			get_viewport().add_child(pause_menu)
			is_in_menu = true
			game_paused.emit()
		get_tree().paused = true
	else: #unpause
		time_since_unpause = 0
		if is_instance_valid(pause_menu):
			pause_menu.queue_free()
			is_in_menu =  false
		get_tree().paused = false

func level_complete() -> void:
	current_save.complete_level(current_level, player.idols_collected)
	save_game()
	if current_level == levels.back():
		load_level_from_packed(victory_screen_scene)
	else:
		load_level_from_packed(level_select_scene)
	
func load_level_from_packed(scene: PackedScene) -> void:
	loading_new_scene.emit()
	current_level = scene
	get_tree().change_scene_to_packed(scene)
	# Takes two frames for this to actually happen
	await get_tree().process_frame
	await get_tree().process_frame
	loaded_new_scene.emit()
	time_since_unpause = 0
	time_since_level_loaded = 0

func setup_new_save() -> void:
	print("Resetting Save")
	current_save = load("res://Levels/Game Saves/Starting_Save.tres").duplicate()
	save_game()

func save_game() -> void:
	ResourceSaver.save(current_save, SAVE_PATH)

func complete_all_levels() -> void:
	for level: PackedScene in levels:
		current_save.complete_level(level,0)
	save_game()


var endless_run_height: int = 0:
	set(new_val):
		endless_run_height = new_val
		current_save.endless_high_height = max(new_val, current_save.endless_high_height)
var endless_run_idols: int = 0:
	set(new_val):
		endless_run_idols = new_val
		current_save.endless_high_idols = max(new_val, current_save.endless_high_idols)

func player_die() -> void:
	if get_tree().current_scene.name == "Endless Level":
		save_game()
		load_level_from_packed(leaderboard_scene)
	else:
		restart_level()
