class_name Door
extends Area2D


@export var is_exit: bool = false
@onready var door_frame: Sprite2D = $"Door Frame" as Sprite2D
@onready var interior_wall: StaticBody2D = $"Interior Wall"
@onready var interior_wall_2: StaticBody2D = $"Interior Wall2"
@onready var floor_collider: StaticBody2D = $Floor


var player_inside: bool = false

func _ready() -> void:
	await  get_tree().process_frame
	if is_exit:
		interior_wall.process_mode = Node.PROCESS_MODE_DISABLED
		interior_wall_2.process_mode = Node.PROCESS_MODE_DISABLED
		floor_collider.process_mode = Node.PROCESS_MODE_DISABLED 
		GameManager.exit_door = self
	else:
		interior_wall.process_mode = Node.PROCESS_MODE_INHERIT
		interior_wall_2.process_mode = Node.PROCESS_MODE_INHERIT
		floor_collider.process_mode = Node.PROCESS_MODE_INHERIT 
		GameManager.entrance_door = self

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if is_exit:
			interior_wall.process_mode = Node.PROCESS_MODE_INHERIT
			interior_wall_2.process_mode = Node.PROCESS_MODE_INHERIT
			floor_collider.process_mode = Node.PROCESS_MODE_INHERIT 
			(body as Player).exit_level()
		else:
			interior_wall.process_mode = Node.PROCESS_MODE_DISABLED
			interior_wall_2.process_mode = Node.PROCESS_MODE_DISABLED
			floor_collider.process_mode = Node.PROCESS_MODE_DISABLED 
			(body as Player).crossed_entrance_threshold.emit()
