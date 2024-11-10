extends Node2D

var mouse_pos : Vector2 = Vector2()
var mouse_speed : float = 25

func _ready() -> void:
	mouse_pos = get_window().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass

func _process(_delta: float) -> void:
	var mouse_rel : Vector2 = Vector2.ZERO
	var move_dir : Vector2 = Input.get_vector("controller_mouse_left","controller_mouse_right",
											  "controller_mouse_up","controller_mouse_down")
	mouse_rel += move_dir * mouse_speed
	if mouse_rel != Vector2.ZERO:
		mouse_pos = get_viewport().get_mouse_position()
		get_viewport().warp_mouse(mouse_pos + mouse_rel)
	global_position = get_global_mouse_position()
	if (Input.is_action_just_pressed("controller_mouse_click")):
		fake_press()
	
	if is_instance_valid(GameManager.currently_held_object) and GameManager.currently_held_object is Placeable and GameManager.currently_held_object.check_for_collisions():
		modulate = Color.RED
	else:
		modulate = Color.WHITE

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
