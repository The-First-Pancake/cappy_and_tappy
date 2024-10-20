@tool
class_name CameraZone
extends Area2D


@export var type: CameraController.CamType = CameraController.CamType.VERTICAL:
	set(val):
		type = val
		queue_redraw()
@export var mid_line_offset: float = 0:
	set(val):
		mid_line_offset = val
		queue_redraw()

@export var bottom_out: bool = true
@export var top_out: bool = true
@export var right_out: bool = true
@export var left_out: bool = true

var collision_shape: CollisionShape2D:
	get:
		return  $CollisionShape2D

var rect: RectangleShape2D:
	get:
		return collision_shape.shape as RectangleShape2D

var top_left: Vector2:
	get:
		return Vector2(collision_shape.global_position.x - rect.size.x/2, collision_shape.global_position.y - rect.size.y/2)

var bot_right: Vector2:
	get:
		return Vector2(collision_shape.global_position.x + rect.size.x/2, collision_shape.global_position.y + rect.size.y/2)

var mid_line: float:
	get:
		if type == CameraController.CamType.VERTICAL:
			return mid_line_offset + collision_shape.global_position.x
		elif type == CameraController.CamType.HORIZONTAL:
			return mid_line_offset + collision_shape.global_position.y
		else:
			return 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw() -> void:
	if !Engine.is_editor_hint(): return

	if type == CameraController.CamType.VERTICAL:
		var from_point: Vector2 = Vector2(mid_line, bot_right.y)
		var end_point: Vector2 = Vector2(mid_line, top_left.y)
		draw_line(to_local(from_point), to_local(end_point),Color.PURPLE,10)
	elif type == CameraController.CamType.HORIZONTAL:
		var from_point: Vector2 = Vector2(bot_right.x, mid_line)
		var end_point: Vector2 = Vector2(top_left.x, mid_line)
		draw_line(to_local(from_point), to_local(end_point),Color.PURPLE,10)
