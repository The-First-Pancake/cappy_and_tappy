extends Node2D

#Water Gen with Physics2DServer
@export var particle_texture : Texture2D
@export var max_water_particles : int = 1000
var current_particle_count : int = 0
var spawn_timer : float = 0
@export var spawn_time : float = 1.0
var water_particles : Array[Array]= []

func _ready() -> void:
	GameManager.loading_new_scene.connect(delete_all_particles)
	GameManager.loaded_new_scene.connect(delete_all_particles)
	

func delete_all_particles() -> void:
	for col in water_particles:
		#remove RIDs
		PhysicsServer2D.free_rid(col[0])
		RenderingServer.free_rid(col[1])
		#remove reference
		water_particles.erase(col)

func create_particle() -> void:
	# set position
	var trans : Transform2D = global_transform
	trans.origin += Vector2(randf_range(-10,10),randf_range(-10,10))
	#physics body
	var water_col : RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_mode(water_col, PhysicsServer2D.BODY_MODE_RIGID)
	PhysicsServer2D.body_set_space(water_col,get_world_2d().space)
	#create circle shape for collision
	var shape : RID = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape,5)
	#add shape to rigid body
	PhysicsServer2D.body_add_shape(water_col,shape,Transform2D.IDENTITY)
	#set collision layer and mask
	PhysicsServer2D.body_set_collision_layer(water_col, 1 << 20)
	PhysicsServer2D.body_set_collision_mask(water_col, (1 << 0) + (1 << 20))
	#set physics parameters
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_FRICTION,0.0)
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_MASS,0.05)
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE,0.25)
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_INERTIA, 1)
	PhysicsServer2D.body_set_state(water_col,PhysicsServer2D.BODY_STATE_TRANSFORM,trans)
	#Visual
	#create canvas item(all 2D objects are canvas items)
	var water_particle : RID = RenderingServer.canvas_item_create()
	#set the parent to this object
	RenderingServer.canvas_item_set_parent(water_particle, get_canvas_item())
	#set its transform
	RenderingServer.canvas_item_set_transform(water_particle,trans)
	#create a rectangle that will contain the texture
	var rect : Rect2 = Rect2()
	rect.position = Vector2(-8,-8)
	rect.size = particle_texture.get_size()
	#add the texture to the canvas item
	RenderingServer.canvas_item_add_texture_rect(water_particle,rect,particle_texture)
	#set the texture color to pink
	RenderingServer.canvas_item_set_self_modulate(water_particle,Color("ff00ff"))
	#add RID pair to array
	water_particles.append([water_col,water_particle])

func _physics_process(delta: float) -> void:
	#add particles while less than max amount set and timer < 0
	if spawn_timer < 0 and current_particle_count < max_water_particles:
		create_particle()
		current_particle_count += 1
		spawn_timer = spawn_time
	spawn_timer -= 1
	#update particle texture position to be at Rigid body position
	for col in water_particles:
		var trans : Transform2D = PhysicsServer2D.body_get_state(col[0],PhysicsServer2D.BODY_STATE_TRANSFORM)
		trans.origin = trans.origin - global_position
		RenderingServer.canvas_item_set_transform(col[1],trans)
		#Delete particles if Y position > than 1500. 2D y down is positive
		if trans.origin.y > 1500:
			#remove RIDs
			PhysicsServer2D.free_rid(col[0])
			RenderingServer.free_rid(col[1])
			#remove reference
			water_particles.erase(col)
