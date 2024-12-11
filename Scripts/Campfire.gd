class_name Campfire
extends Area2D

@onready var smoke_particle_fx: CPUParticles2D =  %"Smoke Particle FX" as CPUParticles2D
@onready var ember_particle_fx: CPUParticles2D =  %"Ember Particle FX" as CPUParticles2D
@onready var flame_sprite: AnimatedSprite2D = %"Flame Sprite" as AnimatedSprite2D
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var flag_sprite: AnimatedSprite2D = $"Flag Sprite"
@onready var light_sound: AudioStreamPlayer = $CampfireLight as AudioStreamPlayer
@onready var extinguish_sound: AudioStreamPlayer = $CampfireExtinguish as AudioStreamPlayer
@onready var squashable: Squashable = $Squashable

var flat_angle: float = 20

var is_lit: bool:
	set(val):
		if is_lit == val:
			return
		if val == true and abs(global_rotation_degrees) > flat_angle:
			return #cannot light if not upright
		is_lit = val
		smoke_particle_fx.emitting = val
		ember_particle_fx.emitting = val
		point_light_2d.visible = val
		flame_sprite.visible = val
		if val == true:
			flame_sprite.play("ignite")
			AudioManager.PlayAudio(light_sound)
			await flame_sprite.animation_looped
			flame_sprite.play("burning")
	get:
		return smoke_particle_fx.emitting
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_lit = false
	flag_sprite.play("wave")
	var parent: Node = get_parent()
	if parent is Placeable:
		parent.placed.connect(func() -> void:
			if abs(global_rotation_degrees) > flat_angle:
				break_apart()
		)
	squashable.squashed.connect(break_apart)

func break_apart() -> void:
	if is_lit:
		extinguish()
	var gibs: Node2D = %Gibs as Node2D
	if gibs == null: return
	await get_tree().process_frame
	gibs.process_mode = Node.PROCESS_MODE_INHERIT
	gibs.reparent(get_tree().current_scene)
	
	await get_tree().process_frame
	get_tree().create_timer(20).timeout.connect(gibs.queue_free)
	gibs.visible = true
	queue_free()

func extinguish() -> void:
	if !is_lit: return
	AudioManager.PlayAudio(extinguish_sound)
	is_lit = false

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("water"):
		if is_lit:
			extinguish()
