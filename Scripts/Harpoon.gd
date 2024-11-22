class_name Harpoon
extends Area2D

@onready var tripwire: RayCast2D = $Tripwire
var launched: bool = false
var has_harpoon_landed: bool = false
@onready var harpoon: Area2D = $Harpoon
@onready var harpoon_raycast: RayCast2D = $"Harpoon/Harpoon Raycast"

@onready var rope: Line2D = $Rope


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rope.visible = false
	rope.clear_points()

#TODO Decide what should bebehavior for destroyed harpoons. RN i think it causes errors
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		if parent.state != Placeable.PlaceState.PLACED:
			return
	if !launched:
		var tripping_obj: Object = tripwire.get_collider()
		if tripping_obj is Placeable:
			if tripping_obj.state == Placeable.PlaceState.FALLING:
				if tripping_obj.targeted_by_harpoon: return #if another harpoon already has plans
				tripping_obj.targeted_by_harpoon = true
				launched = true
				
				var direction: Vector2 = Vector2.from_angle( global_rotation - deg_to_rad(90))
				direction = direction.normalized()
				direction = direction.round()
				rope.visible = true
				var range: float = 1600
				var speed: float = 6000
				
				var hit_block: Node2D = null
				
				
				
				for i in range(range):
					harpoon_raycast.target_position.y = -speed * delta #The harpoon checks the ahead for the distance it's about to traverse
					if harpoon_raycast.get_collider() and harpoon_raycast.get_collider() != get_parent():
						hit_block = harpoon_raycast.get_collider()
						harpoon.global_position = harpoon_raycast.get_collision_point() - direction * 50
						break
					else:
						harpoon.global_position += delta*speed*direction
					
					await get_tree().process_frame
				
				
				has_harpoon_landed = true
				
				if hit_block and hit_block is Placeable:
					hit_block.enter_harpooned(-direction)
					var cell_hit_pos: Vector2 = hit_block.get_closest_cell_center(harpoon.global_position)
					var cell_local_pos: Vector2 = cell_hit_pos - hit_block.global_position
					if direction.y == 0:
						hit_block.global_position.y  = global_position.y - cell_local_pos.y
					else:
						hit_block.global_position.x  = global_position.x- cell_local_pos.x
					harpoon.global_position -= direction * 0 #Back up the harpoon
					harpoon.reparent(hit_block)
	else:
		if is_instance_valid(harpoon):
			if has_harpoon_landed:
				rope.points = [to_local(harpoon.global_position), Vector2.ZERO]
			else:
				rope.clear_points()
				var rope_resolution: float = 5 #pixels per point. Higher is fewer points
				var frequency: float = 0.015 #lower for further apart waves
				var amplitude: float = 12 #higher for bigger waves
				var distance: float = to_local(harpoon.global_position).distance_to(Vector2.ZERO)
				var direction: Vector2 = Vector2.ZERO.direction_to(to_local(harpoon.global_position))
				var perpendicular_dir: Vector2 = direction.rotated(PI/2)
				for x: float in rangef(0.0,distance,rope_resolution):
					var y: float = sin(x*PI*frequency) * amplitude
					
					rope.add_point(direction*(distance-x) + perpendicular_dir*y)
		else:
			rope.visible = false

signal harpoon_landed(block: Placeable)

func _on_harpoon_body_entered(body: Node2D) -> void:
	harpoon_landed.emit(body) 


func rangef(start: float, end: float, step: float) -> Array[float]:
	var res: Array[float] = []
	var i : float = start
	while i < end:
		res.push_back(i)
		i += step
	return res
