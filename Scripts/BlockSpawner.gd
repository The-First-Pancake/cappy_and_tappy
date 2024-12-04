class_name BlockSpawner
extends Marker2D

@onready var spawn_timer : Timer = $SpawnTimer as Timer

@export var block_container : Node2D
@export var held_block_container : Node2D


@export var block_prefabs : Array[PackedScene] :
	set(_block_prefabs):
		block_prefabs = _block_prefabs
		refresh_block_bag()
@export var spawn_objects: Array[SpawnObject]
@export var spawn_object_probability : float = 0.0
@export var every_block_spawn_objects: Array[SpawnObject]

var queued_block : Placeable
var spawned_object_counts : Array[int] = []
var block_bag : Array[PackedScene]
var total_objects_to_spawn : int = 0
var appended_spawns : int = 0
@onready var return_block_click_area: Area2D = $"Return Block Click Area"
var mouse_in_return_block_click_area: bool = false

static var instance: BlockSpawner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instance = self
	spawned_object_counts.resize(len(spawn_objects))
	refresh_block_bag()
	refresh_spawn_object_counts()
	generate_and_spawn_block()
	return_block_click_area.mouse_entered.connect(func()-> void:
		mouse_in_return_block_click_area = true
		)
	return_block_click_area.mouse_exited.connect(func()-> void:
		mouse_in_return_block_click_area = false
		)

func _process(delta: float) -> void:
	
	if Input.is_action_just_released("drop_block"):
		if GameManager.time_since_unpause <= 0.2: return
		var hovering_dynamite: Dynamite = null
		
		for obj: Node in GameManager.objects_hovering:
			if not is_instance_valid(obj): continue
			if obj is Dynamite:
				hovering_dynamite = obj
		
		if is_instance_valid(GameManager.currently_held_object): #if we're holding something
			if GameManager.currently_held_object is Placeable:
				if mouse_in_return_block_click_area:
					put_back_held_block() #put the block back
				elif hovering_dynamite:
					put_back_held_block()
					hovering_dynamite.try_pickup()
				else:
					GameManager.currently_held_object.try_to_drop_block()
			elif GameManager.currently_held_object is Dynamite:
				if mouse_in_return_block_click_area:
					GameManager.currently_held_object.return_dynamite()
					try_pickup_queued_block()
				else:
					GameManager.currently_held_object.try_to_detonate()
					
		else:
			if hovering_dynamite:
				hovering_dynamite.try_pickup()
			else: #If there is a block ready to be picked up
				try_pickup_queued_block()

func try_pickup_queued_block() -> void:
	if is_instance_valid(queued_block):
		queued_block.enter_placing()
		queued_block = null
		spawn_timer.start()

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

	queued_block = block_bag.pop_front().instantiate() as Placeable
	add_child(queued_block)
	queued_block.global_position = global_position
	queued_block.enter_queued() # force entering the queued again to force physics layers
	generate_and_spawn_hold_objects(queued_block)
	queued_block.enter_queued() # force entering the queued again to force physics layers

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
	


func _spawn_timer_finished() -> void:
	if queued_block == null:
		generate_and_spawn_block()


func put_back_held_block() -> void:
	if queued_block: # if there's already a queued block already spawned, return it to the bag
		queued_block.queue_free()
		queued_block = null
	
	queued_block = GameManager.currently_held_object as Placeable
	GameManager.currently_held_object = null
	queued_block.reparent(self)
	queued_block.global_position = global_position
	queued_block.enter_queued()
