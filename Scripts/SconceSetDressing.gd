extends Area2D

@export var show_base: bool = true
@export var use_mix_light_blend: bool = false

@onready var base_sprite: StaticBody2D = $Base
@onready var point_light: PointLight2D = $Fire/PointLight2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if show_base:
		base_sprite.show()
	else:
		base_sprite.hide()
		
	if use_mix_light_blend:
		point_light.blend_mode = Light2D.BLEND_MODE_MIX
	else:
		point_light.blend_mode = Light2D.BLEND_MODE_ADD
