extends Area2D
@export var enemy_prefab : PackedScene
@export var spawn_delay : float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if parent is Placeable:
		parent.placed.connect(func() -> void:
			if abs(global_rotation_degrees) > 20:
				destroy()
			else:
				get_tree().create_timer(spawn_delay).timeout.connect(spawn_enemy)
		)
	else:
		get_tree().create_timer(spawn_delay).timeout.connect(spawn_enemy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_enemy() -> void:
	var spawned_obj : Enemy = enemy_prefab.instantiate() as Enemy
	get_tree().current_scene.add_child(spawned_obj)
	spawned_obj.global_position = $SpawnPoint.global_position
	destroy()

func destroy() -> void:
	$Sprite2D/ShardEmitter.shatter($SpawnPoint.global_position)
