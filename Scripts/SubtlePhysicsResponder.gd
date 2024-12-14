class_name SubtlePhysicsResponder
extends Area2D

@export var magnitude: float = 1000


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.velocity.length() < 10:
		return
	var rb_parent:RigidBody2D = get_parent() as RigidBody2D
	var dir: Vector2 = body.global_position.direction_to(global_position)
	rb_parent.apply_central_impulse(dir * magnitude)
