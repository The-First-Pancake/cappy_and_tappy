class_name PathNode
extends Area2D

var active : bool = false
var point_id : int = 0
var is_hold : bool = false
var node_position : Vector2 :
	get():
		return $NodePosition.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		parent.placed.connect(enter_pathfinding_graph)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _exit_tree() -> void:
	if (active):
		PathFindingGraph.remove_pathfinding_node(self)

func enter_pathfinding_graph() -> void:
	# Destroy most nodes if placed sideways
	if not is_hold and abs(global_rotation_degrees) > 20:
		queue_free()
		return
	# Don't add holds to pathfinding if placed faceup
	if is_hold and abs(global_rotation_degrees) < 20:
		return
	active = true
	PathFindingGraph.add_pathfinding_node(self)

func _on_squashable_squashed() -> void:
	destroy()

func destroy() -> void:
	if (active):
		PathFindingGraph.remove_pathfinding_node(self)
	queue_free()
