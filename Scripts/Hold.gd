extends PathNode

func _ready() -> void:
	is_hold = true
	var parent: Node = get_parent()
	if parent is Placeable:
		parent.placed.connect(enter_pathfinding_graph)
