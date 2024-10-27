class_name Arrow
extends CharacterBody2D

const max_roation_on_hit = 10
@export var speed : float = 300.0
var lifetime : float = 5.0

func _physics_process(_delta: float) -> void:
	if (speed != 0):
		velocity = speed * Vector2.UP.rotated(global_rotation)
		move_and_slide()
		var collision : KinematicCollision2D = get_last_slide_collision()
		if collision:
			if collision.get_collider() is ScarabBeetle:
				collision.get_collider().die()
				return
			self.reparent(collision.get_collider())
			stick_in_object()
			if collision.get_collider() is Player:
				collision.get_collider().die()

func stick_in_object() -> void:
	speed = 0
	show_behind_parent = true
	$CollisionShape2D.disabled = true
	$AnimatedSprite2D.visible = false
	$ArrowSingle.visible = true
	$ArrowSingle.show_behind_parent = true
	# rotate a bit
	var rotate_amount : float = randf_range(-1, 1) * max_roation_on_hit
	rotate(deg_to_rad(rotate_amount))
	await get_tree().create_timer(lifetime).timeout
	queue_free()
