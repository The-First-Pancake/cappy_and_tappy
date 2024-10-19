@tool
class_name Placeable
extends CharacterBody2D

enum PlaceState {QUEUED, PLACING, FALLING, HARPOONED, PLACED, DESTROYED}
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var state : PlaceState = PlaceState.PLACED
@export var pathnode_prefab : PackedScene
@export var indestructable: bool = false:
	set(new_val):
		indestructable = new_val
		if new_val == true:
			sprite_2d.modulate = Color(.1,.1,.1)
		else:
			sprite_2d.modulate = Color.WHITE
@export var sand_cluster: bool = false
@export var minecraft_sand_behavior: bool = false

var hold_point_generator : HoldPointGenerator


signal picked_up
signal placed
signal falling
signal destroyed

const DEFAULT_COLLISION_LAYER : int = 1
const PLAYER_COLLISION_LAYER : int = 2
const UNPLACED_COLLISION_LAYER : int = 7

@onready var impact_sound : AudioStreamPlayer = $BlockImpact01 as AudioStreamPlayer
@onready var shatter_sound : AudioStreamPlayer = $Explosion3003 as AudioStreamPlayer

var destroy_semaphore : Semaphore = Semaphore.new()
var targeted_by_harpoon: bool = false
var harpooned_accel: float = 3500
var harpooned_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if (state == PlaceState.FALLING):
		enter_falling()
	hold_point_generator = $HoldPointGenerator
	spawn_pathfinding_nodes()
	destroy_semaphore.post()

var rotate_debounce: bool = false
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): #editor tools
		if self in EditorInterface.get_selection().get_selected_nodes():
			if Input.is_key_pressed(KEY_V):
				if rotate_debounce == false:
					rotate_debounce = true
					rotate(PI/2)
			else:
				rotate_debounce = false
		return
	
	if (state == PlaceState.PLACING):
		var grid_size: float = GameManager.GRID_SIZE
		var mouse_pos : Vector2 = get_global_mouse_position()
		global_position = round(mouse_pos / grid_size) * grid_size
		if (Input.is_action_just_pressed("rotate_block_right")):
			rotation += deg_to_rad(90)
			return
		if (Input.is_action_just_pressed("rotate_block_left")):
			rotation -= deg_to_rad(90)
			return
		if (!check_for_collisions() and Input.is_action_just_released("drop_block")):
			await get_tree().physics_frame
			if GameManager.currently_held_object == self:
					GameManager.currently_held_object = null
			enter_falling()
	elif (state == PlaceState.FALLING):
		# Add the gravity.
		velocity += get_gravity() * delta
		var collision : KinematicCollision2D = move_and_collide(velocity * delta)
		if (collision):
			if (collision.get_angle(up_direction) < deg_to_rad(45) and collision.get_angle(up_direction) > deg_to_rad(-45)):
				enter_placed()
	elif state == PlaceState.HARPOONED:
		velocity += harpooned_accel * harpooned_dir * delta
		var collision : KinematicCollision2D = move_and_collide(velocity * delta)
		if (collision):
			if (collision.get_collider() is Player):
				collision.get_collider().velocity = velocity #TODO this kind of prevents the player from sliding/jumping
			elif (collision.get_angle(-harpooned_dir) < deg_to_rad(45) and collision.get_angle(-harpooned_dir) > deg_to_rad(-45)):
				enter_placed()
	elif (state == PlaceState.QUEUED):
		if Input.is_action_just_released("drop_block"): #Pick Up
			if GameManager.currently_held_object == null:
				enter_placing()
	elif (state == PlaceState.PLACED):
		if is_instance_valid(GameManager.currently_held_object) and GameManager.currently_held_object is Dynamite and mouse_hovering and !indestructable:
			modulate = Color.RED
		else:
			modulate = Color.WHITE
		if minecraft_sand_behavior:
			var collision: KinematicCollision2D = move_and_collide(Vector2.DOWN * 20, true)
			if !collision:
				enter_falling()

func align_to_grid() -> void:
	var grid_size: float = GameManager.GRID_SIZE
	global_position = round(global_position / grid_size) * grid_size #Snap to the nearest grid space

func get_closest_cell_center(to_point: Vector2) -> Vector2:
	var center_points: PackedVector2Array = hold_point_generator.generated_cell_center_points
	var closest_point: Vector2 = Vector2(100000,100000)
	for cell_center: Vector2 in center_points:
		if to_global(cell_center).distance_to(to_point) < closest_point.distance_to(to_point):
			closest_point = to_global(cell_center)
	return closest_point
func enter_harpooned(dir: Vector2) -> void:
	align_to_grid()
	velocity = Vector2.ZERO
	harpooned_dir = dir
	state = PlaceState.HARPOONED

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
	set_collision_mask_value(PLAYER_COLLISION_LAYER,true)
	GameManager.currently_held_object = self
	await get_tree().process_frame
	picked_up.emit()
	modulate.a = 0.5 # make transparent
	state = PlaceState.PLACING 

func enter_falling() -> void:
	set_collision_mask_value(PLAYER_COLLISION_LAYER,false)
	
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
	falling.emit()

func enter_placed() -> void:
	align_to_grid()
	if sand_cluster:
		const SAND_CELL = preload("res://Prefabs/Blocks/Sand Cell.tscn")
		for point: Vector2 in hold_point_generator.generated_cell_center_points:
			var new_sand: Placeable = SAND_CELL.instantiate()
			get_parent().add_child(new_sand)
			new_sand.global_position =   point.rotated(global_rotation) + global_position
			new_sand.enter_falling()
		queue_free()
		return
	velocity = Vector2.ZERO
	state = PlaceState.PLACED
	CameraController.instance.apply_shake()
	AudioManager.PlayAudio(impact_sound)
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

func destroy(collision_point_global : Vector2, nbr_of_shards : int = 10, min_impulse : float = 50, max_impulse: float = 200) -> void:
	if indestructable: return
	if destroy_semaphore.try_wait():
		if (state != PlaceState.DESTROYED):
			state = PlaceState.DESTROYED
			destroyed.emit()
			AudioManager.PlayAudio(shatter_sound)
			for child in get_children():
				if child is Sprite2D:
					continue
				if child is CollisionPolygon2D:
					continue
				if child is PathNode:
					child.destroy()
				else: 
					child.queue_free()
			enter_placed()
			$Sprite2D/ShardEmitter.nbr_of_shards = nbr_of_shards
			$Sprite2D/ShardEmitter.min_impulse = min_impulse
			$Sprite2D/ShardEmitter.max_impulse = max_impulse
			$Sprite2D/ShardEmitter.shatter(collision_point_global)

var mouse_hovering: bool = false

func _on_mouse_entered() -> void:
	mouse_hovering = true

func _on_mouse_exited() -> void:
	mouse_hovering = false

func spawn_pathfinding_nodes() -> void:
	for spawn_point_idx in len(hold_point_generator.get_generated_points()):
		var pathnode : Node2D = pathnode_prefab.instantiate()
		add_child(pathnode)
		pathnode.position = hold_point_generator.generated_points[spawn_point_idx]
		var orth_vector : Vector2 = hold_point_generator.generated_orth_vectors[spawn_point_idx]
		pathnode.rotate(Vector2.UP.angle_to(orth_vector))
