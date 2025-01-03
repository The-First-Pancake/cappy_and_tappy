@tool
class_name LevelBuildingTools
extends Node

@export var auto_parent_to: String = ""

var rotate_debounce: bool = false
var parenting_debounce: bool = false
var flip_debounce: bool = false
var autoparent_debounce: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_parent().get_parent() is LevelInfo:
			try_auto_parent()
	


func try_auto_parent() -> void:
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return #don't try to do this while dragging the object in
	#if get_parent() in EditorInterface.get_selection().get_selected_nodes():
	if auto_parent_to != "":
		var new_parent: Node = get_tree().get_first_node_in_group(auto_parent_to)
		if new_parent:
			get_parent().reparent(new_parent)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_parent() is Node2D:
		var parent: Node2D = get_parent()
		if Engine.is_editor_hint(): #editor tools
			if parent in EditorInterface.get_selection().get_selected_nodes():
				if Input.is_key_pressed(KEY_V): #rotate key
					if rotate_debounce == false:
						rotate_debounce = true
						parent.rotate(PI/2)
				else:
					rotate_debounce = false
					
				if Input.is_key_pressed(KEY_C): #flip key
					if flip_debounce == false:
						flip_debounce = true
						parent.apply_scale(Vector2(-1, 1))
				else:
					flip_debounce = false
				
				if EditorInterface.get_selection().get_selected_nodes().size() == 2:
					if Input.is_key_pressed(KEY_B): #parent
						if parenting_debounce == false:
							parenting_debounce = true
							if parent == EditorInterface.get_selection().get_selected_nodes()[0]:
								parent.reparent(EditorInterface.get_selection().get_selected_nodes()[1])
					else:
						parenting_debounce = false
				
				if Input.is_key_pressed(KEY_P):
					if autoparent_debounce == false:
						autoparent_debounce = true
						try_auto_parent()
				else:
					autoparent_debounce = false
