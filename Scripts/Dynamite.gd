class_name Dynamite
extends Area2D


@onready var block_detector: RayCast2D = $"Block Detector"
var click_debounce: bool = false
var exploding: bool = false
var start_pos: Vector2

@onready var explosion_sound: AudioStreamPlayer = $"Explosion Sound"
@onready var explosion_animation: AnimatedSprite2D = $"Explosion Animation"
@onready var explosion_particles: CPUParticles2D = $"CPUParticles2D"


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D




func _ready() -> void:
	animated_sprite_2d.play("default")
	explosion_animation.play("default")
	explosion_animation.process_mode = Node.NOTIFICATION_DISABLED
	start_pos = position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var held: bool = GameManager.currently_held_object == self
	if held and not exploding:
		var mouse_pos : Vector2 = get_global_mouse_position()
		global_position = mouse_pos

		
		#if Input.is_action_just_pressed("rotate_block_right"):
			#return_dynamite()
		
		#global_position = round(mouse_pos / grid_size) * grid_size # use this if we want to snape to grid. We currently don't cus it's too easy to click between blocks

func try_to_detonate() -> void:
	if !block_detector.is_colliding() or block_detector.get_collider() is not Placeable: 
		return_dynamite()
		return
	var block_collided_with: Placeable = block_detector.get_collider() as Placeable
	
	exploding = true
	GameManager.currently_held_object = null
	animated_sprite_2d.play("fuse")
	reparent(get_viewport().get_camera_2d().get_parent()) #reparent the dynamite off the camera
	
	await animated_sprite_2d.animation_finished
	#TODO fuse sound
	AudioManager.PlayAudio(explosion_sound)
	
	explosion_animation.reparent(get_parent())
	explosion_animation.play("explode")
	explosion_particles.reparent(get_parent())
	explosion_particles.restart()
	explosion_animation.visible = true
	explosion_animation.process_mode = Node.PROCESS_MODE_INHERIT
	explosion_animation.animation_finished.connect(explosion_animation.queue_free)
	block_collided_with.destroy(global_position, 20, 500, 1000)
	queue_free()

func return_dynamite() -> void:
	GameManager.currently_held_object = null
	reparent(get_viewport().get_camera_2d())
	position = start_pos

func try_pickup() -> void:
	if exploding: return
	
	reparent(BlockSpawner.instance.held_block_container)
	GameManager.currently_held_object = self
