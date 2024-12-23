class_name Player
extends CharacterBody2D


var jump_velocity: float = -850.0
var acceleration: float = 3000
var deceleration: float = 4000
var max_speed: float = 700

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
@onready var gravity_reduce_timer: Timer = %"Gravity Reduce Timer" as Timer
@onready var targeting_arrow: Sprite2D = $"Targeting Arrow"

#Particles
@onready var slide_particles: CPUParticles2D = $"Slide Particles" as CPUParticles2D
@onready var jump_particles: CPUParticles2D = $"Jump Particles" as CPUParticles2D
@onready var jump_trail_particles: CPUParticles2D = $"Jump Trail Particles" as CPUParticles2D
@onready var land_particles: CPUParticles2D = $"Land Particles" as CPUParticles2D
@onready var hold_release_particles: CPUParticles2D = $"Hold Release Particles" as CPUParticles2D

#Sounds
@onready var jump_sound: AudioStreamPlayer = $Audio/Jump012 as AudioStreamPlayer
@onready var land_sound: AudioStreamPlayer = $Audio/Punch1021 as AudioStreamPlayer
@onready var slide_sound: AudioStreamPlayer = $Audio/Sliding01 as AudioStreamPlayer
@onready var die_sound: AudioStreamPlayer = $Audio/Ouch006 as AudioStreamPlayer
@onready var grab_sound: AudioStreamPlayer = $Audio/Footstep1012 as AudioStreamPlayer
@onready var idol_get_sound: AudioStreamPlayer = $Audio/IdolGet as AudioStreamPlayer
@onready var griddy_sound: AudioStreamPlayer = $Audio/Griddy as AudioStreamPlayer
@onready var respawn_sound: AudioStreamPlayer = $Audio/Respawn as AudioStreamPlayer

var is_entering: bool = false
var is_exiting: bool = false
var is_downsliding: bool = false

var normal_z_layer: int = 0
var inside_door_z_layer: int = -1

var input_direction: Vector2 = Vector2.ZERO

signal crossed_entrance_threshold

func _ready() -> void:
	GameManager.player = self
	enter_level()

func enter_level() -> void:
	z_index = inside_door_z_layer
	is_entering = true
	await get_tree().create_timer(0.2).timeout
	velocity.x = max_speed
	
	get_tree().create_timer(1).timeout.connect(crossed_entrance_threshold.emit) #if 1 second passes, act like we hit to doorway, just in case door is fucked
	
	await crossed_entrance_threshold
	z_index = normal_z_layer
	await get_tree().create_timer(0.2).timeout
	is_entering = false

func exit_level() -> void:
	z_index = inside_door_z_layer
	var dir: int = 1
	if velocity.x < 0:
		dir = -1
	is_exiting = true
	velocity.x = 600 * dir
	await get_tree().create_timer(0.15).timeout
	visible = false
	await get_tree().create_timer(1).timeout
	GameManager.level_complete()
	is_exiting = false

func _physics_process(delta: float) -> void:
	targeting_arrow.visible = false
	
	if dying: return
	
	update_camera_zone()
	
	if is_entering or is_exiting:
		apply_gravity(delta)
		update_animations()
		move_and_slide()
		return
	
	input_direction = Input.get_vector("move_left", "move_right","move_up","move_down")

	is_downsliding = is_on_wall() and velocity.y > 0
	if !is_instance_valid(current_hold):
		movement(delta)
	if is_instance_valid(current_hold):
		holding_behavior()
	
	update_animations()
	move_and_slide()
	try_look_ahead()
	try_squash()	

var current_camera_zone: CameraZone = null

func update_camera_zone() -> void:
	for area: Area2D in collect_box.get_overlapping_areas():
		if area is CameraZone:
			current_camera_zone = area
			return
	current_camera_zone = null

func movement(delta: float) -> void:
	# Add the gravity.
	apply_gravity(delta)
	
	#grab holds
	if Input.is_action_just_pressed("grab_hold") or (Input.is_action_pressed("grab_hold") and velocity.y > 0):
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
			velocity = Vector2.ZERO
			current_hold = closest_hold
			AudioManager.PlayAudio(grab_sound)
			return
	
	# Handle jump.
	var coyote_timer: Timer = %"Coyote Timer" as Timer
	if was_on_floor and not is_on_floor():
		coyote_timer.wait_time = coyote_time
		coyote_timer.start()
	
	var has_recently_left_ground: bool = coyote_timer.time_left != 0
	
	if !was_on_floor and is_on_floor():
		land_particles.emitting = true
		AudioManager.PlayAudio(land_sound)
	
	#Jumping!
	if (is_on_floor() or has_recently_left_ground) and Input.is_action_just_pressed("jump") and !Input.is_key_pressed(KEY_SHIFT):
		jump_particles.restart()
		AudioManager.PlayAudio(jump_sound)
		was_on_floor = false
		velocity.y = jump_velocity
		jump_trail_particles.emitting = true
		await get_tree().create_timer(0.1).timeout
		jump_trail_particles.emitting = false
	else:
		was_on_floor = is_on_floor()
	
	if input_direction.x != 0 and !Input.is_key_pressed(KEY_SHIFT): #if we're tryna move left/right
		if sign(input_direction.x) != sign(velocity.x):
			velocity.x = 0 # for instant turning around
		if abs(velocity.x) < max_speed:
			velocity.x += input_direction.x * acceleration * delta
	else: #if we aint tryna move
		velocity.x = move_toward(velocity.x, 0, deceleration * delta) #slow down
	
	#flipping. Used answer from here: https://forum.godotengine.org/t/why-my-character-scale-keep-changing/13909/5
	if input_direction.x > 0:
		transform.x.x = 1
	elif input_direction.x < 0:
		transform.x.x = -1


@onready var look_up_timer: Timer = %"Look Up Timer"
var look_ahead_hold_time: float = 0.5
var is_holding_down_look_ahead_input: bool = false
var look_ahead_dir: Vector2 = Vector2.ZERO

func try_look_ahead() -> void:
	var can_look_ahead: bool = velocity.x == 0 and is_on_floor() and !is_downsliding
	
	var d_pad_input: Vector2 = Input.get_vector("controller_peek_left","controller_peek_right","controller_peek_up","controller_peek_down")
	
	look_ahead_dir = Vector2.ZERO
	if can_look_ahead:
		if Input.is_key_pressed(KEY_SHIFT):
			look_ahead_dir = input_direction
		elif d_pad_input != Vector2.ZERO:
			look_ahead_dir = d_pad_input
	
	#var is_trying_to_look_up: bool = input_direction.y == -1
	#var is_trying_to_look_down: bool = input_direction.y == 1
	#
	#if can_look_ahead and (is_trying_to_look_up or is_trying_to_look_down):
		#if !is_holding_down_look_ahead_input:
			#look_up_timer.start() #make sure timer is goingd
			#is_holding_down_look_ahead_input = true
		#elif look_up_timer.time_left == 0:
			#if is_trying_to_look_up:
				#look_ahead_dir = Vector2.UP
			#else:
				#look_ahead_dir = Vector2.DOWN
	#else:
		#look_up_timer.stop()
		#look_up_timer.wait_time = look_ahead_hold_time
		#look_ahead_dir = Vector2.ZERO
		#is_holding_down_look_ahead_input = false

func holding_behavior() -> void:
	#targeting arrow
	if input_direction != Vector2.ZERO:
		targeting_arrow.visible = true
		if transform.x.x == 1:
			targeting_arrow.global_rotation = input_direction.angle() + PI/2
		else:
			targeting_arrow.global_rotation = input_direction.angle() - PI/2
	
	var holding_cieling: bool = abs(angle_difference(current_hold.global_rotation, deg_to_rad(180))) < deg_to_rad(20)
	if holding_cieling:
		#cieling gold
		if input_direction.x > 0: #flip player
			transform.x.x = 1
		elif input_direction.x < 0:
			transform.x.x = -1 
		global_position = current_hold.global_position - (top_hand_point.global_position - global_position)
	else:
		#side hold
		if abs(angle_difference(current_hold.global_rotation, deg_to_rad(90))) < deg_to_rad(20): #flip player
			transform.x.x = -1
		elif abs(angle_difference(current_hold.global_rotation, deg_to_rad(270))) < deg_to_rad(20):
			transform.x.x = 1
		global_position = current_hold.global_position - (side_hand_point.global_position - global_position)
	
	if Input.is_action_just_released("grab_hold"):
		hold_release_particles.restart()
		AudioManager.PlayAudio(jump_sound)
		if abs(input_direction.y) == 0:
			velocity = leap_velocity * input_direction
			gravity_reduce_timer.wait_time = 0.15
			gravity_reduce_timer.start()
		else:
			velocity = leap_velocity * input_direction
		current_hold = null

@onready var collect_box: Area2D = $CollectBox
@onready var die_box: Area2D = %DieBox
@onready var sprite_animator: AnimatedSprite2D = %"Sprite Animator" as AnimatedSprite2D
@onready var griddy_timer: Timer = %"Griddy Timer" as Timer
@onready var footstep_animator: AnimationPlayer = $"Sprite Animator/AnimationPlayer" as AnimationPlayer

var slide_sound_playing : AudioStreamPlayer = null
var main_music_playing : bool = false

func try_stop_griddy() -> void:
	griddy_sound.stop()
	#resume music
	if is_instance_valid(AudioManager.current_music):
		if AudioManager.current_music.stream_paused == true:
			AudioManager.current_music.stream_paused = false

func update_animations() -> void:
	if sprite_animator.animation != "idle" and sprite_animator.animation != "dance":
		griddy_timer.start()
	
	slide_particles.emitting = false
	
	if is_instance_valid(current_hold):
		try_stop_griddy()
		footstep_animator.stop()
		if is_instance_valid(slide_sound_playing):
			slide_sound_playing.queue_free()
		var holding_cieling: bool = abs(angle_difference(current_hold.global_rotation, deg_to_rad(180))) < deg_to_rad(1)
		if holding_cieling:
			sprite_animator.play("hang_top")
		else:
			sprite_animator.play("hang_side")
	elif is_downsliding:
		if not is_instance_valid(slide_sound_playing):
			slide_sound_playing = AudioManager.PlayAudio(slide_sound)
		footstep_animator.stop()
		sprite_animator.play("downslide")
		land_particles.emitting = false
		slide_particles.emitting = true
	elif is_on_floor():
		if is_instance_valid(slide_sound_playing):
			slide_sound_playing.queue_free()
		if abs(velocity.x) > 10:
			try_stop_griddy()
			sprite_animator.play("walk")
			footstep_animator.play("footsteps")
			land_particles.emitting = true
		else:
			if griddy_timer.time_left == 0:
				sprite_animator.play("dance")
				footstep_animator.play("footsteps")
				if griddy_sound.playing == false:
					AudioManager.current_music.stream_paused = true
					griddy_sound.play()
			else:
				sprite_animator.play("idle")
				land_particles.emitting = false
				try_stop_griddy()
				footstep_animator.stop()
	else:
		if (is_instance_valid(slide_sound_playing)):
			slide_sound_playing.queue_free()
		footstep_animator.stop()
		try_stop_griddy()
		if abs(velocity.x) > 750:
			sprite_animator.play("jump_reach")
			land_particles.emitting = false
		else:
			land_particles.emitting = false
			if abs(velocity.y) < 200:
				sprite_animator.play("jump_hang")
			elif velocity.y > 0:
				sprite_animator.play("jump_decend")
			else:
				sprite_animator.play("jump_up")

@onready var squash_detector: RayCast2D = %"Squash detector"

func try_squash() -> void:
	await get_tree().physics_frame
	#This method could cause problems if the player temporarily clips into something due to moving really fast, but I've yet to run into that problem
	if squash_detector.is_colliding():
		#if squash_detector.get_collision_normal() == Vector2.ZERO: #the ray is inside the object it's colliding with
		die()
	
	#This method is really smart and doesn't work lol
	#var collision_normals: Array[Vector2] = []
	#for i: int in get_slide_collision_count():
		#var collision: KinematicCollision2D = get_slide_collision(i)
		#for other_normal: Vector2 in collision_normals:
			#if other_normal.dot(collision.get_normal()) < -0.25: #if we're colliding with 2 opposite colliders
				#die()
		#collision_normals.append(collision.get_normal())


var dying: bool = false

func disable_hitboxes() -> void:
	die_box.process_mode = Node.PROCESS_MODE_DISABLED
	collect_box.process_mode = Node.PROCESS_MODE_DISABLED

func die() -> void:
	if is_exiting: return
	if dying:return
	dying = true
	call_deferred("disable_hitboxes")
	
	current_hold = null
	sprite_animator.play("die")
	if (is_instance_valid(slide_sound_playing)):
		slide_sound_playing.queue_free()
	footstep_animator.stop()
	AudioManager.PlayAudio(die_sound)
	
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position:y", global_position.y - 80, 0.3)
	await tween.finished
	
	tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position:y", global_position.y + 800, 0.5)
	await tween.finished
	await get_tree().process_frame

	var respawn_fire: Campfire = null
	for campfire: Campfire in campfires:
		if campfire == null: continue
		if campfire.is_lit == false: continue
		#this would make it so it's actually the highest. We cut this once we added horizontal levels
		#if campfire.global_position.y < respawn_fire.global_position.y:
		#	respawn_fire = campfire
			#continue
		respawn_fire = campfire
	
	
	
	if respawn_fire:
		#respawn
		AudioManager.PlayAudio(respawn_sound)
		global_position = respawn_fire.global_position + Vector2(0,-35) #offset to put play standing on the ground
		velocity = Vector2.ZERO
		collect_box.process_mode = Node.PROCESS_MODE_INHERIT
		die_box.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		GameManager.save_game()
		GameManager.player_die()
		return
	
	await get_tree().physics_frame
	await get_tree().physics_frame #waiting two frams lets the teleport fully resulve so that things like the camera zone have time to update
	dying = false

func apply_gravity(delta: float) -> void:
	if is_on_floor(): return
	var is_past_terminal_velocity: bool = velocity.y > terminal_velocity
	var gravity_reduced: bool = gravity_reduce_timer.time_left > 0
	if is_downsliding:
		velocity += get_gravity()*0.5 * delta
		velocity.y = min(velocity.y, downslide_speed)
	elif gravity_reduced:
		velocity += get_gravity()*0.5 * delta
		velocity.y = min(velocity.y, downslide_speed)
	elif is_past_terminal_velocity: #TODO this structure si kinda whack, but as long as downlide speed is less than terminal velocity it should be fine I think -  OP
		pass
	else:
		velocity += get_gravity()*3 * delta

func on_collectbox_hit(area: Area2D) -> void:
	if dying: return
	if area.is_in_group("idol"):
		area.queue_free()
		idols_collected += 1
		AudioManager.PlayAudio(idol_get_sound)
		return
	if area is Campfire:
		area.is_lit = true
		if !campfires.has(area): #skip if we already have it
			campfires.append(area)

func on_diebox_hit(area: Area2D) -> void:
	if area.is_in_group("spike"):
		die()
	if area.is_in_group("water"):
		die()

func _on_die_box_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if PhysicsServer2D.body_get_collision_layer(body_rid) & (1<<15):
		die()
