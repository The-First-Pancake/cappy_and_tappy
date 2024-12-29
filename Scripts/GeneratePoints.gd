class_name HoldPointGenerator
extends Node

var units_per_block : int = 98
@export var generate_test_points : bool = false
var generated_points : PackedVector2Array = PackedVector2Array()
var generated_orth_vectors : PackedVector2Array = PackedVector2Array()
var generated_cell_center_points: PackedVector2Array = PackedVector2Array()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var collision_polygon : CollisionPolygon2D = $"../CollisionPolygon2D"
	var collision_points : PackedVector2Array = collision_polygon.polygon
	
	var generated : Array[PackedVector2Array] = generateHoldPoints(collision_points)
	generated_cell_center_points = get_cell_centers(collision_points)
	generated_points = generated[0]
	generated_orth_vectors = generated[1]
	if (generate_test_points):
		placeTestPoints(generated_points)
	
func get_generated_points() -> PackedVector2Array:
	return generated_points
	
func placeTestPoints(points: PackedVector2Array) -> void:
	for point in points:
		var test_point_prefab : PackedScene = preload("res://Prefabs/test_point.tscn") as PackedScene
		var test_point : Node2D = test_point_prefab.instantiate()
		var parent : Node2D = $".."
		parent.add_child.call_deferred(test_point)
		test_point.position = point
		#test_point.rotation = parent.rotation
	return

func get_cell_centers(points: PackedVector2Array) -> PackedVector2Array:
	var center_points: PackedVector2Array = []
	for i in points.size():
		var next_index : int = i+1
		if (next_index == points.size()):
			next_index = 0 #loop back to first index when on the last point in the array
		var point1 : Vector2 = points[i]
		var point2 : Vector2 = points[next_index]
		var orthvector : Vector2 = (point2 - point1).rotated(deg_to_rad(-90)).normalized()
		var distance: float = point1.distance_to(point2)
		var direction : Vector2 = point1.direction_to(point2)
		if (distance >= units_per_block):
			var working_point : Vector2 = point1 - ((units_per_block * direction) / 2)
			
			for j in range((distance/units_per_block)):
				var new_point : Vector2 = (units_per_block * direction) + working_point
				working_point = new_point
				var center_point: Vector2 = working_point - (orthvector * units_per_block/2)
				
				center_point = round(center_point/50)*50 #round to the nearest 50
				if !center_points.has(center_point):
					center_points.push_back(center_point)
	
	return center_points

func generateHoldPoints(points: PackedVector2Array) -> Array[PackedVector2Array]:
	var collider_inset_distance: float = 1 #how far the collider is inset from the block sprite. We outset the points by this ammount to compensate
	var created_points: PackedVector2Array
	var orth_points: PackedVector2Array
	for i in points.size():
		var next_index : int = i+1
		if (next_index == points.size()):
			next_index = 0 #loop back to first index when on the last point in the array
		var point1 : Vector2 = points[i]
		var point2 : Vector2 = points[next_index]
		var orthvector : Vector2 = (point2 - point1).rotated(deg_to_rad(-90)).normalized()
		var distance: float = point1.distance_to(point2)
		var direction : Vector2 = point1.direction_to(point2)
		#print("Collision Point: ", point1)
		if (distance >= units_per_block):
			var distance_vector : Vector2 = Vector2(units_per_block, units_per_block)
			var working_point : Vector2 = point1 - ((distance_vector * direction) / 2)
			
			for j in range((distance/units_per_block)):
				var new_point : Vector2 = (distance_vector * direction) + working_point
				working_point = new_point
				#print("Created point: ", new_point)
				created_points.push_back(new_point + (orthvector * collider_inset_distance))
				orth_points.push_back(orthvector)

	return [created_points, orth_points]
