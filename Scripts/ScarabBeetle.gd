class_name ScarabBeetle
extends CharacterBody2D

@onready var front_raycast: RayCast2D = $FrontRaycast
@onready var middle_raycast: RayCast2D = $"Middle Raycast"
@onready var rear_raycast: RayCast2D = $RearRaycast
@onready var player_kill_box: Area2D = $"Player Kill Box"

var move_speed: float = 75
var rotate_speed: float = 20
var fall_speed: float = 0
var falling_rotation_speed: float = 50

var active: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		if parent.state != Placeable.PlaceState.PLACED:
			active = false
			player_kill_box.process_mode = Node.PROCESS_MODE_DISABLED
			parent.placed.connect(activate_scarab)
			parent.destroyed.connect(activate_scarab)
		else:
			activate_scarab()
	pass # Replace with function body.

func activate_scarab() -> void:
	await get_tree().physics_frame
	if is_instance_valid(get_parent()):
		reparent(get_parent().get_parent())
		player_kill_box.process_mode = Node.PROCESS_MODE_INHERIT
		active = true

func try_squash() -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		return
	if front_raycast.is_colliding() and rear_raycast.is_colliding() and middle_raycast.is_colliding():
		if front_raycast.get_collision_normal() == Vector2.ZERO and rear_raycast.get_collision_normal() == Vector2.ZERO and middle_raycast.get_collision_normal() == Vector2.ZERO:
			die()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !active: return
	
	var falling: bool = !front_raycast.is_colliding() and !rear_raycast.is_colliding()
	if falling:
		var collision: KinematicCollision2D =  move_and_collide(Vector2.ZERO, true)
		if collision:
			fall_speed = 0
			rotate(rotate_speed * delta)
		else:
			fall_speed += 980 * delta
			global_position.y += fall_speed * delta
			#global_rotation += falling_rotation_speed*delta #spin while falling
	
	var correction_speed: float = 30
	if front_raycast.is_colliding() and rear_raycast.is_colliding():
		var front_pt: Vector2 = front_raycast.get_collision_point()
		var back_pt: Vector2 = rear_raycast.get_collision_point()
		global_position = (front_pt + back_pt)/2
		global_rotation = back_pt.direction_to(front_pt).angle()
		global_position += move_speed * delta * Vector2.RIGHT.rotated(rotation)  #move forward
	elif front_raycast.is_colliding():
		rotate(-rotate_speed * delta)
		global_position = global_position.move_toward(front_raycast.get_collision_point(), correction_speed*delta)
	elif rear_raycast.is_colliding():
		rotate(rotate_speed * delta)
		global_position = global_position.move_toward(rear_raycast.get_collision_point(), correction_speed*delta)
	
	try_squash()

@onready var brown_stain: Sprite2D = $"Brown Stain"

func die() -> void:
	if middle_raycast.get_collider() is Placeable:
		middle_raycast.get_collider().add_decal(brown_stain, global_position)
	queue_free()
