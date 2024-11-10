class_name Pirahna
extends Area2D

var speed: float = 225 #pixels/sec
var angular_vel: float = 20 #radians/sec
var angular_accel: float = 0.25 #does not have units
var swim_dir: Vector2 = Vector2(1,0)
@onready var swim_area: Area2D = $".."
var noise_gen: FastNoiseLite = FastNoiseLite.new()
@onready var pirahna_sprite: Sprite2D = %"Pirahna Sprite"
var splash_particles: PackedScene = preload("res://Prefabs/Pirahnas/splash_particles.tscn")

@onready var noise_offset: float = randf_range(0,10000)

func _ready() -> void:
	noise_gen.noise_type = FastNoiseLite.TYPE_PERLIN

var was_submerged: bool = true

func _process(delta: float) -> void:
	var is_submerged: bool = get_overlapping_areas().has(swim_area)
	var is_above_waterline: bool = !is_submerged and global_position.y < swim_area.global_position.y
	var player: Player = GameManager.player
	
	if is_submerged:
		var rand_angle: float = noise_gen.get_noise_1d(Time.get_ticks_msec()*angular_accel + noise_offset) * angular_vel
		if player: # I tried biasing the movment towards the player this way. It made them jump a little too much and it didn't make a huge difference
			rand_angle = abs(rand_angle) * sign(global_position.angle_to_point(player.global_position))
		swim_dir = swim_dir.rotated(rand_angle * delta)
	else:
		var angle_to_home: float = (swim_area.global_position - global_position).angle()
		if is_above_waterline: 
			angle_to_home = Vector2.DOWN.angle()
		var new_angle: float = rotate_toward(swim_dir.angle(), angle_to_home, delta * 5)
		swim_dir = Vector2.from_angle(new_angle)
	if was_submerged != is_submerged and is_above_waterline:
		var splash: CPUParticles2D = splash_particles.instantiate()
		swim_area.add_child(splash)
		splash.global_position = global_position
		splash.emitting = true
		splash.finished.connect(func() -> void:
			splash.queue_free()
			)
	
	rotation = swim_dir.angle() #rotate to face movement
	if swim_dir.angle_to(Vector2.LEFT) < PI/2 and  swim_dir.angle_to(Vector2.LEFT) > -PI/2:
		pirahna_sprite.flip_v = true
	else:
		pirahna_sprite.flip_v = false
	global_position += swim_dir * speed * delta
	was_submerged = is_submerged
