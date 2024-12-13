extends Area2D

@export var use_mix_light_blend: bool = false

@onready var point_light: PointLight2D = $PointLight2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		
	if use_mix_light_blend:
		point_light.blend_mode = Light2D.BLEND_MODE_MIX
	else:
		point_light.blend_mode = Light2D.BLEND_MODE_ADD
