## Handles enemy generation for the WorldGenerator.
## Attached as a child node - keeps enemy logic separate from terrain logic.
class_name EnemySpawner
extends Node

#TODO add better comments 

## Reference back to the world generator for accessing world settings
var world_generator : WorldGenerator

## Tracks how many enemies have been allocated to each chunk group.
## Key: group_id (Vector2i), Value: int (count spawned so far in this group)
var _group_spawn_counts : Dictionary = {}

## Parent node where all enemy instances will be added
var enemy_parent : Node3D

## Flat list of every currently live enemy instance.
## Used for distance checking which is faster than traversing the scene tree.
var _live_enemies : Array[Node3D] = []

## Automatically calculated from world generator settings.
## Enemies unload at the same distance as chunks, so they always
## disappear together rather than at mismatched distances.
var enemy_unload_distance : float:
	get:
		if not world_generator:
			return 200.0  # fallback if called before world_generator is set
		return (world_generator.render_distance
			* world_generator.chunk_size_x  
			* world_generator.voxel_size 
			* 1.5)


## Only check enemy distances every N frames to avoid checking hundreds
## of enemies every single frame.
var _distance_check_interval : int = 30
var _distance_check_timer : int = 0

func _ready() -> void:
	enemy_parent = Node3D.new()
	enemy_parent.name = "EnemyContainer"
	get_parent().add_child(enemy_parent)

func _process(_delta: float) -> void:
	# Only check every N frames there is no need to do this every frame
	_distance_check_timer += 1
	if _distance_check_timer < _distance_check_interval:
		return
	_distance_check_timer = 0
	
	if not world_generator or not world_generator.player:
		return
	
	var player_pos = world_generator.player.global_position
	var enemies_to_remove : Array[Node3D] = []
	
	for enemy in _live_enemies:
		# Enemy might have been freed by other means (e.g. killed by player)
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue
		
		var diff = enemy.global_position - player_pos
		var dist = Vector2(diff.x, diff.z).length()
		if dist < enemy_unload_distance:
			continue  # Still in range, leave it alone
		
		# Check if the enemy is currently chasing the player.
		# We use get() duck typing to match the same pattern as instantiate_enemy().
		# If the enemy script has no is_chasing property, we default to false.
		var is_chasing : bool = false
		if "is_chasing" in enemy:
			is_chasing = enemy.get("is_chasing")
		
		# Never unload a chasing enemy, it would feel like the enemy just vanished
		if is_chasing:
			continue
		
		enemies_to_remove.append(enemy)
	
	# Unload all collected enemies
	for enemy in enemies_to_remove:
		_unload_enemy(enemy)


## Unloads a single enemy and adjusts the group quota so it can respawn
## if the player returns to that area later.
func _unload_enemy(enemy: Node3D) -> void:
	_live_enemies.erase(enemy)
	
	# Reduce the group spawn count so this spot becomes available again.
	# We stored the group_id and config name on the enemy when spawning.
	if is_instance_valid(enemy):
		var group_id = enemy.get_meta("spawn_group_id", null)
		var enemy_name = enemy.get_meta("spawn_config_name", null)
		 
		if group_id != null and enemy_name != null:
			if _group_spawn_counts.has(group_id) and _group_spawn_counts[group_id].has(enemy_name):
				_group_spawn_counts[group_id][enemy_name] = max(
					0,
					_group_spawn_counts[group_id][enemy_name] - 1
				)
		
		enemy.queue_free()


## INFO Call this after a chunk finishes generating terrain.
## chunk_x, chunk_z: chunk coordinates (same as generate_chunk params)
## surface_heights: Dictionary of Vector2i(local_x, local_z) -> int surface_height
##   (pass an empty dict to auto-spawn at sea_level if surface_only is false)
func spawn_enemies_for_chunk(chunk_x : int, chunk_z : int, surface_heights : Dictionary) -> void:
	if not world_generator or not world_generator.generateEnemies:
		return
	
	for config in world_generator.enemy_configurations:
		if not config or not config.enemy_scene:
			continue
		process_enemy_config(config, chunk_x, chunk_z, surface_heights)


## Internal: handles spawn logic for a single enemy configuration in a chunk.
func process_enemy_config(
	config: EnemyConfiguration, 
	chunk_x: int, 
	chunk_z: int, 
	surface_heights: Dictionary
) -> void:
	# --- Group-based quota system ---
	# Figure out which group this chunk belongs to
	var group_id := _get_group_id(config, chunk_x, chunk_z)
	
	if not _group_spawn_counts.has(group_id):
		_group_spawn_counts[group_id] = {}
	if not _group_spawn_counts[group_id].has(config.enemy_name):
		_group_spawn_counts[group_id][config.enemy_name] = 0
	
	# How many enemies are still "owed" to this group?
	var already_spawned: int = _group_spawn_counts[group_id][config.enemy_name]
	var quota_remaining: int = config.enemies_per_group - already_spawned
	
	if quota_remaining <= 0:
		return  # This group already has its full allocation
	
	# Respect the per-chunk hard cap
	var to_spawn: int = min(quota_remaining, config.max_per_chunk)
	if to_spawn <= 0:
		return
	
	# --- Collect valid spawn positions in this chunk ---
	var wg := world_generator
	var chunk_size_x := wg.chunk_size_x
	var chunk_size_z := wg.chunk_size_z
	var world_offset_x := chunk_x * chunk_size_x
	var world_offset_z := chunk_z * chunk_size_z
	
	# Build candidate positions
	var candidates: Array[Vector3] = []
	for lx in range(chunk_size_x):
		for lz in range(chunk_size_z):
			var world_x := world_offset_x + lx
			var world_z := world_offset_z + lz
			var spawn_y: int
			
			if config.surface_only:
				var key := Vector2i(lx, lz)
				if not surface_heights.has(key):
					continue
				spawn_y = surface_heights[key] + 1 # one block above surface
			else:
				spawn_y = wg.sea_level + 1
			
			candidates.append(Vector3(world_x, spawn_y, world_z))
	
	if candidates.is_empty():
		return
	
	# --- Pick random positions using deterministic RNG keyed to chunk + config ---
	var spawn_rng := RandomNumberGenerator.new()
	spawn_rng.seed = hash(Vector3i(chunk_x, 0, chunk_z)) ^ hash(config.enemy_name)
	candidates.shuffle() # Note: shuffle is not seeded, so we use index picking below
	
	var spawned_this_chunk := 0
	var attempt_order : Array[int] = []
	attempt_order.assign(range(candidates.size()))
	# Deterministic ordering via rng
	for i in range(attempt_order.size() - 1, 0, -1):
		var j := spawn_rng.randi_range(0, i)
		var tmp = attempt_order[i]
		attempt_order[i] = attempt_order[j]
		attempt_order[j] = tmp
	
	for idx in attempt_order:
		if spawned_this_chunk >= to_spawn:
			break
		if spawn_rng.randf() > config.spawn_chance:
			continue
		
		var pos := candidates[idx] * wg.voxel_size
		instantiate_enemy(config, pos, group_id)
		spawned_this_chunk += 1
	
	_group_spawn_counts[group_id][config.enemy_name] += spawned_this_chunk
	
	#if spawned_this_chunk > 0:
		#print("EnemySpawner: Spawned %d '%s' in chunk (%d, %d)" % [
			#spawned_this_chunk, config.enemy_name, chunk_x, chunk_z
			#])


## Instantiate and configure an enemy scene at the given world position.
func instantiate_enemy(config: EnemyConfiguration, world_position: Vector3, group_id: Vector3i) -> void:
	var instance: Node3D = config.enemy_scene.instantiate()
	instance.position = world_position
	
	# Stamp the enemy with its origin info so _unload_enemy() can
	# reduce the group quota correctly when this enemy is unloaded.
	instance.set_meta("spawn_group_id", group_id)
	instance.set_meta("spawn_config_name", config.enemy_name)
	
	if instance.get_script() != null:
		if "player" in instance:
			instance.set("player", world_generator.player)
		if "can_patrol" in instance:
			instance.set("can_patrol", config.can_patrol)
		if "patrol_radius" in instance:
			instance.set("patrol_radius", config.patrol_radius)
		if "patrol_speed" in instance:
			instance.set("patrol_speed", config.patrol_speed)
		if "can_chase" in instance:
			instance.set("can_chase", config.can_chase)
		if "chase_detection_range" in instance:
			instance.set("chase_detection_range", config.chase_detection_range)
		if "chase_speed" in instance:
			instance.set("chase_speed", config.chase_speed)
		if "chase_abandon_range" in instance:
			instance.set("chase_abandon_range", config.chase_abandon_range)
		if "patrol_origin" in instance:
			instance.set("patrol_origin", world_position)
	
	enemy_parent.add_child(instance)
	
	# Register in our live enemy list for distance tracking
	_live_enemies.append(instance)


## Calculate which spawn group a chunk belongs to.
## Groups are 2D tiles of size chunks_per_group x chunks_per_group.
func _get_group_id(config : EnemyConfiguration, chunk_x : int, chunk_z : int) -> Vector3i:
	var group_size := config.chunks_per_group
	@warning_ignore("integer_division")
	return Vector3i(
		chunk_x / group_size if chunk_x >= 0 else (chunk_x - group_size + 1) / group_size,
		0,
		chunk_z / group_size if chunk_z >= 0 else (chunk_z - group_size + 1) / group_size
	)


## Clear all spawned enemies (useful when clearing the world)
func clear_enemies() -> void:
	for child in enemy_parent.get_children():
		child.queue_free()
	_group_spawn_counts.clear()
	_live_enemies.clear() 
