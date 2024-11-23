class_name ShardEmitter extends Node2D

## Number of break points.
@export_range(0, 200) var nbr_of_shards: int = 5

## Prevents slim triangles being created at the sprite edges.
@export var threshold: float = 10.0 

## Minimum impulse of the shards upon breaking.
@export var min_impulse: float = 1

## Maximum impulse of the shards upon breaking.
@export var max_impulse: float = 10

## How long the shards live.
@export var lifetime: float = 5.0

## Whether to display the triangles, for debug purposes.
@export var display_triangles: bool = false 

const SHARD : PackedScene = preload("res://Prefabs/Shard.tscn")

var triangles : Array[PackedVector2Array] = []
var shards : Array[Node2D] = []


func add_shards() -> void:
	for s in shards:
		get_parent().add_child(s)

func shatter(impact_point_global : Vector2, use_impact_point : bool = true) -> void:
	if get_parent() is Sprite2D:
		var _rect : Rect2 = get_parent().get_rect()
		var collisionpolygon2d : CollisionPolygon2D = $"../../CollisionPolygon2D"
		var points : PackedVector2Array = []
		#add outer frame points
		if (use_impact_point):
			points.append(to_local(impact_point_global))
		for point in collisionpolygon2d.get_polygon():
			points.append(to_local((point.rotated(collisionpolygon2d.global_rotation) + collisionpolygon2d.global_position)))
		collisionpolygon2d.queue_free()

		#add random break points
		for i in nbr_of_shards:
			var p : Vector2 = _rect.position + Vector2(randf_range(0, _rect.size.x), randf_range(0, _rect.size.y))
			#move outer points onto rectangle edges
			if p.x < _rect.position.x + threshold:
				p.x = _rect.position.x
			elif p.x > _rect.end.x - threshold:
				p.x = _rect.end.x
			if p.y < _rect.position.y + threshold:
				p.y = _rect.position.y
			elif p.y > _rect.end.y - threshold:
				p.y = _rect.end.y
			points.append(p)

		#calculate triangles
		var delaunay : PackedInt32Array = Geometry2D.triangulate_delaunay(points)
		for i in range(0, delaunay.size(), 3):
			var triangle : PackedVector2Array = [points[delaunay[i + 2]], points[delaunay[i + 1]], points[delaunay[i]]]
			triangles.append(triangle)
		#create RigidBody2D shards
		var texture : Texture2D = get_parent().texture
		for t in triangles:
			var center : Vector2 = Vector2((t[0].x + t[1].x + t[2].x)/3.0,(t[0].y + t[1].y + t[2].y)/3.0)
			if true:
				var shard : RigidBody2D = SHARD.instantiate()
				shard.position = center
				shard.hide()
				shards.append(shard)

				#setup polygons & collision shapes
				shard.get_node("Polygon2D").texture = texture
				shard.get_node("Polygon2D").polygon = t
				shard.get_node("Polygon2D").position = -center

				#shrink polygon so that the collision shapes don't overlapp
				var shrunk_triangles : Array[PackedVector2Array] = Geometry2D.offset_polygon(t, -2)
				if shrunk_triangles.size() > 0:
					shard.get_node("CollisionPolygon2D").polygon = shrunk_triangles[0]
				else:
					shard.get_node("CollisionPolygon2D").polygon = t
				shard.get_node("CollisionPolygon2D").position = -center

		queue_redraw()
		call_deferred("add_shards")

	await get_tree().process_frame 

	#spawn shards
	randomize()
	get_parent().self_modulate.a = 0
	for s : RigidBody2D in shards:
		var direction : Vector2
		if use_impact_point:
			direction = (s.position - to_local(impact_point_global)).normalized()
		else:
			direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()
		var impulse : float = randf_range(min_impulse, max_impulse)
		s.linear_velocity = Vector2.ZERO
		s.apply_central_impulse(direction * impulse)
		s.get_node("CollisionPolygon2D").disabled = false
		s.show()
		#s.process_mode = Node.PROCESS_MODE_INHERIT
	$DeleteTimer.start(lifetime)


func _on_DeleteTimer_timeout() -> void:
	get_parent().get_parent().queue_free()

func _draw() -> void:
	if display_triangles:
		for i in triangles:
			draw_line(i[0], i[1], Color.WHITE, 1)
			draw_line(i[1], i[2], Color.WHITE, 1)
			draw_line(i[2], i[0], Color.WHITE, 1)


func _on_squashable_squashed() -> void:
	# Shatter with default args
	shatter(Vector2.ZERO, false)
