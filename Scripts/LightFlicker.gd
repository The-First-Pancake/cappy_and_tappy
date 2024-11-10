class_name LightFlicker
extends PointLight2D

@export var percent_variance: float = .9

var initial_energy: float = 0
var noise_gen: FastNoiseLite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_energy = energy
	noise_gen = FastNoiseLite.new()
	noise_gen.seed = randi()
	noise_gen.noise_type = FastNoiseLite.TYPE_PERLIN


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	energy = initial_energy - initial_energy * percent_variance * noise_gen.get_noise_1d(float(Time.get_ticks_msec())/4)
