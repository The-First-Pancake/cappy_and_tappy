class_name Enemy
extends CharacterBody2D


var jump_velocity: float = -850.0
var acceleration: float = 3000
var deceleration: float = 4000
var max_speed: float = 300

var leap_velocity: float = 1350.0

var downslide_speed: float = 300
var current_hold: Node2D = null

var coyote_time: float = 0.1

var terminal_velocity: float = 1500
var idols_collected: int = 0

var was_on_floor: bool = true

var campfires: Array[Campfire] = []

@onready var side_hand_point: Marker2D = %"Side Hand Point" as Marker2D
@onready var top_hand_point: Marker2D = %"Top Hand Point" as Marker2D

@onready var slide_particles: CPUParticles2D = $"Slide Particles" as CPUParticles2D
@onready var jump_particles: CPUParticles2D = $"Jump Particles" as CPUParticles2D
@onready var land_particles: CPUParticles2D = $"Land Particles" as CPUParticles2D
@onready var hold_release_particles: CPUParticles2D = $"Hold Release Particles" as CPUParticles2D

@onready var jump_sound: AudioStreamPlayer = $Audio/Jump012 as AudioStreamPlayer
@onready var land_sound: AudioStreamPlayer = $Audio/Punch1021 as AudioStreamPlayer
@onready var slide_sound: AudioStreamPlayer = $Audio/Sliding01 as AudioStreamPlayer
@onready var die_sound: AudioStreamPlayer = $Audio/Ouch006 as AudioStreamPlayer
@onready var grab_sound: AudioStreamPlayer = $Audio/Footstep1012 as AudioStreamPlayer
@onready var idol_get_sound: AudioStreamPlayer = $Audio/IdolGet as AudioStreamPlayer
@onready var griddy_sound: AudioStreamPlayer = $Audio/Griddy as AudioStreamPlayer

@onready var gravity_reduce_timer: Timer = %"Gravity Reduce Timer" as Timer
@onready var launch_timer: Timer = $"Launch Timer"
@onready var targeting_arrow: Sprite2D = $"Targeting Arrow"

var is_downsliding: bool = false

var path_to_player : Array[PathNode] = []
var last_path_update : int = Time.get_ticks_msec()
var diff_vector : Vector2 = Vector2.ZERO
var horz_move_dir : float = 0
var should_jump : bool = false
var should_grab_hold : bool =  false
var hold_aim_dir : Vector2 = Vector2.ZERO
var should_launch : bool = false
var is_launched : bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	queue_redraw()
	targeting_arrow.visible = false
	if dying: return
	is_downsliding = is_on_wall() and velocity.y > 0
	
	if !is_instance_valid(current_hold):
		movement(delta)
	if is_instance_valid(current_hold):
		holding_behavior()
	
	update_animations()
	move_and_slide()

func _draw() -> void:
	for i in path_to_player.size() - 1:
		if is_instance_valid(path_to_player[i]) and is_instance_valid(path_to_player[i + 1]):
			z_index = 1001
			draw_line(path_to_player[i].node_position, path_to_player[i+1].node_position, Color.RED)

func is_next_path_node_reached() -> bool:
	if path_to_player.is_empty():
		return false
	# Make sure we can operate on the path
	if not is_instance_valid(path_to_player[0]):
		return false
	return (path_to_player[0].node_position - global_position).length() < 50 and not path_to_player[0].is_hold

func is_next_path_node_held() -> bool:
	if path_to_player.is_empty():
		return false
	# Make sure we can operate on the path
	if not is_instance_valid(path_to_player[0]):
		return false
	return (path_to_player[0].is_hold and is_instance_valid(current_hold) and (current_hold as PathNode).point_id == path_to_player[0].point_id)

func emulate_inputs() -> void:
	# Is there no valid path to player
	if path_to_player.is_empty():
		horz_move_dir = 0
		should_jump = false
		should_grab_hold = false
		is_launched = false
		hold_aim_dir = Vector2.ZERO
		return
	# First check if we've reached our target
	while is_next_path_node_reached() or is_next_path_node_held():
		is_launched = false
		path_to_player.pop_front()
		last_path_update = Time.get_ticks_msec()
	# Check again if we've emptied. this time it means we've reached destination
	if path_to_player.is_empty():
		horz_move_dir = 0
		should_jump = false
		should_grab_hold = false
		is_launched = false
		hold_aim_dir = Vector2.ZERO
		return
	# Make sure we can operate on the path
	if not is_instance_valid(path_to_player[0]):
		return
	
	# Calculate simulated inputs
	diff_vector = path_to_player[0].node_position - global_position
	if is_launched and diff_vector.y <= 0 and diff_vector.x < 200:
		horz_move_dir = 0
	else:
		horz_move_dir = diff_vector.normalized().x
	should_jump = abs(diff_vector.y) > 50 and not is_launched
	if (abs(diff_vector.y) < 200):
		hold_aim_dir = (Vector2.UP + diff_vector.normalized()).normalized()
	else:
		hold_aim_dir = Vector2.UP
	should_grab_hold = path_to_player[0].is_hold and diff_vector.length() < 100

func movement(delta: float) -> void:
	# Add the gravity.
	apply_gravity(delta)
	# Emulate player inputs
	emulate_inputs()
	#grab holds
	if should_grab_hold:
		var mid_air_hold_detector: Area2D = %"Mid-Air Hold Detector" as Area2D
		var grounded_hold_detector_2: Area2D = %"Grounded Hold Detector2" as Area2D
		
		var holds: Array[Area2D] = []
		if is_on_floor():
			holds = grounded_hold_detector_2.get_overlapping_areas()
		else:
			holds = mid_air_hold_detector.get_overlapping_areas()
		
		#Grab the closest hold
		var closest_hold: Node2D = null
		for hold in holds:
			if !hold.is_in_group("hold"): continue
			if abs(hold.global_rotation_degrees) < 1: continue #if the hold is upright we can't grab it
			if closest_hold == null:
				closest_hold = hold
				continue
			if side_hand_point.global_position.distance_to(hold.global_position) < side_hand_point.global_position.distance_to(closest_hold.global_position):
				closest_hold = hold
		if closest_hold:
			launch_timer.start()
			velocity = Vector2.ZERO
			current_hold = closest_hold
			AudioManager.PlayAudio(grab_sound, false)
			return
	
	# Handle jump.
	var coyote_timer: Timer = %"Coyote Timer" as Timer
	if was_on_floor and not is_on_floor():
		coyote_timer.wait_time = coyote_time
		coyote_timer.start()
	
	var has_recently_left_ground: bool = coyote_timer.time_left != 0
	
	if !was_on_floor and is_on_floor():
		land_particles.restart()
		AudioManager.PlayAudio(land_sound, false)
	
	if (is_on_floor() or has_recently_left_ground) and should_jump and not should_launch and not is_instance_valid(current_hold):
		jump_particles.restart()
		AudioManager.PlayAudio(jump_sound, false)
		was_on_floor = false
		velocity.y = jump_velocity
	else:
		was_on_floor = is_on_floor()
	
	# Get the input direction and handle the movement/deceleration.
	if horz_move_dir: #if we're tryna move
		if sign(horz_move_dir) != sign(velocity.x):
			velocity.x = 0 # for instant turning around
		if abs(velocity.x) < max_speed:
			velocity.x += horz_move_dir * acceleration * delta
	else: #if we aint tryna move
		velocity.x = move_toward(velocity.x, 0, deceleration * delta) #slow down
	
	#flipping. Used answer from here: https://forum.godotengine.org/t/why-my-character-scale-keep-changing/13909/5
	if horz_move_dir > 0:
		transform.x.x = 1
	elif horz_move_dir < 0:
		transform.x.x = -1 

func holding_behavior() -> void:
	emulate_inputs()
	var holding_cieling: bool = abs(angle_difference(current_hold.global_rotation, deg_to_rad(180))) < deg_to_rad(1)
	if holding_cieling:
		global_position = current_hold.global_position - (top_hand_point.global_position - global_position)
		if hold_aim_dir.x > 0:
			transform.x.x = 1
		elif hold_aim_dir.x < 0:
			transform.x.x = -1 
	else:
		global_position = current_hold.global_position - (side_hand_point.global_position - global_position)
		if abs(angle_difference(current_hold.global_rotation, deg_to_rad(90))) < deg_to_rad(1):
			transform.x.x = -1
		elif abs(angle_difference(current_hold.global_rotation, deg_to_rad(270))) < deg_to_rad(1):
			transform.x.x = 1
	
	if should_launch:
		should_launch = false
		is_launched = true
		hold_release_particles.restart()
		AudioManager.PlayAudio(jump_sound, false)
		if abs(hold_aim_dir.y) == 0:
			velocity = leap_velocity * hold_aim_dir
			gravity_reduce_timer.wait_time = 0.15
			gravity_reduce_timer.start()
		else:
			velocity = leap_velocity * hold_aim_dir
		current_hold = null

@onready var kill_box: Area2D = $KillBox
@onready var die_box: Area2D = %DieBox
@onready var sprite_animator: AnimatedSprite2D = %"Sprite Animator" as AnimatedSprite2D
@onready var griddy_timer: Timer = %"Griddy Timer" as Timer
@onready var footstep_animator: AnimationPlayer = $"Sprite Animator/AnimationPlayer" as AnimationPlayer

var slide_sound_playing : AudioStreamPlayer = null
var griddy_sound_playing : bool = false
var main_music_playing : bool = false

func update_animations() -> void:
	if sprite_animator.animation != "idle" and sprite_animator.animation != "dance":
		griddy_timer.start()
	
	slide_particles.emitting = false
	
	if is_instance_valid(current_hold):
		footstep_animator.stop()
		if is_instance_valid(slide_sound_playing):
			slide_sound_playing.queue_free()
		griddy_sound_playing = false
		var holding_cieling: bool = abs(angle_difference(current_hold.global_rotation, deg_to_rad(180))) < deg_to_rad(1)
		if holding_cieling:
			sprite_animator.play("hang_top")
		else:
			sprite_animator.play("hang_side")
	elif is_on_floor():
		if is_instance_valid(slide_sound_playing):
			slide_sound_playing.queue_free()
		if abs(velocity.x) > 10:
			if AudioManager.current_music.stream_paused == true:
				AudioManager.current_music.stream_paused = false
				griddy_sound.stop()
			sprite_animator.play("walk")
			footstep_animator.play("footsteps")
		else:
			if griddy_timer.time_left == 0:
				sprite_animator.play("dance")
				footstep_animator.play("footsteps")
				if griddy_sound.playing == false:
					AudioManager.current_music.stream_paused = true
					griddy_sound.play()
			else:
				sprite_animator.play("idle")
				if AudioManager.current_music.stream_paused == true:
					AudioManager.current_music.stream_paused = false
					griddy_sound.stop()
				footstep_animator.stop()
	elif is_downsliding:
		if not is_instance_valid(slide_sound_playing):
			slide_sound_playing = AudioManager.PlayAudio(slide_sound, false)
		footstep_animator.stop()
		sprite_animator.play("downslide")
		slide_particles.emitting = true
	else:
		if (is_instance_valid(slide_sound_playing)):
			slide_sound_playing.queue_free()
		footstep_animator.stop()
		if AudioManager.current_music.stream_paused == true:
			AudioManager.current_music.stream_paused = false
			griddy_sound.stop()
		if abs(velocity.x) > 750:
			sprite_animator.play("jump_reach")
		else:
			if abs(velocity.y) < 200:
				sprite_animator.play("jump_hang")
			elif velocity.y > 0:
				sprite_animator.play("jump_decend")
			else:
				sprite_animator.play("jump_up")

func try_squash() -> void:
	if is_on_floor():
		die()

var dying: bool = false
func die() -> void:
	if dying:return
	dying = true
	die_box.process_mode = Node.PROCESS_MODE_DISABLED
	kill_box.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_hold = null
	sprite_animator.play("die")
	if (is_instance_valid(slide_sound_playing)):
			slide_sound_playing.queue_free()
	footstep_animator.stop()
	AudioManager.PlayAudio(die_sound, false)
	
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position:y", global_position.y - 80, 0.3)
	await tween.finished
	
	tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position:y", global_position.y + 600, 0.5)
	await tween.finished
	queue_free()

func apply_gravity(delta: float) -> void:
	if is_on_floor(): return
	if velocity.y > terminal_velocity: return
	
	var gravity_reduced: bool = gravity_reduce_timer.time_left > 0
	if is_downsliding:
		velocity += get_gravity()*0.5 * delta
		velocity.y = min(velocity.y, downslide_speed)
	elif gravity_reduced:
		velocity += get_gravity()*0.5 * delta
		velocity.y = min(velocity.y, downslide_speed)
	else:
		velocity += get_gravity()*3 * delta

func on_diebox_hit(area: Area2D) -> void:
	if area.is_in_group("water"):
		die()

func _on_pathfinding_timer_timeout() -> void:
	# only do this if not mid launch
	if is_on_floor() or is_instance_valid(current_hold) or (Time.get_ticks_msec() - last_path_update > 1000):
		last_path_update = Time.get_ticks_msec()
		path_to_player = PathFindingGraph.find_path(global_position, GameManager.player.global_position)

func _on_launch_timer_timeout() -> void:
	should_launch = true

func _on_kill_box_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
