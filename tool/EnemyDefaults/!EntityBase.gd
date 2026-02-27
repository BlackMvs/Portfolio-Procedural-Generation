@abstract
class_name EntityBase
extends CharacterBody3D

#TODO finish the class and change set up + comments
#TODO change all the names from enemy to entity 

var player : Node3D = null
var can_patrol : bool = false
var patrol_radius : float = 10.0
var patrol_speed : float = 2.0
var patrol_origin : Vector3 = Vector3.ZERO
var can_chase : bool = false
var chase_detection_range : float = 20.0
var chase_speed : float = 4.0
var chase_abandon_range : float = 35.0

const GRAVITY : float = -9.8

## Override this instead of _ready()
@abstract func enemy_ready()

## Override this instead of _physics_process()
@abstract func enemy_process(delta : float)

func _ready() -> void:
	patrol_origin = global_position
	enemy_ready()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	enemy_process(delta)
	move_and_slide()
