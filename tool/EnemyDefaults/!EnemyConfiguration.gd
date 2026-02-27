## Resource for configuring a single enemy type and its behavior.
## Add one of these per enemy type you want to spawn in the world.
class_name EnemyConfiguration
extends Resource

#region ENEMY IDENTITY
@export_group("Enemy")
## Display name for this enemy type (used in debug logs)
@export var enemy_name : String = "Enemy"
## The scene to instantiate for this enemy
@export var enemy_scene : PackedScene
#endregion

#region SPAWN SETTINGS
@export_group("Spawn Settings")
## How many chunks form one "spawn group". 
## e.g. 4 means: for every 4 chunks, this many enemies will be spawned across them.
@export_range(1, 128) var chunks_per_group : int = 4
## How many enemies to spawn per group of chunks defined above.
## e.g. 1 means one enemy per 4 chunks. 20 means 20 enemies per chunk (if chunks_per_group = 1).
@export_range(0, 100) var enemies_per_group : int = 1
## Hard cap: maximum enemies that can spawn in a single chunk regardless of group math.
@export_range(0, 50) var max_per_chunk : int = 3
## Spawn chance per valid spawn attempt (0.0 to 1.0). 
## Use this to add randomness on top of the group-based counts.
@export_range(0.0, 1.0, 0.01) var spawn_chance : float = 1.0
## Only spawn enemies on the surface (at terrain_height). Disable to allow underground spawns. [br]
## WARNING - The current system does not support caves, this is just future proofing, turning this off 
## will break it. 
@export var surface_only : bool = true
#endregion

#region BEHAVIOR SETTINGS
@export_group("Behavior")

## If enabled, the enemy will patrol around its spawn point.
@export var can_patrol : bool = false
## Radius (in voxels) the enemy is allowed to wander while patrolling.
## Only used when [member EnemyConfiguration.can_patrol] is true.
@export_range(1.0, 100.0, 0.5) var patrol_radius : float = 10.0
## Patrol movement speed.
@export_range(0.1, 20.0, 0.1) var patrol_speed : float = 2.0

## If enabled, the enemy will chase the player when they are nearby.
## Can be combined with [member EnemyConfiguration.can_patrol] or used alone.
@export var can_chase : bool = false
## How close the player must be (in meters) before the enemy starts chasing.
## Only used when [member EnemyConfiguration.can_chase] is true.
@export_range(1.0, 200.0, 1.0) var chase_detection_range : float = 20.0
## Chase movement speed.
@export_range(0.1, 30.0, 0.1) var chase_speed : float = 4.0
## How far the player must get before the enemy gives up chasing and returns to patrol/idle.
## Only used when [member EnemyConfiguration.can_chase] is true.
@export_range(1.0, 300.0, 1.0) var chase_abandon_range : float = 35.0

#endregion
