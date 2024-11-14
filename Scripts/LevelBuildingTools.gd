@tool
class_name LevelBuildingTools
extends Node


var rotate_debounce: bool = false
var parenting_debounce: bool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var parent: Node2D = get_parent()
	if Engine.is_editor_hint(): #editor tools
		if parent in EditorInterface.get_selection().get_selected_nodes():
			if Input.is_key_pressed(KEY_V): #rotate key
				if rotate_debounce == false:
					rotate_debounce = true
					parent.rotate(PI/2)
			else:
				rotate_debounce = false
			
			if EditorInterface.get_selection().get_selected_nodes().size() == 2:
				if Input.is_key_pressed(KEY_B): #parent
					if parenting_debounce == false:
						parenting_debounce = true
						if parent == EditorInterface.get_selection().get_selected_nodes()[0]:
							parent.reparent(EditorInterface.get_selection().get_selected_nodes()[1])
				else:
					parenting_debounce = false
		return
