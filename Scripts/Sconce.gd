extends Area2D

@onready var point_light_2d: PointLight2D = $Fire/PointLight2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		parent.placed.connect(func() -> void:
				point_light_2d.texture_scale = 1
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fall() -> void:
	point_light_2d.enabled = false
	
