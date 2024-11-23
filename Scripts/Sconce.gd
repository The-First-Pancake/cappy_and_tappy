extends Area2D

@onready var point_light_2d: PointLight2D = $Fire/PointLight2D
@onready var fire: RigidBody2D = $Fire

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		parent.falling.connect(func() -> void:
			fire.freeze = false
		)
		parent.placed.connect(func() -> void:
			point_light_2d.texture_scale = 18
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fall() -> void:
	point_light_2d.enabled = false
	
