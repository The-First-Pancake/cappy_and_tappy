@tool
extends VBoxContainer

@export var show_top: bool = true:
	set(new_val):
		show_top = new_val
		if not is_inside_tree():
			return
		if show_top:
			$Top.show()
		else:
			$Top.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
