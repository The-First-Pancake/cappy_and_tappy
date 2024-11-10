class_name Extinguishable
extends Node

@export var nodes_to_disable: Array[Node2D]

func _ready() -> void:
	var parent: Area2D = get_parent()
	if parent is Area2D:
		parent.area_entered.connect(func(area: Area2D) -> void:
			if area.is_in_group("water"):
				for node: Node2D in nodes_to_disable:
					node.visible = false
		)
