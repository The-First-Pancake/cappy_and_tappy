@tool
class_name HangingRope
extends Node2D

const ROPE_PIN_JOINT = preload("res://Prefabs/rope_pin_joint.tscn")
const ROPE_SEGMENT = preload("res://Prefabs/rope_segment.tscn")
var rope_anchor: StaticBody2D:
	get: return $"Rope Anchor" as StaticBody2D

@export var regenerate_rope: bool:
	set(new_val):
		generate_segments()

func _ready() -> void:
	generate_segments()


func generate_segments() -> void:
	for child: Node in get_children():
		if child != rope_anchor:
			child.queue_free()
	
	await get_tree().process_frame
	
	var segment_count: int = 10
	var last_segment: RigidBody2D = null
	var segment_length: float = 30
	var spawn_direction: Vector2 = Vector2.RIGHT
	for i in range(segment_count):
		var pin_joint: PinJoint2D = ROPE_PIN_JOINT.instantiate()
		var segment: RigidBody2D = ROPE_SEGMENT.instantiate()
		add_child(segment)
		add_child(pin_joint)
		segment.owner = owner
		pin_joint.owner = owner
		pin_joint.position = segment_length * i * spawn_direction
		segment.position = (segment_length * (i + .5)) * spawn_direction
		segment.rotation = spawn_direction.angle_to(Vector2.DOWN)
		if last_segment:
			pin_joint.node_a = last_segment.get_path()
		else:
			pin_joint.node_a = rope_anchor.get_path()
		pin_joint.node_b = segment.get_path()
		
		
		
		last_segment = segment
