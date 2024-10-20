class_name CameraController
extends Camera2D

static var instance: CameraController
@export_category("Stepping Movement")
var screen_edge_trigger: float = 300
var left_screen_edge_trigger: float = 740
@export var stationary_cam: bool = false
var look_ahead_distance: float = 400

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

func _process(delta: float) -> void:
	var screen_left: float = global_position.x - get_viewport_rect().size.x/2
	var screen_right: float = global_position.x + get_viewport_rect().size.x/2
	var screen_top: float = global_position.y - get_viewport_rect().size.y/2
	var screen_bottom: float = global_position.y + get_viewport_rect().size.y/2
	
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shake_fade * delta)
		
	offset = random_offset()
	
	if !GameManager.player: return
	if GameManager.player.dying: return
	if stationary_cam: return
	
	
	var free_cam: bool = true
	var cam_zone: CameraZone = GameManager.player.current_camera_zone
	var target_position: Vector2 = GameManager.player.global_position
	
	
	if GameManager.player.looking_up: #look ahead
		target_position.y -= look_ahead_distance
	elif GameManager.player.looking_down:
		target_position.y += look_ahead_distance
		
	if cam_zone:
		current_cam_type = cam_zone.type
		if current_cam_type == CamType.VERTICAL:
			target_position.x = cam_zone.mid_line
		if current_cam_type == CamType.HORIZONTAL:
			target_position.y = cam_zone.mid_line
	else:
		current_cam_type = CamType.FREECAM
	
	if target_position.y < screen_top + screen_edge_trigger:
		if current_cam_type != CamType.HORIZONTAL:
			is_sliding = true
		
	if target_position.y > screen_bottom - screen_edge_trigger:
		if current_cam_type != CamType.HORIZONTAL:
			is_sliding = true

	if target_position.x < screen_left + left_screen_edge_trigger:
		if current_cam_type != CamType.VERTICAL:
			is_sliding = true
	
	if target_position.x > screen_right - screen_edge_trigger:
		if current_cam_type != CamType.VERTICAL:
			is_sliding = true
	
	if current_cam_type != last_frame_cam_type:
		is_sliding = true
	
	if cam_zone: #cap camera movements based on zone end points
		if cam_zone.bottom_out:
			if current_cam_type != CamType.HORIZONTAL:
				var min_camera_y: float = cam_zone.bot_right.y - get_viewport_rect().size.y/2
				if target_position.y > min_camera_y:
					target_position.y = min_camera_y
		if cam_zone.top_out:
			if current_cam_type != CamType.HORIZONTAL:
				var max_camera_y: float = cam_zone.top_left.y + get_viewport_rect().size.y/2
				if target_position.y < max_camera_y:
					target_position.y = max_camera_y
		if cam_zone.right_out:
			if current_cam_type != CamType.VERTICAL:
				var max_camera_x: float = cam_zone.bot_right.x - get_viewport_rect().size.x/2
				if target_position.x > max_camera_x:
					print(max_camera_x)
					print(target_position)
					
					target_position.x = max_camera_x
		if cam_zone.left_out:
			if current_cam_type != CamType.VERTICAL:
				var min_camera_x: float = cam_zone.top_left.x + get_viewport_rect().size.x/2
				if target_position.x < min_camera_x:
					target_position.x = min_camera_x
	
	if is_sliding:
		var distance_from_target: float = global_position.distance_to(target_position)
		var pan_speed: float = 180
		var pan_speed_multiplier: float = clamp(pow(distance_from_target, .5), 1, 10000000)
		global_position = global_position.move_toward(target_position, pan_speed * delta * pan_speed_multiplier)
		if global_position.distance_to(target_position) < 5:
			is_sliding = false
	
	
	last_frame_cam_type = current_cam_type
