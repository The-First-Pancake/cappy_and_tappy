class_name LightFlash
extends PointLight2D

@export var flash_duration: float = .3
@export var flash_curve: Curve
var initial_energy: float = 0
var time_since_activation: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_energy = energy
	energy = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_since_activation += delta
	energy = initial_energy * flash_curve.sample(time_since_activation/flash_duration)
	if time_since_activation > flash_duration:
		queue_free()
