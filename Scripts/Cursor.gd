extends Node2D

var two_controller_mode : bool = false
var pl1_act_to_remap : Array[String] = ["move_up",
										"move_down",
										"move_left",
										"move_right",
										"jump",
										"grab_hold",
										"controller_peek_left",
										"controller_peek_right",
										"controller_peek_up",
										"controller_peek_down"]

var pl2_act_to_remap : Array[String] = ["controller_mouse_left", 
										"controller_mouse_right", 
										"controller_mouse_up", 
										"controller_mouse_down",
										"controller_mouse_click",
										"rotate_block_left",
										"rotate_block_right"]
var mouse_pos : Vector2 = Vector2()
var mouse_speed : float = 25

@onready var point_light_2d: LightFlicker = $PointLight2D

func _ready() -> void:
	mouse_pos = get_window().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameManager.loaded_new_scene.connect(on_scene_load)
	pass

func on_scene_load() -> void:
	if is_instance_valid(GameManager.level_info):
		point_light_2d.visible = GameManager.level_info.dark
	else:
		point_light_2d.visible = false
	

func _process(_delta: float) -> void:

	check_for_controllers()
	var mouse_rel : Vector2 = Vector2.ZERO
	var move_dir : Vector2 = Input.get_vector("controller_mouse_left","controller_mouse_right",
											  "controller_mouse_up","controller_mouse_down")
	
	mouse_rel += move_dir * mouse_speed
	if mouse_rel != Vector2.ZERO:
		mouse_pos = get_viewport().get_mouse_position()
		#mouse_pos = global_position * get_viewport_transform()
		get_viewport().warp_mouse(mouse_pos + mouse_rel)
	
	global_position = get_global_mouse_position()
	if (Input.is_action_just_pressed("controller_mouse_click")):
		fake_press()
	
	if is_instance_valid(GameManager.currently_held_object) and GameManager.currently_held_object is Placeable and GameManager.currently_held_object.check_for_collisions():
		self_modulate = Color.RED
	else:
		self_modulate = Color.WHITE

func fake_press() -> void:
	var a : InputEventMouseButton = InputEventMouseButton.new()
	# This line is to transform to screen coordinates so mouse clicks work
	# If we ever update to a new version of godot and controller mouse control breaks
	# Check here lol
	a.position = get_viewport().get_screen_transform() * get_viewport().get_mouse_position()
	a.button_index = MOUSE_BUTTON_LEFT
	a.pressed = true
	Input.parse_input_event(a)
	await get_tree().process_frame
	a.pressed = false
	Input.parse_input_event(a)

func check_for_controllers() -> void:
	if (not two_controller_mode and Input.get_connected_joypads().size() > 1):
		two_controller_mode = true
		remap_controllers(two_controller_mode)
	elif (two_controller_mode and Input.get_connected_joypads().size() <= 1):
		two_controller_mode = false
		remap_controllers(two_controller_mode)

func remap_controllers(two_player: bool) -> void:
	var joypads : Array[int] = Input.get_connected_joypads()
	if two_player:
		for action in pl1_act_to_remap:
			var events : Array[InputEvent] = InputMap.action_get_events(action)
			for event in events:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					InputMap.action_erase_event(action, event)
					event.device = joypads[0]
					InputMap.action_add_event(action, event)
		for action in pl2_act_to_remap:
			var events : Array[InputEvent] = InputMap.action_get_events(action)
			for event in events:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					InputMap.action_erase_event(action, event)
					event.device = joypads[1]
					InputMap.action_add_event(action, event)
	else:
		for action in InputMap.get_actions():
			var events : Array[InputEvent] = InputMap.action_get_events(action)
			for event in events:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					InputMap.action_erase_event(action, event)
					event.device = joypads[0]
					InputMap.action_add_event(action, event)
