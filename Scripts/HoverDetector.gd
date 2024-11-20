class_name HoverDetector
extends Node


func _ready() -> void:
	var parent: Area2D = get_parent() as Area2D
	if parent:
		parent.mouse_entered.connect(func()-> void:
			GameManager.objects_hovering.append(parent)
			)
		parent.mouse_exited.connect(func()-> void:
			GameManager.objects_hovering.erase(parent)
			)
