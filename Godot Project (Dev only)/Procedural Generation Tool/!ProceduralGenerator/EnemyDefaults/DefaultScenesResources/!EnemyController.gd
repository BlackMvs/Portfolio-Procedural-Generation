## Template enemy controller - attach this (or your own script) to your enemy scene.
## EnemySpawner will automatically set these properties based on EnemyConfiguration.
##
## Behavior combinations:
##   can_patrol=false, can_chase=false -> Idle (stands still forever)
##   can_patrol=true,  can_chase=false -> Patrol only (ignores player)
##   can_patrol=false, can_chase=true -> Chase only (never patrols, immediately chases if in range)
##   can_patrol=true,  can_chase=true -> Patrol until player detected, then chase; return on abandon
class_name EnemyController
extends CharacterBody3D


#region BEHAVIOR FLAGS VARIABLES
# These are set automatically by EnemySpawner before the enemy enters the scene tree.
# You do not need to set these manually - configure them in the EnemyConfiguration
# resource in WorldGenerator's inspector instead.

var can_patrol : bool = false # Should this enemy walk around its spawn area?
var patrol_radius : float = 10.0 # How far from spawn it's allowed to wander (in meters)
var patrol_speed : float = 2.0 # How fast it moves while patrolling

var patrol_origin : Vector3 = Vector3.ZERO # The point it patrols around (set to spawn position)

var can_chase : bool = false # Should this enemy chase the player when nearby?
var chase_detection_range : float = 20.0 # How close the player must be to trigger a chase
var chase_speed : float = 4.0 # How fast the enemy moves while chasing
var chase_abandon_range : float = 35.0  # How far the player must get before the enemy gives up

# The player node - set by EnemySpawner automatically from WorldGenerator's player export.
# The enemy needs this to measure distance to the player and move toward them.
var player : Node3D = null

#endregion BEHAVIOR FLAGS VARIABLES


#region STATE MACHINE VARIABLES
# A state machine means the enemy can only ever be doing ONE thing at a time.
# Instead of a mess of if/else checks everywhere, each state has its own function
# that handles all the logic for that state. We switch between states using _enter_state().

enum States { IDLE, PATROL, CHASE } # The three possible states
var currentState : States = States.IDLE # Which state we're currently in (starts as IDLE)

#endregion STATE MACHINE VARIABLES


#region PATROL INTERNALS VARIABLES
var patrol_target : Vector3 = Vector3.ZERO # The current waypoint the enemy is walking toward
var patrol_wait_timer : float = 0.0 # Countdown timer for how long to wait at a waypoint

const PATROL_WAIT_TIME : float = 2.0 # How many seconds to pause at each waypoint before moving on
const ARRIVAL_THRESHOLD : float = 0.8 # How close (in meters) counts as "arrived" at a waypoint

#endregion PATROL INTERNALS VARIABLES


#region OBSTACLE JUMPING VARIABLES
var jump_cooldown : float = 0.0 # Prevents the enemy from spamming jumps repeatedly
const JUMP_FORCE : float = 5.0 # How strong the jump is (higher = jumps over taller blocks)

#endregion OBSTACLE JUMPING VARIABLES


#region PHYSICS VARIABLES
const GRAVITY : float = -9.8 # Downward acceleration applied every frame when airborne

#endregion PHYSICS VARIABLES


## Called once when the enemy enters the scene tree.
## By this point EnemySpawner has already set all behavior flags and the player reference,
## so we can safely read can_patrol/can_chase here to decide the starting state.
func _ready() -> void:
	# Record spawn position as the center of the patrol area.
	# We use global_position because the enemy is already placed in the world by EnemySpawner.
	patrol_origin = global_position
	
	# Pick the correct starting state based on the behavior flags that were set.
	enter_state(initial_state())


## Called every physics frame (default 60 times per second).
## This is where all movement actually happens.
func _physics_process(delta: float) -> void:
	# If the enemy is in the air, pull it downward with gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Run the logic for whichever state we're currently in.
	# Each _tick_ function updates velocity.x and velocity.z to point in the right direction.
	match currentState:
		States.IDLE:   tick_idle(delta)
		States.PATROL: tick_patrol(delta)
		States.CHASE:  tick_chase(delta)
	
	# Actually move the enemy based on the velocity set above.
	# move_and_slide() handles collisions - it will stop the enemy if it hits a wall
	# rather than passing through it. This is why we need the jump logic below.
	move_and_slide()
	
	# Count down the jump cooldown timer every frame.
	#TODO add checks 
	jump_cooldown -= delta
	
	# Check if we need to jump over an obstacle in front of us.
	try_jump_over_obstacle()



#region OBSTACLE JUMPING
## Fires a ray forward to detect walls, then jumps if there's one in the way.
## This lets the enemy navigate bumpy voxel terrain without getting stuck.
func try_jump_over_obstacle() -> void:
	# Don't jump if we're already in the air or the cooldown hasn't expired.
	if jump_cooldown > 0.0 or not is_on_floor():
		return
	
	# Don't check for obstacles if we're standing still - no point jumping if not moving.
	if velocity.x == 0 and velocity.z == 0:
		return
	
	# Get the horizontal direction we're currently moving in.
	var move_dir := Vector3(velocity.x, 0, velocity.z).normalized()
	
	# Get the physics space so we can cast rays into it.
	var space := get_world_3d().direct_space_state
	
	# Create a ray that starts just in front of our feet and points forward 0.6 meters.
	# We start it slightly above ground (+ 0.1) to avoid hitting the floor itself.
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.1, 0),                  # ray start
		global_position + Vector3(0, 0.1, 0) + move_dir * 0.6  # ray end
	)
	query.exclude = [self]  # Don't hit our own collision shape
	
	# If the ray hits something (a wall or voxel block), jump over it.
	if space.intersect_ray(query):
		velocity.y = JUMP_FORCE # Launch upward
		jump_cooldown = 1.0 # Wait 1 second before jumping again


#endregion OBSTACLE JUMPING


#region STATE MACHINE
## Decides which state to start in when the enemy first spawns.
func initial_state() -> States:
	# If patrolling is enabled, start walking immediately.
	# Otherwise just stand still (IDLE) and wait to detect the player.
	if can_patrol:
		return States.PATROL
	return States.IDLE


## Switches to a new state and runs any setup that state needs.
## Always use this instead of setting state directly so setup code always runs.
func enter_state(new_state : States) -> void:
	currentState = new_state
	match currentState:
		States.PATROL:
			# Pick the first waypoint to walk toward.
			pick_new_patrol_target()
		States.CHASE:
			pass # No setup needed - tick_chase reads player position directly
		States.IDLE:
			# Stop moving immediately.
			velocity.x = 0
			velocity.z = 0


## IDLE: stand still, but keep checking if the player gets close enough to chase.
func tick_idle(_delta : float) -> void:
	velocity.x = 0
	velocity.z = 0
	check_for_player_detection()


## PATROL: walk between random waypoints within patrol_radius of the spawn point.
func tick_patrol(delta : float) -> void:
	# Always check for the player even while patrolling.
	# If they're detected this will call enter_state(CHASE) and we return early.
	check_for_player_detection()
	if currentState == States.CHASE:
		return
	
	# If we're waiting at a waypoint, count down the timer then pick a new destination.
	if patrol_wait_timer > 0.0:
		patrol_wait_timer -= delta
		velocity.x = 0
		velocity.z = 0
		if patrol_wait_timer <= 0.0:
			pick_new_patrol_target()
		return
	
	# Calculate direction toward the current patrol waypoint, ignoring Y so we
	# don't try to fly up or fall faster - gravity handles vertical movement.
	var flat_pos := Vector3(global_position.x, 0, global_position.z)
	var flat_target := Vector3(patrol_target.x, 0, patrol_target.z)
	var dir := (flat_target - flat_pos)
	
	if dir.length() <= ARRIVAL_THRESHOLD:
		# Close enough to the waypoint - stop and wait before picking the next one.
		patrol_wait_timer = PATROL_WAIT_TIME
	else:
		# Still walking - set horizontal velocity toward the target.
		dir = dir.normalized()
		velocity.x = dir.x * patrol_speed
		velocity.z = dir.z * patrol_speed


## CHASE: run directly toward the player until they escape or we lose them.
func tick_chase(_delta : float) -> void:
	# If we somehow lost the player reference, give up and go back to base behaviour.
	if not player:
		return_to_base()
		return
	
	var dist := global_position.distance_to(player.global_position)
	
	# If the player has run far enough away, give up the chase.
	if dist > chase_abandon_range:
		return_to_base()
		return
	
	# Move horizontally toward the player. We zero out Y so gravity isn't fought.
	var dir := (player.global_position - global_position)
	dir.y = 0
	if dir.length_squared() > 0.01: # Avoid normalizing a near-zero vector (would cause errors)
		dir = dir.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed


## Checks if the player is within detection range and triggers a chase if so.
## Called every frame from both IDLE and PATROL ticks.
func check_for_player_detection() -> void:
	# Only check if chasing is enabled and we actually have a player reference.
	if not can_chase or not player:
		return
	if global_position.distance_to(player.global_position) <= chase_detection_range:
		enter_state(States.CHASE)


## Called when a chase is abandoned. Returns to patrolling or idling
## depending on which behaviors are enabled for this enemy.
func return_to_base() -> void:
	if can_patrol:
		enter_state(States.PATROL)
	else:
		enter_state(States.IDLE)


## Picks a new random point within patrol_radius of patrol_origin to walk toward.
## Called on entering PATROL state and after each waypoint arrival.
func pick_new_patrol_target() -> void:
	# Pick a random angle and distance, then convert from polar to cartesian coordinates.
	# This gives us a natural-looking spread of waypoints around the origin.
	var angle := randf_range(0, TAU)                            # TAU = full 360 degrees in radians
	var dist := randf_range(patrol_radius * 0.3, patrol_radius) # Don't pick targets too close to origin
	patrol_target = patrol_origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

#endregion STATE MACHINE
