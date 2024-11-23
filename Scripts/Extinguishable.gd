class_name Extinguishable
extends Node

@export var nodes_to_disable: Array[Node2D]

func _ready() -> void:
	var parent: Area2D = get_parent()
	if parent is Area2D:
		parent.area_entered.connect(func(area: Area2D) -> void:
			if parent.get_parent() is Placeable:
				if parent.get_parent().state == Placeable.PlaceState.PLACING: return
			if area.is_in_group("water"):
				for node: Node2D in nodes_to_disable:
					node.visible = false
		)
