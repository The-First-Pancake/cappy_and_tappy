extends Node2D

var show_debug : bool = true
var path_nodes : Array[PathNode] = []
@onready var astar_graph : AStar2D = AStar2D.new()
var cull_radius :  float = 1080
var horz_jump_dist : float = 200 # guess for now
var vert_jump_dist : float = 175 # guess for now
var horz_jump_hold_dist : float = 50 # guess for now
var vert_jump_hold_dist : float = 300 # guess for now
var horz_hold_dist : float = 600 # guess for now
var vert_hold_dist : float = 350 # guess for now
var path_semaphore : Semaphore = Semaphore.new()
var graph_recalc_semaphore : Semaphore = Semaphore.new()
var last_path : Array[PathNode] = []

signal graph_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path_semaphore.post()
	z_index = 1000
	GameManager.connect("loaded_new_scene", _gamemanager_new_scene_loaded)
	pass # Replace with function body.

func _draw() -> void:
	if show_debug:
		for path_node in path_nodes:
			for connection in astar_graph.get_point_connections(path_node.point_id):
				draw_line(path_node.node_position, astar_graph.get_point_position(connection), Color.GREEN)
		for idx in last_path.size()-1:
			if is_instance_valid(last_path[idx]) and is_instance_valid(last_path[idx+1]):
				draw_line(last_path[idx].node_position, last_path[idx + 1].node_position, Color.RED)

func find_path(start_global_position : Vector2, target_global_position : Vector2) -> Array[PathNode]:
	var start_node_id : int = astar_graph.get_closest_point(start_global_position)
	var end_node_id : int = astar_graph.get_closest_point(target_global_position)
	if not (start_node_id and end_node_id):
		return []
	var path : PackedInt64Array = astar_graph.get_id_path(start_node_id, end_node_id)
	if (path.is_empty()):
		return []
	var pathnode_path : Array[PathNode] = []
	for path_point in path:
		pathnode_path.append(find_node_with_id(path_point))
	last_path = pathnode_path.duplicate()
	queue_redraw()
	return pathnode_path
	
func find_node_with_id(id: int) -> PathNode:
	for path_node in path_nodes:
		if path_node.point_id == id:
			return path_node
	return null
	
func add_pathfinding_node(path_node : PathNode) -> void:
	path_semaphore.wait()
	path_node.point_id = astar_graph.get_available_point_id()
	astar_graph.add_point(path_node.point_id, path_node.node_position)
	path_nodes.append(path_node)
	recalculate_connections()
	path_semaphore.post()

func remove_pathfinding_node(path_node : PathNode) -> void:
	path_semaphore.wait()
	astar_graph.remove_point(path_node.point_id)
	for i in path_nodes.size():
		if (path_node.point_id == path_nodes[i].point_id):
			path_nodes.remove_at(i)
			break
	queue_redraw()
	path_semaphore.post()

func is_node_cullable(node : PathNode) -> bool:
	# Nodes loaded before player are not cullable
	if not is_instance_valid(GameManager.player):
		return false
	var diff_vector : Vector2 = node.node_position - GameManager.player.global_position
	return diff_vector.length() > cull_radius
	
func recalculate_connections() -> void:
	clear_astar_connections()
	for node in path_nodes:
		if is_node_cullable(node):
			continue
		add_axis_connection(node, Vector2.LEFT)
		add_axis_connection(node, Vector2.RIGHT)
		add_jump_connections(node)
		add_jump_hold_connections(node)
		add_hold_connections(node)
		add_falling_connections(node)
	emit_signal("graph_changed")
	queue_redraw()

func add_axis_connection(path_node : PathNode, direction : Vector2) -> void:
	if path_node.is_hold:
		return
	var closest_node : PathNode = null
	var closest_dist : float = INF
	for node_to in path_nodes:
		if is_node_self(node_to, path_node) or is_node_cullable(node_to):
			continue
		var diff_vector : Vector2 = node_to.node_position - path_node.node_position
		if abs(diff_vector.angle_to(direction)) < deg_to_rad(10):
			var dist : float = diff_vector.length()
			if dist < horz_jump_dist and dist < closest_dist:
				if not is_path_clear(node_to, path_node):
					continue
				closest_node = node_to
				closest_dist = dist
	if closest_node:
		astar_graph.connect_points(path_node.point_id, closest_node.point_id)

func add_jump_connections(path_node : PathNode) -> void:
	if path_node.is_hold:
		return
	for node_to in path_nodes:
		if is_node_self(node_to, path_node) or is_node_cullable(node_to):
			continue
		var diff_vector : Vector2 = node_to.node_position - path_node.node_position
		if abs(diff_vector.x) < horz_jump_dist and abs(diff_vector.y) < vert_jump_dist:
			if is_path_jumpable(node_to, path_node, vert_jump_dist):
				astar_graph.connect_points(path_node.point_id, node_to.point_id, false)

func add_jump_hold_connections(path_node: PathNode) -> void:
	if path_node.is_hold:
		return
	for node_to in path_nodes:
		if is_node_self(node_to, path_node) or is_node_cullable(node_to):
			continue
		var diff_vector : Vector2 = node_to.node_position - path_node.node_position
		if node_to.is_hold and abs(diff_vector.x) < horz_jump_hold_dist and abs(diff_vector.y) < vert_jump_hold_dist:
			if is_path_jumpable(node_to, path_node, vert_jump_dist):
				astar_graph.connect_points(path_node.point_id, node_to.point_id, false)

func add_hold_connections(path_node : PathNode) -> void:
	if not path_node.is_hold:
		return
	for node_to in path_nodes:
		if is_node_self(node_to, path_node) or is_node_cullable(node_to):
			continue
		var diff_vector : Vector2 = node_to.node_position - path_node.node_position
		if abs(diff_vector.x) < horz_hold_dist and abs(diff_vector.y) < vert_hold_dist:
			if diff_vector.length() < horz_hold_dist: # only jumpable if total length is less
				if is_path_jumpable(node_to, path_node, vert_hold_dist):
					astar_graph.connect_points(path_node.point_id, node_to.point_id, false)
					# false means single direction

func add_falling_connections(path_node : PathNode) -> void:
	if path_node.is_hold:
		return
	for node_to in path_nodes:
		if is_node_self(node_to, path_node) or is_node_cullable(node_to):
			continue
		var diff_vector : Vector2 = node_to.node_position - path_node.node_position
		# allow falling straight down
		if abs(diff_vector.x) < horz_jump_dist and diff_vector.y > 0:
			if is_path_fallable(path_node, node_to):
				astar_graph.connect_points(path_node.point_id, node_to.point_id, false)

func is_path_clear(path_node: PathNode, path_node_to: PathNode) -> bool:
	var space_state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(path_node.node_position, path_node_to.node_position)
	query.exclude = [path_node, path_node_to]
	query.collision_mask = 1 << 1
	query.collide_with_areas = false
	var result : Dictionary = space_state.intersect_ray(query)
	return result.is_empty()

func is_path_fallable(path_node: PathNode, path_node_to: PathNode) -> bool:
	var space_state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	# First, check if you can get to the horizontal space over the fall
	var over_fall : Vector2 = Vector2(path_node_to.node_position.x, path_node.node_position.y);
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(path_node.node_position, over_fall)
	query.exclude = [path_node, path_node_to]
	query.collision_mask = 1 << 1
	query.collide_with_areas = false
	var result : Dictionary = space_state.intersect_ray(query)
	if not result.is_empty():
		return false
	# Next, check if you can fall straight down from that point
	query = PhysicsRayQueryParameters2D.create(over_fall, path_node_to.node_position)
	query.exclude = [path_node, path_node_to]
	query.collision_mask = 1 << 1
	query.collide_with_areas = false
	result = space_state.intersect_ray(query)
	return result.is_empty()

func is_path_jumpable(path_node: PathNode, path_node_to: PathNode, jump_height_max : float)-> bool:
	var space_state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	# Check if there's overhead to jump here
	var jump_position : Vector2 = Vector2(path_node.node_position.x, path_node.node_position.y - jump_height_max)
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(path_node.node_position, jump_position)
	query.exclude = [path_node, path_node_to]
	query.collision_mask = 1 << 1
	query.collide_with_areas = false
	var result : Dictionary = space_state.intersect_ray(query)
	# see if rest of the jump is possible
	query = PhysicsRayQueryParameters2D.create(jump_position, path_node_to.node_position)
	query.exclude = [path_node, path_node_to]
	query.collision_mask = 1 << 1
	query.collide_with_areas = false
	result = space_state.intersect_ray(query)
	return result.is_empty()

func clear_astar_connections() -> void:
	for path_node in path_nodes:
		for connection_id in astar_graph.get_point_connections(path_node.point_id):
			astar_graph.disconnect_points(path_node.point_id, connection_id)
	
func is_node_self(path_node_1 : PathNode, path_node_2 : PathNode) -> bool:
	return path_node_2.point_id == path_node_1.point_id

func _gamemanager_new_scene_loaded() -> void:
	path_semaphore.wait()
	path_nodes.clear()
	astar_graph.clear()
	last_path.clear()
	queue_redraw()
	path_semaphore.post()
