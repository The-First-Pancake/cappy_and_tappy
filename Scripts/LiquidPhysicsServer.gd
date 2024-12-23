extends Node2D

#Water Gen with Physics2DServer
@export var particle_texture : Texture2D
@export var max_water_particles : int = 1000
@export var lifetime_ms : int = 10000
var current_particle_count : int = 0
var spawn_timer : float = 0
@export var spawn_time : float = 1.0
@export_flags_2d_physics var collision_layers : int
@export_flags_2d_physics var collision_mask : int
static var particle_list : Array[RID] = []

func _ready() -> void:
	GameManager.loading_new_scene.connect(clear_all_particles)
	GameManager.loaded_new_scene.connect(clear_all_particles)

func clear_all_particles() -> void:
	for particle in particle_list:
		PhysicsServer2D.free_rid(particle)
	particle_list.clear()

func create_particle() -> void:
	# set position
	var trans : Transform2D = global_transform
	trans.origin += Vector2(randf_range(-10,10),randf_range(-10,10))
	#physics body
	var water_col : RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_attach_object_instance_id(water_col, get_instance_id())
	PhysicsServer2D.body_set_mode(water_col, PhysicsServer2D.BODY_MODE_RIGID_LINEAR)
	PhysicsServer2D.body_set_space(water_col,get_world_2d().space)
	#create circle shape for collision
	var shape : RID = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape,7)
	#add shape to rigid body
	PhysicsServer2D.body_add_shape(water_col,shape,Transform2D.IDENTITY)
	#set collision layer and mask
	PhysicsServer2D.body_set_collision_layer(water_col, collision_layers)
	PhysicsServer2D.body_set_collision_mask(water_col, collision_mask)
	#set physics parameters
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_FRICTION,0.0)
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_MASS,0.05)
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE,0.25)
	PhysicsServer2D.body_set_param(water_col,PhysicsServer2D.BODY_PARAM_INERTIA, 1)
	PhysicsServer2D.body_set_param(water_col, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, 0.75)
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
	# Add callback to do things with body
	var particle_user_data : Array = [water_col, water_particle, Time.get_ticks_msec(), GameManager.load_count]
	PhysicsServer2D.body_set_force_integration_callback(water_col, _body_moved, particle_user_data)
	# Add physics object to particle list
	particle_list.append(water_col)

func _physics_process(delta: float) -> void:
	#add particles while less than max amount set and timer < 0
	if spawn_timer < 0 and current_particle_count < max_water_particles:
		create_particle()
		current_particle_count += 1
		spawn_timer = spawn_time
	spawn_timer -= 1

func _body_moved(state: PhysicsDirectBodyState2D, user_data : Array) -> void:
	var body_rid : RID = user_data[0]
	var particle_rid : RID = user_data[1]
	var spawn_time : int = user_data[2]
	var spawn_load_count : float = user_data[3]
	# Update particle to be where rigidbody is
	var trans : Transform2D = state.transform
	trans.origin = trans.origin - global_position
	RenderingServer.canvas_item_set_transform(particle_rid, trans)
	if spawn_time + lifetime_ms < Time.get_ticks_msec():
		#remove RIDs
		PhysicsServer2D.free_rid(body_rid)
		RenderingServer.free_rid(particle_rid)
		particle_list.erase(body_rid)
		#decrement count
		current_particle_count -= 1
