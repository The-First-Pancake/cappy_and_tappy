class_name Placeable_fucked
extends CharacterBody2D

enum PlaceState {QUEUED, PLACING, FALLING, PLACED}
@export var grid_size : float = 50
var state : int = PlaceState.QUEUED
var hold_point_generator : HoldPointGenerator

signal picked_up
signal placed

const DEFAULT_COLLISION_LAYER : int = 1
const UNPLACED_COLLISION_LAYER : int = 2

func _ready() -> void:
	hold_point_generator = $HoldPointGenerator
	enter_queued()

func _physics_process(delta: float) -> void:
	if (state == PlaceState.PLACING):
		var mouse_pos : Vector2 = get_global_mouse_position()
		global_position = Vector2(int(mouse_pos.x / grid_size) * grid_size, int(mouse_pos.y / grid_size) * grid_size)
		if (Input.is_action_just_pressed("rotate_block")):
			rotation += deg_to_rad(90)
			return
		if (!check_for_collisions() and Input.is_action_just_pressed("drop_block")):
			enter_falling()
	elif (state == PlaceState.FALLING):
		# Add the gravity.
		velocity += get_gravity() * delta
		var collision : KinematicCollision2D = move_and_collide(velocity * delta)
		if (collision):
			if (collision.get_collider() is Player):
				if (collision.get_angle(up_direction) < deg_to_rad(45) and collision.get_angle(up_direction) > deg_to_rad(-45)):
					var player : Player = collision.get_collider() as Player
					player.try_squash()
			elif (collision.get_angle(up_direction) < deg_to_rad(45) and collision.get_angle(up_direction) > deg_to_rad(-45)):
				enter_placed(collision)

func on_collision_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (state == PlaceState.QUEUED):
		if Input.is_action_just_pressed("drop_block"):
			enter_placing()

func enter_queued() -> void:
	state = PlaceState.QUEUED
	set_collision_layer_value(DEFAULT_COLLISION_LAYER, false);
	set_collision_layer_value(UNPLACED_COLLISION_LAYER, true);
	# Deal with child nodes
	for child in get_children():
		if (child is Area2D):
			var area_2d_child : Area2D = child as Area2D
			area_2d_child.set_collision_layer_value(DEFAULT_COLLISION_LAYER, false);
			area_2d_child.set_collision_layer_value(UNPLACED_COLLISION_LAYER, true);

func enter_placing() -> void:
	await get_tree().process_frame
	picked_up.emit()
	modulate.a = 0.5 # make transparent
	state = PlaceState.PLACING 

func enter_falling() -> void:
	set_collision_layer_value(DEFAULT_COLLISION_LAYER, true);
	set_collision_layer_value(UNPLACED_COLLISION_LAYER, false);
	# Deal with child nodes
	for child in get_children():
		if (child is Area2D):
			var area_2d_child : Area2D = child as Area2D
			area_2d_child.set_collision_layer_value(DEFAULT_COLLISION_LAYER, true);
			area_2d_child.set_collision_layer_value(UNPLACED_COLLISION_LAYER, false);
	modulate.a = 1 # make solid
	state = PlaceState.FALLING

func enter_placed(collision : KinematicCollision2D) -> void:
	state = PlaceState.PLACED
	
	CameraController.instance.apply_shake()
	
	#var points : PackedVector2Array = hold_point_generator.get_generated_points()
	#print("Collision Position: ", collision.get_position())
	#var particle_spawn_points : PackedVector2Array
	#for point in points:
		#var global_coord : Vector2 = to_global(point)
		#if abs(global_coord.y - collision.get_position().y) <= 2:
			#particle_spawn_points.push_back(global_coord)
	#
	#var impact_particles_prefab : PackedScene = preload("res://Prefabs/block_impact_particles.tscn") as PackedScene
	#
	#for point in particle_spawn_points:
		#var impact_particles : Node2D = impact_particles_prefab.instantiate()
		#add_child(impact_particles)
		#impact_particles.global_position = point
		#impact_particles.rotation = rotation
		#for child in impact_particles.get_children():
			#if child is GPUParticles2D:
				#child.emitting = true
	
	placed.emit()
	
func check_for_collisions() -> bool:
	var collision : KinematicCollision2D = move_and_collide(Vector2.ZERO, true, 0);
	if (collision):
		modulate.g = 0.5
		modulate.r = 2 # Redden unplaceable blocks
		modulate.b = 0.5
	else:
		modulate.g = 1
		modulate.r = 1
		modulate.b = 1
	return is_instance_valid(collision)
