extends Area2D

@onready var lightning_beam: Area2D = $"Lightning Beam"

var rot_speed: float = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lightning_beam.rotation_degrees = randf_range(0,360)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lightning_beam.rotation_degrees += rot_speed * delta
