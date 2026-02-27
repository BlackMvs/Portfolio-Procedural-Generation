@tool
class_name WorldGenerator
extends Node3D

#region CLASSES
## Simple voxel type definition - everything configurable in the inspector
class VoxelType:
	var voxel_name : String
	var voxel_scene : PackedScene
	var min_spawn_height : int
	var max_spawn_height : int
	var spawn_chance : float  # 0.0 to 1.0 (1.0 = 100%)
	var priority : int  # Higher priority checked first
	var mesh_node_paths : Array[NodePath] = []
	
#...................................................................................................
#endregion CLASSES


#region EXPORTS 

#region DEBUG SETTINGS
@export_group("Seed")
## DEBUG DEVELOPEMENT ONLY [br]
## If turned on (will fail unless in developement build) will ignore all the settings below [br][br]
## Only used during the development of the project! Will give error if dev file are missing! [br]
## as we use set seeds for testing
## that are being kept in a separate file.
@export var hardCodedSeed : bool = true
## Set if we want the world to use a random seed or our set seed. If turned off, it will be the 
## [member customWorldSeed] variable. 
@export var randomWorldSeed : bool = true
## The world seed, this seed will only be apllied if [member randomWorldSeed] is turned off
@export var customWorldSeed : int

@export_group("Performance")
@export_subgroup("Visibility range")
## ## At what distance do we want the object to stop showing [br][br]
## For example, if you set it at 10, if the object is withing 10m of you, you can see it but
## if it past 10m, you cannot see it anymore 
## [member WorldGenerator.visiblityRangeEnd] will not be used if [member WorldGenerator.visibilityRange] is off. 
@export var visibilityRange : bool = true
## The distance we want the object to stop showing [br][br]
## Turn on [member WorldGenerator.visiblityRange] to work 
@export var visibilityRangeEnd : float =  50
## If you already set up the visibility range in the voxel scene, set to true if you want it to be overwritten 
## by the value of [member WorldGenerator.visiblityRange] or to false if you want to keep it. 
@export var overwriteVisibilityRange : bool = true
@export_subgroup("")

@export_subgroup("Chunk rendering")
#TODO add functionality for this 
@export var player : Node3D 
@export var chunkLoadingAroundPlayer : bool = false
## How many chunks in each direction around the player to keep loaded.
## e.g. 5 means an 11x11 grid of chunks is always active around the player.
@export var render_distance : int = 3
## Extra chunks beyond render_distance before we actually unload.
## This buffer prevents chunks constantly loading/unloading when the player
## walks along a chunk border back and forth.
@export var unload_buffer : int = 2
@export_subgroup("")

@export var culling : bool = true


#region WORLD SETTINGS
@export_group("World Settings")
## When enabled, chunks will never generate outside the world_size_x/z bounds.
## When disabled, the world generates infinitely in all directions. [br][br]
## INFO To use the infinite world generation efficinetly, use the [member chunkLoadingAroundPlayer. 
## Game will not be able to load without it! 
@export var limit_world_size : bool = true

#TODO add the voxels part too 
## The types of world sizes 
enum WorldSizeTypes {
	## Calculate the world size using chunks. If you select 1x1x1, it will generate one chunk of x 
	## amount of voxels (this depends on your chunk size selected)
	CHUNKS,
	## Calculate the world size using voxels. If you select 1x1x1, it will generate one voxel 
	VOXELS
	}
## How do you want the world size to be calculated. 
@export var worldSizeType : WorldSizeTypes = WorldSizeTypes.CHUNKS

## Width of the generated world (X axis)
@export var world_size_x : int = 6
## Depth of the generated world (Z axis)
@export var world_size_z : int = 6
## Maximum height of the world (Y axis)
@export var world_size_y : int = 32
# TODO make it work with a vector 3 instead 
## Size of each voxel cube (1.0 = 1 meter)
@export var voxel_size : float = 1.0

#endregion WORLD SETTINGS


#region CHUNKS SETTINGS 
@export_group("Chunks Settings")
## The size of the chunk in voxels on the X axis
@export var chunk_size_x : int = 16  # X axis
## The size of the chunk in voxels on the Z axis
@export var chunk_size_z : int = 16  # Z axis
## The size of the chunk in voxels on the Y axis
@export var chunk_size_y : int = 32 # Y axis

#endregion CHUNKS SETTINGS 


#region GENERATION PARAMETERS
@export_group("Generation parameters")
# Terrain generation parameters
@export var amplitude : float = 10.0  # How tall the terrain features are
@export var sea_level : int = 8     # Base height of terrain
#endregion GENERATION PARAMETERS


#region LAYER CONFIGURATION
@export_group("Layer Configuration")

## Define terrain layers. Order doesn't matter - priority determines check order.
## Example setup:
##   - Surface (depth 0-0 from surface)
##   - Subsurface (depth 1-4 from surface)
##   - Deep (depth 5+ from surface)
##   - Bedrock (depth 0-2 from bottom)
@export var terrain_layers: Array[TerrainLayer] = [
	preload("uid://c64si828v6fev"), #Surface
	preload("uid://coinmj0ey1qjd"), #Sub-surface
	preload("uid://dm15xxgllybii") #Deep
]

#endregion LAYER CONFIGURATION


#region VOXEL CONFIGURATION
@export_group("Voxel Configuration")

## Array of voxel configurations - add/remove/modify as needed. 
## Each element defines a voxel type with its scene, height range, spawn chance, and priority
@export var voxel_configurations : Array[VoxelConfiguration] = [
	preload("uid://bynlt0bc05y5h"), #Grass_01
	preload("uid://c0hjwq1dswnsj"), #Dirt_01
	preload("uid://cl1pe5uait7cd")  #Stone_01
]

#endregion VOXEL CONFIGURATION


@export_group("Enemies")
##If you want the world to generate enemies 
@export var generateEnemies : bool = false
##Reference to your player
## TODO changed the name to chaseTarget, apply this change to other things as well  
@export var chaseTarget : Node3D
## Add one EnemyConfiguration resource per enemy type you want to spawn.
## Each config controls spawn density and AI behavior independently.
@export var enemy_configurations: Array[EnemyConfiguration] = []


@export_group("Editor functions")
## When you press this button the world will be added into the editor
## this way you do not have to start the game or load the world. [br]
## You can also use this to manually edit the world if you prefer
#TODO generate world with button, clear world with button 
@export_tool_button("Generate world in editor") var generateWorldBtn = editor_generateWorld
func editor_generateWorld() -> void:
	#Check if is in editor, and if it is, run editor code if not, ignore and run the game code 
	if Engine.is_editor_hint():
		print("pressed")
	else:
		return


#...................................................................................................
#endregion  EXPORTS 


#region DEBUG - TIMER 
var startTime: int
var nodesLoadedTime: int

#...................................................................................................
#endregion DEBUG - TIMER


#region INSTANCE VARIABLES 
# === DEBUG === 
# Chunks debug grid 
var debug_grid : ChunkDebugGrid

## Tracks all currently loaded chunks.
## Key: Vector3i(chunk_x, 0, chunk_z)
## Value: Node3D container holding all voxels for that chunk.
## Storing the node (instead of just true) lets us free the whole chunk
## in one queue_free() call without having to find its children manually.
var loaded_chunks : Dictionary = {}

## The chunk coordinates the player was in last frame.
## We compare this every frame, if it hasn't changed we do nothing,
## keeping _process() very cheap when the player isn't crossing chunk borders.
var _last_player_chunk : Vector2i = Vector2i(-9999, -9999)

## Guards against starting a new streaming update while one is already running.
## Without this, moving quickly could queue up multiple overlapping coroutines.
var _is_streaming : bool = false

## Internal list of voxel types converted from configurations
var voxel_types : Array[VoxelType] = []
## The node where all the voxels will be added too 
var voxelParent : Node3D = Node3D.new()
## Random number generator for spawn chances and world generation
var rng : RandomNumberGenerator
# Noise generator for terrain
var currentWorldSeed : int 
#TODO make this modular 
var noise : FastNoiseLite

## Voxels organized by layer name
var voxels_by_layer : Dictionary = {}  # layer_name -> Array[VoxelType]

## Layers sorted by priority for checking
var sorted_layers : Array[TerrainLayer] = []

## Handles all enemy spawning logic
var enemy_spawner : EnemySpawner

#...................................................................................................
#endregion INSTANCE VARIABLES 

## This runs before nodes are being added
func _init() -> void:
	#region DEBUG
	#DEBUG - Scene gets created, take a note of the time to calculate how long it takes 
	startTime = Time.get_ticks_msec()
	#endregion DEBUG
	

## This runs when node enters the tree, this always runs after the nodes are instantiated 
func _enter_tree() -> void:
	#region DEBUG
	#DEBUG - Take note of the time it took to start the scene 
	nodesLoadedTime = Time.get_ticks_msec()
	#endregion DEBUG
	

func _ready() -> void:
	## === EDITOR CODE ===
	#Check if is in editor, and if it is, run editor code if not, ignore and run the game code 
	if Engine.is_editor_hint():
		
		return
	
	#TODO check and fix the debug messages if/not working well since well we changed a lot in code
	
	## === GAME CODE ===
	#region DEBUG - ALWAYS AT THE START 
	#DEBUG - how long it took for the nodes to load 
	print("Scene nodes loaded in: " + str((nodesLoadedTime - startTime)) + " ms")
	#DEBUG - scene ready start time INFO always run at the start of the ready function 
	var readyStartTime: int = Time.get_ticks_msec()
		# DEEBUG - START TIMER
	print("Starting world generation...")
	var start_time = Time.get_ticks_msec()
	
	#endregion DEBUG - ALWAYS AT THE START 
	
	# Turn culling on or off 
	if culling: 
		get_tree().root.use_occlusion_culling = true  
	else:
		get_tree().root.use_occlusion_culling = false 
	
	print("Started generating")
	# Parent node for all the voxels, used for organisation 
	#TODO take note of speed slow down and then remove (if still applies)
	add_child(voxelParent)
	voxelParent.name = "VoxelContainer"
	
	# Add the debug grid
	debug_grid = ChunkDebugGrid.new()
	add_child(debug_grid)
	debug_grid.set_world_generator(self)
	
	# Set up enemy spawner
	if generateEnemies:
		enemy_spawner = EnemySpawner.new()
		enemy_spawner.name = "EnemySpawner"
		enemy_spawner.world_generator = self
		add_child(enemy_spawner)
	
	rng = RandomNumberGenerator.new()
	# Generate a random seed or use the custom one set by the user 
	if randomWorldSeed:
		currentWorldSeed = randi()
	else:
		currentWorldSeed = customWorldSeed
	#Set the generators with the selected seed 
	rng.seed = currentWorldSeed
	noise = FastNoiseLite.new()
	noise.set_seed(currentWorldSeed)
	
	#TODO add parameter for changing the different types and the frequency
	#Make new category, generation or something, add the seed under and the rest there too 
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05  # Lower = smoother, larger features
	
	#Set the voxel types
	setup_voxel_types()
	# Safety check - make sure we have voxels to spawn
	if voxel_types.is_empty():
		print("Warning: No voxel types configured!")
		return
	
	## === GENERATE WORLD === 
	
	#TODO generation on the y axis not working, fix it. 
	
	## If we have a player, use the streaming system, only generate chunks around them.
	## If there's no player assigned, fall back to generating a fixed grid.
	if player:
		await _update_chunks_around_player(true)  # true = emit loading screen signals
	else:
		await _generate_fixed_world()
	
	#TODO compare the speed with and without this part of the code and add to documents 
	#region DEBUG - ALWAYS AT THE END 
	#DEBUG - Console display information 
	#Scene loading time 
	var readyEndTime: int = Time.get_ticks_msec()
	print("Ready function took: " + str((readyEndTime - readyStartTime)) + " ms")
	print("Total load time was: " + str((readyEndTime - startTime)) + " ms")
	
	# Calculate and print generation statistics
	var end_time = Time.get_ticks_msec()
	var generation_time = end_time - readyStartTime
	var total_cubes = world_size_x * world_size_z * world_size_y
	print("=== World Generation Performance ===")
	print("World Size - X:" + str(world_size_x) + " Z:" + str(world_size_z) + " Y:"  + str(world_size_y))
	print("World generation complete! Time: " + str(end_time - start_time) + "ms")
	print("Total voxels spawned: " + str(get_child_count()))
	#TODO fix this 
	print("Max possible cubes: " + str(total_cubes))
	print("Cubes per second: " + str(total_cubes / (generation_time / 1000.0)))
	print("====================================")
	
	#endregion DEBUG - ALWAYS AT THE END 


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not player or _is_streaming:
		return
	
	var current_chunk = _get_chunk_coords_from_world_pos(player.global_position)
	
	if current_chunk != _last_player_chunk:
		_last_player_chunk = current_chunk
		_update_chunks_around_player()
		return
	
	# Pre-generation: check if the player is close to a chunk edge.
	# If they are, trigger streaming early so new chunks are ready before they arrive.
	# We use 30% of chunk size as the threshold - adjust to taste.
	var chunk_world_size_x = chunk_size_x * voxel_size
	var chunk_world_size_z = chunk_size_z * voxel_size
	var local_x = fmod(abs(player.global_position.x), chunk_world_size_x)
	var local_z = fmod(abs(player.global_position.z), chunk_world_size_z)
	var threshold_x = chunk_world_size_x * 0.3
	var threshold_z = chunk_world_size_z * 0.3
	
	var near_edge = (local_x < threshold_x or local_x > chunk_world_size_x - threshold_x or
		local_z < threshold_z or local_z > chunk_world_size_z - threshold_z)
	
	if near_edge:
		_update_chunks_around_player()


# Generate a chunk at the given chunk coordinates
# chunk_x and chunk_z define which chunk in the world grid
func generate_chunk(chunk_x: int, chunk_z: int):
	var chunk_y = 0
	var chunk_key = Vector3i(chunk_x, chunk_y, chunk_z)
	if loaded_chunks.has(chunk_key):
		return
	
	# Create a dedicated container node for this chunk.
	# Every voxel spawned below gets added as a child of this node, not voxelParent directly.
	# This means unloading the chunk is just one queue_free() on chunk_node -
	# Godot automatically frees all children with it.
	var chunk_node = Node3D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_x, chunk_z]
	voxelParent.add_child(chunk_node)
	# Register in loaded_chunks immediately, before we generate any voxels.
	# This prevents a second call to generate_chunk() for the same key from
	# starting while we're still building this one (e.g. if the player moves fast).
	loaded_chunks[chunk_key] = chunk_node
	
	
	var world_offset_x = chunk_x * chunk_size_x
	var world_offset_z = chunk_z * chunk_size_z
	
	# Timing
	#var time_instantiate: int = 0
	#var time_add_child: int = 0
	#var time_visibility: int = 0
	#var voxel_count: int = 0
	
	# Track surface height at each (local_x, local_z) for enemy spawning
	var surface_heights: Dictionary = {}  # Vector2i(lx, lz) -> int
	
	for x in range(chunk_size_x):
		for z in range(chunk_size_z):
			var world_x = world_offset_x + x
			var world_z = world_offset_z + z
			
			var height = noise.get_noise_2d(world_x, world_z) * amplitude
			var terrain_height = int(sea_level + height)
			terrain_height = clamp(terrain_height, 0, world_size_y - 1)
			
			# Record surface height for this column
			surface_heights[Vector2i(x, z)] = terrain_height
			
			for y in range(terrain_height + 1):
				var voxel_type = get_voxel_type_for_position(world_x, y, world_z, terrain_height)
				
				if voxel_type and voxel_type.voxel_scene:
					#voxel_count += 1
					
					#var t1 = Time.get_ticks_usec()
					var voxel_instance = voxel_type.voxel_scene.instantiate()
					#time_instantiate += Time.get_ticks_usec() - t1
					
					#var t2 = Time.get_ticks_usec()
					if visibilityRange and not voxel_type.mesh_node_paths.is_empty():
						for path in voxel_type.mesh_node_paths:
							var mesh = voxel_instance.get_node_or_null(path)
							if mesh and mesh is MeshInstance3D:
								if overwriteVisibilityRange:
									mesh.visibility_range_end = visibilityRangeEnd
								elif mesh.visibility_range_end <= 0:
									mesh.visibility_range_end = visibilityRangeEnd
					#time_visibility += Time.get_ticks_usec() - t2
					
					voxel_instance.position = Vector3(world_x, y, world_z) * voxel_size
					
					#var t3 = Time.get_ticks_usec()
					# Add to the chunk container, not voxelParent directly.
					# This is what makes clean unloading possible.
					chunk_node.add_child(voxel_instance)
					#time_add_child += Time.get_ticks_usec() - t3
	
	# Print timing for this chunk
	#print("Chunk (%d, %d): %d voxels" % [chunk_x, chunk_z, voxel_count])
	#@warning_ignore("integer_division")
	#print("  - instantiate: %d ms" % [time_instantiate / 1000])
	#@warning_ignore("integer_division")
	#print("  - visibility:  %d ms" % [time_visibility / 1000])
	#@warning_ignore("integer_division")
	#print("  - add_child:   %d ms" % [time_add_child / 1000])
	
	# Spawn enemies for this chunk after terrain is done
	if generateEnemies and enemy_spawner:
		enemy_spawner.spawn_enemies_for_chunk(chunk_x, chunk_z, surface_heights)


## Convert VoxelConfiguration resources into internal VoxelType objects
## Also sorts them by priority (higher priority = spawns first)
func setup_voxel_types():
	voxel_types.clear()
	voxels_by_layer.clear()
	
	# Sort layers by priority
	sorted_layers = terrain_layers.duplicate()
	sorted_layers.sort_custom(func(a, b): return a.priority > b.priority)
	
	# Initialize dictionary with layer names
	for layer in terrain_layers:
		if layer:
			voxels_by_layer[layer.layer_name] = []
	
	# Keep track of the index of the item in the array 
	var configIndex : int = 0 
	
	for config in voxel_configurations:
		if not config:
			continue
		
		if not config.voxel_scene:
			print("Voxel '" + config.voxel_name + "' has no scene - skipping")
			continue
		
		var voxel = VoxelType.new()
		voxel.voxel_name = "ID_" + str(configIndex) + "__" + config.voxel_name
		voxel.voxel_scene = config.voxel_scene
		voxel.min_spawn_height = config.min_spawn_height
		voxel.max_spawn_height = config.max_spawn_height
		voxel.spawn_chance = config.spawn_chance
		voxel.priority = config.priority
		
		# Find mesh paths ONCE per voxel type
		var test_instance = config.voxel_scene.instantiate()
		voxel.mesh_node_paths = _find_mesh_paths(test_instance, test_instance)
		test_instance.queue_free()
		
		if voxel.mesh_node_paths.is_empty():
			print("Voxel '" + config.voxel_name + "' has no MeshInstance3D nodes")
			print("Voxel '" + config.voxel_name + "' has no MeshInstance3D nodes")
		
		voxel_types.append(voxel)
		
		# Add to layers
		if config.layer_names.is_empty():
			for layer_name in voxels_by_layer.keys():
				voxels_by_layer[layer_name].append(voxel)
		else:
			for layer_name in config.layer_names:
				if voxels_by_layer.has(layer_name):
					voxels_by_layer[layer_name].append(voxel)
				else:
					print("Voxel '" + config.voxel_name + "' references unknown layer '" + layer_name + "'")
		print("Voxel type " + voxel.voxel_name + " has been added")
		# Add one to the index INFO always at the end of the for loop 
		configIndex += 1
	
	# Sort each layer's voxels by priority
	var sort_by_priority = func(a, b): return a.priority > b.priority
	for layer_name in voxels_by_layer.keys():
		voxels_by_layer[layer_name].sort_custom(sort_by_priority)
	
	print("=== Terrain Setup ===")
	for layer in sorted_layers:
		if layer:
			print("  " + layer.layer_name + ": " + str(voxels_by_layer[layer.layer_name].size()) + " voxels")


## Find all mesh paths relative to root node (called once per voxel type)
func _find_mesh_paths(node: Node, root: Node) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	_find_mesh_paths_recursive(node, root, paths)
	return paths


func _find_mesh_paths_recursive(node: Node, root: Node, paths: Array[NodePath]) -> void:
	if node is MeshInstance3D:
		paths.append(root.get_path_to(node))
	
	for child in node.get_children():
		_find_mesh_paths_recursive(child, root, paths)

func clear_world() -> void:
	# Iterate over all loaded chunks and free their container nodes.
	# Freeing the container automatically frees all voxels inside it.
	for key in loaded_chunks.keys():
		var chunk_node = loaded_chunks[key]
		if is_instance_valid(chunk_node):
			chunk_node.queue_free()
	loaded_chunks.clear()
	if enemy_spawner:
		enemy_spawner.clear_enemies()

func get_voxel_type_for_position(x: int, y: int, z: int, surface_height: int) -> VoxelType:
	# Find ALL matching layers
	var matching_layers: Array[TerrainLayer] = []
	var highest_priority: int = -9999
	
	for layer in sorted_layers:
		if not layer:
			continue
		
		var depth: int
		if layer.depth_mode == TerrainLayer.DepthMode.FROM_SURFACE:
			depth = surface_height - y
		else:
			depth = y
		
		var min_ok = depth >= layer.min_depth
		var max_ok = layer.max_depth == -1 or depth <= layer.max_depth
		
		if min_ok and max_ok:
			if layer.priority > highest_priority:
				# New highest priority - clear and start fresh
				highest_priority = layer.priority
				matching_layers.clear()
				matching_layers.append(layer)
			elif layer.priority == highest_priority:
				# Same priority - add to candidates
				matching_layers.append(layer)
	
	# Deterministic random based on position
	var position_seed = hash(Vector3i(x, y, z))
	var position_rng = RandomNumberGenerator.new()
	position_rng.seed = position_seed
	
	# Pick a layer (randomly if multiple with same priority)
	var matching_layer_name: String = ""
	if not matching_layers.is_empty():
		if matching_layers.size() == 1:
			matching_layer_name = matching_layers[0].layer_name
		else:
			var random_index = position_rng.randi_range(0, matching_layers.size() - 1)
			matching_layer_name = matching_layers[random_index].layer_name
	
	# Get voxels for this layer
	var layer_voxels: Array = []
	if not matching_layer_name.is_empty() and voxels_by_layer.has(matching_layer_name):
		layer_voxels = voxels_by_layer[matching_layer_name]
	
	if layer_voxels.is_empty():
		layer_voxels = voxel_types
	
	# Find valid voxels for this height
	var valid_voxels: Array[VoxelType] = []
	for voxel in layer_voxels:
		if y >= voxel.min_spawn_height and y <= voxel.max_spawn_height:
			valid_voxels.append(voxel)
	
	if valid_voxels.is_empty():
		return null
	
	# Separate guaranteed voxels (100%) from chance-based voxels
	var guaranteed_voxels: Array[VoxelType] = []
	var chance_voxels: Array[VoxelType] = []
	
	for voxel in valid_voxels:
		if voxel.spawn_chance >= 1.0:
			guaranteed_voxels.append(voxel)
		else:
			chance_voxels.append(voxel)
	
	# First, try chance-based voxels (higher priority first)
	for voxel in chance_voxels:
		if position_rng.randf() <= voxel.spawn_chance:
			return voxel
	
	# Then handle guaranteed voxels
	if not guaranteed_voxels.is_empty():
		# Find the highest priority among guaranteed voxels
		var highest_voxel_priority = guaranteed_voxels[0].priority
		
		# Collect all voxels with that highest priority
		var top_priority_voxels: Array[VoxelType] = []
		for voxel in guaranteed_voxels:
			if voxel.priority == highest_voxel_priority:
				top_priority_voxels.append(voxel)
		
		# Randomly pick one from the top priority group
		if top_priority_voxels.size() == 1:
			return top_priority_voxels[0]
		else:
			var random_index = position_rng.randi_range(0, top_priority_voxels.size() - 1)
			return top_priority_voxels[random_index]
	
	# Last resort
	return valid_voxels[0]
	


## Spawns a single voxel instance at the specified grid position
func spawn_voxel(voxel_type: VoxelType, grid_pos: Vector3) -> void:
	if not voxel_type or not voxel_type.voxel_scene:
		return
	
	var voxel_instance = voxel_type.voxel_scene.instantiate()
	
	# Apply visibility range using cached paths (no searching!)
	if visibilityRange and not voxel_type.mesh_node_paths.is_empty():
		for path in voxel_type.mesh_node_paths:
			var mesh = voxel_instance.get_node_or_null(path)
			if mesh and mesh is MeshInstance3D:
				if overwriteVisibilityRange:
					mesh.visibility_range_end = visibilityRangeEnd
				elif mesh.visibility_range_end <= 0:
					mesh.visibility_range_end = visibilityRangeEnd
	
	voxel_instance.position = grid_pos * voxel_size
	voxelParent.add_child(voxel_instance)


## Converts a world-space position into chunk grid coordinates.
## We divide by the chunk's total world size (chunk_size * voxel_size)
## and floor it so negative coordinates round the right way.
## e.g. if chunk_size_x is 16 and voxel_size is 1.0,
## world_x 0-15 = chunk 0, world_x 16-31 = chunk 1, world_x -16 to -1 = chunk -1
func _get_chunk_coords_from_world_pos(world_pos : Vector3) -> Vector2i:
	var cx = floori(world_pos.x / (chunk_size_x * voxel_size))
	var cz = floori(world_pos.z / (chunk_size_z * voxel_size))
	return Vector2i(cx, cz)


## Main streaming function - called whenever the player enters a new chunk.
## is_initial_load is true on the first call so we can emit loading screen signals.
func _update_chunks_around_player(is_initial_load : bool = false) -> void:
	if not player:
		return
	_is_streaming = true
	
	var player_chunk = _get_chunk_coords_from_world_pos(player.global_position)
	var unload_distance = render_distance + unload_buffer
	
	# STEP 1: UNLOAD
	var chunks_to_unload: Array[Vector3i] = []
	for key in loaded_chunks.keys():
		var dx = abs(key.x - player_chunk.x)
		var dz = abs(key.z - player_chunk.y)
		if dx > unload_distance or dz > unload_distance:
			chunks_to_unload.append(key)
	for key in chunks_to_unload:
		_unload_chunk(key)
	
	# STEP 2: BUILD LOAD LIST 
	var chunks_to_load: Array = []
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for z in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			# If world size is limited, skip any chunk outside the world bounds.
			# We calculate world bounds in chunk coordinates from the center (0,0).
			if limit_world_size:
				@warning_ignore("integer_division")
				var half_x = world_size_x / 2
				@warning_ignore("integer_division")
				var half_z = world_size_z / 2
				if x < -half_x or x >= world_size_x - half_x:
					continue
				if z < -half_z or z >= world_size_z - half_z:
					continue
			
			var key = Vector3i(x, 0, z)
			if not loaded_chunks.has(key):
				var dist = abs(x - player_chunk.x) + abs(z - player_chunk.y)
				chunks_to_load.append({"key": key, "dist": dist})
	
	# Sort closest chunks first so the area around the player fills in before edges
	chunks_to_load.sort_custom(func(a, b): return a.dist < b.dist)
	
	# STEP 3: LOAD
	for entry in chunks_to_load:
		generate_chunk(entry.key.x, entry.key.z)
		
		# Yield every single chunk (not every 4) to spread the load across frames.
		# This is what prevents the spike - each chunk gets its own frame budget.
		await get_tree().process_frame
	
	_is_streaming = false


## Removes a chunk from the scene and cleans up its entry in loaded_chunks.
## Because all voxels are children of the chunk_node, one queue_free()
## frees every voxel inside it automatically - no manual child iteration needed.
func _unload_chunk(chunk_key: Vector3i) -> void:
	if not loaded_chunks.has(chunk_key):
		return
	var chunk_node = loaded_chunks[chunk_key]
	# is_instance_valid guards against nodes that were already freed somehow
	if is_instance_valid(chunk_node):
		chunk_node.queue_free()
	loaded_chunks.erase(chunk_key)


## Fallback generation used when no player is assigned.
## Behaves exactly like the original fixed-grid generation did.
func _generate_fixed_world() -> void:
	@warning_ignore("integer_division")
	var offset_x := int(world_size_x / 2)
	@warning_ignore("integer_division")
	var offset_z := int(world_size_z / 2)
	for x in range(0, world_size_x):
		for z in range(0, world_size_z):
			generate_chunk(x - offset_x, z - offset_z)
			# Yield every frame to keep things smooth
			await get_tree().process_frame
