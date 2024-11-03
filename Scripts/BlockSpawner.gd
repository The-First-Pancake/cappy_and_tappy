class_name BlockSpawner
extends Marker2D

var spawn_timer : Timer

@export var spawn_container : Node2D
@export var block_prefabs : Array[PackedScene] :
	set(_block_prefabs):
		block_prefabs = _block_prefabs
		refresh_block_bag()
@export var spawn_objects: Array[SpawnObject]
@export var spawn_object_probability : float = 0.0
@export var every_block_spawn_objects: Array[SpawnObject]

var spawned_block : Placeable
var spawned_object_counts : Array[int] = []
var block_bag : Array[PackedScene]
var total_objects_to_spawn : int = 0
var appended_spawns : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_timer = $SpawnTimer as Timer
	spawned_object_counts.resize(len(spawn_objects))
	refresh_block_bag()
	refresh_spawn_object_counts()
	generate_and_spawn_block()

func add_spawn_object(object : SpawnObject) -> void:
	spawn_objects.append(object)
	spawned_object_counts.append(0)
	appended_spawns += 1
	refresh_spawn_object_counts()

func clear_added_spawns() -> void:
	for i in appended_spawns:
		spawn_objects.remove_at(spawn_objects.size()-1)
		spawned_object_counts.remove_at(spawned_object_counts.size()-1)
		appended_spawns -= 1
	refresh_spawn_object_counts()

func generate_and_spawn_block() -> void:
	if (block_bag.size() == 0):
		refresh_block_bag()
	if (block_bag.size() == 0): #if it's still empty (meaning this level doesn't want blocks) just return
		return
	spawned_block = block_bag.pop_front().instantiate() as Placeable
	add_child(spawned_block)
	spawned_block.global_position = global_position
	spawned_block.connect("picked_up", _spawned_block_picked_up)
	spawned_block.enter_queued() # force entering the queued again to force physics layers
	generate_and_spawn_hold_objects(spawned_block)
	spawned_block.enter_queued() # force entering the queued again to force physics layers

func generate_and_spawn_hold_objects(block: Placeable) -> void:
	var spawn_point_idxs : Array = range(len(block.hold_point_generator.get_generated_points()))
	spawn_point_idxs.shuffle()
	var every_block_idx : int = 0
	for spawn_point_idx : int in spawn_point_idxs:
		if every_block_idx < len(every_block_spawn_objects):
			spawn_object_on_hold(every_block_spawn_objects[every_block_idx], block, spawn_point_idx)
			every_block_idx += 1
		elif (randf() < spawn_object_probability):
			var cum_probability : float = 0
			var object_choice : float = randf()
			for i in len(spawn_objects):
				cum_probability += float(spawned_object_counts[i]) / float(total_objects_to_spawn)
				if (object_choice <= cum_probability):
					spawned_object_counts[i] -= 1
					total_objects_to_spawn -= 1
					spawn_object_on_hold(spawn_objects[i], block, spawn_point_idx)
					if (total_objects_to_spawn == 0):
						refresh_spawn_object_counts()
					break

func spawn_object_on_hold(object: SpawnObject, block: Placeable, spawn_point_idx: int) -> void:
	var spawned_obj : Node2D = object.spawn_prefab.instantiate() as Node2D
	block.add_child(spawned_obj)
	spawned_obj.position = block.hold_point_generator.generated_points[spawn_point_idx]
	var orth_vector : Vector2 = block.hold_point_generator.generated_orth_vectors[spawn_point_idx]
	spawned_obj.rotate(Vector2.UP.angle_to(orth_vector))

func refresh_spawn_object_counts() -> void:
	total_objects_to_spawn = 0
	for i in len(spawn_objects):
		spawned_object_counts[i] = spawn_objects[i].spawn_count
		total_objects_to_spawn += spawn_objects[i].spawn_count

func refresh_block_bag() -> void:
	block_bag.clear()
	# tetris 2 of each block
	for block in block_prefabs:
		block_bag.append(block)
		block_bag.append(block)
	block_bag.shuffle()
	

func _spawned_block_picked_up() -> void:
	spawn_timer.start()
	spawned_block.reparent(spawn_container)
	spawned_block.disconnect("picked_up", _spawned_block_picked_up)

func _spawn_timer_finished() -> void:
	generate_and_spawn_block()
