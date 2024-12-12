class_name CameraController
extends Camera2D

static var instance: CameraController
@export_category("Stepping Movement")
var vert_screen_edge_trigger: float = 300
var horz_screen_edge_trigger: float = 350

var left_UI_size: float = 440
@export var stationary_cam: bool = false

var look_ahead_distance: float:
	get:
		return cam_size.x/2 - horz_screen_edge_trigger*0.9

@export_category("Screen Shake")
@export var random_stength: float = 15.0
@export var shake_fade: float = 5.0
var RNG : RandomNumberGenerator = RandomNumberGenerator.new()

var shake_strength : float = 0.0

enum CamType{
	VERTICAL,
	HORIZONTAL,
	FREECAM
}

var current_cam_type: CamType = CamType.FREECAM
var last_frame_cam_type: CamType = CamType.FREECAM


func _ready() -> void:
	instance = self

var is_sliding: bool = false

func apply_shake() -> void:
	shake_strength = random_stength
	
func random_offset() -> Vector2:
	return Vector2(RNG.randf_range(-shake_strength, shake_strength), RNG.randf_range(-shake_strength, shake_strength))

var left_edge_UI_width: float = 440

var cam_size: Vector2:
	get:
		return get_viewport_rect().size - Vector2(left_edge_UI_width,0)

var cam_pos: Vector2:
	get:
		return global_position + Vector2(left_edge_UI_width,0)/2
	set(new_val):
		global_position = new_val - Vector2(left_edge_UI_width,0)/2

#TODO these don't really work right for reverse levels. Cutting them for now
var last_camera_slide_dir: Vector2 = Vector2.ZERO
var momentum_bonus: float = 0 #modifies the target position of the camera in the direction of last camera slide
var momentum_trigger_modifier: float = 100 #modifies the trigger area in the direction of last camera slide

func _process(delta: float) -> void:
	var screen_left: float = cam_pos.x - cam_size.x/2
	var screen_right: float = cam_pos.x + cam_size.x/2
	var screen_top: float = cam_pos.y - cam_size.y/2
	var screen_bottom: float = cam_pos.y + cam_size.y/2
	
	if shake_strength < 1:
		shake_strength = 0 #Kill long tail
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shake_fade * delta)
		
	offset = random_offset()
	
	if !GameManager.player: return
	if GameManager.player.dying: return
	if stationary_cam: return
	if GameManager.time_since_level_loaded < 0.5: return #freeze frame for the beginning to help preview levels
	
	
	var cam_zone: CameraZone = GameManager.player.current_camera_zone
	var target_position: Vector2 = GameManager.player.global_position
	target_position += momentum_bonus * last_camera_slide_dir
	
	#Bias the target position based on the mouse
	#var max_mouse_bias: float = 500
	#var mouse_bias: Vector2 = get_global_mouse_position() - GameManager.player.global_position
	#var mouse_bias_mag: float = mouse_bias.length()
	#if mouse_bias_mag > max_mouse_bias:
		#mouse_bias = mouse_bias.normalized() * max_mouse_bias
	#target_position += mouse_bias / 2
	
	var look_ahead_offest: Vector2 = (GameManager.player.look_ahead_dir * look_ahead_distance)
	if look_ahead_offest!= Vector2.ZERO:
		target_position += look_ahead_offest
		is_sliding = true 
	
	if cam_zone:
		current_cam_type = cam_zone.type
		if current_cam_type == CamType.VERTICAL:
			target_position.x = cam_zone.mid_line
		if current_cam_type == CamType.HORIZONTAL:
			target_position.y = cam_zone.mid_line
	else:
		current_cam_type = CamType.FREECAM
	
	#if last_camera_slide_dir == Vector2.UP: top_trigger += momentum_trigger_modifier
	if target_position.y < screen_top + vert_screen_edge_trigger:
		if current_cam_type != CamType.HORIZONTAL:
			last_camera_slide_dir = Vector2.UP
			is_sliding = true
		
	if target_position.y > screen_bottom - vert_screen_edge_trigger:
		if current_cam_type != CamType.HORIZONTAL:
			last_camera_slide_dir = Vector2.DOWN
			is_sliding = true

	if target_position.x < screen_left + horz_screen_edge_trigger:
		if current_cam_type != CamType.VERTICAL:
			last_camera_slide_dir = Vector2.LEFT
			is_sliding = true
	
	if target_position.x > screen_right - horz_screen_edge_trigger:
		if current_cam_type != CamType.VERTICAL:
			last_camera_slide_dir = Vector2.RIGHT
			is_sliding = true
	
	if current_cam_type != last_frame_cam_type:
		is_sliding = true
	
	if cam_zone: #cap camera movements based on zone end points
		if cam_zone.bottom_out:
			if current_cam_type != CamType.HORIZONTAL:
				var min_camera_y: float = cam_zone.bot_right.y - cam_size.y/2
				if target_position.y > min_camera_y:
					target_position.y = min_camera_y
		if cam_zone.top_out:
			if current_cam_type != CamType.HORIZONTAL:
				var max_camera_y: float = cam_zone.top_left.y + cam_size.y/2
				if target_position.y < max_camera_y:
					target_position.y = max_camera_y
		if cam_zone.right_out:
			if current_cam_type != CamType.VERTICAL:
				var max_camera_x: float = cam_zone.bot_right.x - cam_size.x/2
				if target_position.x > max_camera_x:
					target_position.x = max_camera_x
		if cam_zone.left_out:
			if current_cam_type != CamType.VERTICAL:
				var min_camera_x: float = cam_zone.top_left.x + cam_size.x/2
				if target_position.x < min_camera_x:
					target_position.x = min_camera_x
	
	if cam_pos.distance_to(target_position) < 5:
			is_sliding = false
	
	if is_sliding:
		var pan_speed: float = 10
		var max_pan_speed: float = 2000
		var dead_zone: float = 0
		var distance_from_target: float = cam_pos.distance_to(target_position)
		distance_from_target = max(distance_from_target - dead_zone,0)
		var pan_speed_multiplier: float = clamp(pow(distance_from_target,1), 1, max_pan_speed/pan_speed)
		var destination: Vector2 = cam_pos.move_toward(target_position, pan_speed * delta * pan_speed_multiplier)
		#var move_diff: Vector2 =  cam_pos - destination  # Trying out having the mouse left behind during came moves. Doesn't really work or feel right
		#print(move_diff)
		#var mous_pos: Vector2 = get_viewport().get_mouse_position()
		#get_viewport().warp_mouse(mous_pos + move_diff)
		cam_pos = destination
	
	
	last_frame_cam_type = current_cam_type
