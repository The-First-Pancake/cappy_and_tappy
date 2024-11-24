extends Sprite2D

@export var controller_texture : Texture2D
var mkb_texture : Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mkb_texture = texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if is_instance_valid(controller_texture):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			texture = controller_texture
		if event is InputEventKey:
			texture = mkb_texture
