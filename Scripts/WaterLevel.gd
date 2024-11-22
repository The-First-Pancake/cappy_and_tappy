extends Node2D

@export var rise_speed: float = 10
@export var rise_direction: Vector2 = Vector2(0,1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += rise_speed * delta * rise_direction


func _on_water_destroy_area_body_entered(body: Node2D) -> void:
	if body is TileMapLayer: return
	
	body.queue_free()
