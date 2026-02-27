class_name Player
extends CharacterBody3D

#region EXPORTS
@export var mouseSensitivity : float = 0.001 #radians per pixel 

#...............................................................................
#endregion EXPORTS


#region REFERENCES 
#UI reference 
#@onready var playerUI : PlayerUI = %PlayerUi
#Camera reference
@onready var cameraPivot : Node3D = %CameraPivot
@onready var playerCamera : Camera3D = %Camera
@onready var collision : CollisionShape3D = $CollisionShape3D

#...............................................................................
#endregion REFERENCES 


#region INSTANCE FIELDS
#Movement settings
var walkSpeed : float = 5.0
var flySpeed : float = 8.0
var jumpVelocity : float = 5

#Flying mode
var flyingMode : bool = true :
	set(newValue):
		flyingMode = newValue
		#Update UI
		#playerUI.flyToggleText(flyingMode)

#Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#...............................................................................
#endregion INSTANCE FIELDS


func _ready():
	print("!!! Controls !!!")
	print("9 - toggle flying mode")
	print("alt - show hide mouse")
	print("Space - jump / fly up")
	print("CTRL - fly down")
	#Display flying toggle 
	#playerUI.flyToggleText(flyingMode)
	
	#Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	#Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#Rotate player horizontally
		rotate_y(-event.relative.x * mouseSensitivity)
		#Rotate camera vertically
		cameraPivot.rotate_x(-event.relative.y * mouseSensitivity)
		#Clamp vertical rotation
		cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	
	#Toggle flying mode
	if Input.is_key_pressed(KEY_9):
		flyingMode = !flyingMode
		collision.disabled = !collision.disabled
	
	#Show or hide the player mouse 
	if Input.is_key_pressed(KEY_ALT):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _physics_process(delta):
	#Check which mode is being used and apply the logic 
	if flyingMode:
		_handle_flying_mode(delta)
	else:
		_handle_walking_mode(delta)
	
	move_and_slide()
	

#region WALKING/FLYING PHYSICS PROCESS
## Physics process for walking mode, when the player walks 
func _handle_walking_mode(delta):
	#Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	#Handle jump
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jumpVelocity
	
	#Get input direction
	var input_dir = Vector2.ZERO
	input_dir.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	input_dir.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	input_dir = input_dir.normalized()
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#Set moving direction 
	if direction:
		velocity.x = direction.x * walkSpeed
		velocity.z = direction.z * walkSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, walkSpeed)
		velocity.z = move_toward(velocity.z, 0, walkSpeed)
	


## Physics process for flying mode, when the player flies 
func _handle_flying_mode(_delta):
	#Get horizontal input
	var input_dir = Vector2.ZERO
	input_dir.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	input_dir.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	input_dir = input_dir.normalized()
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#Handle vertical movement
	var vertical_input = 0.0
	if Input.is_key_pressed(KEY_SPACE): #Space to go up
		vertical_input = 1.0
	if Input.is_key_pressed(KEY_CTRL): #Ctrl to go down
		vertical_input = -1.0
	
	#Apply movement in all directions
	if direction or vertical_input != 0:
		velocity.x = direction.x * flySpeed
		velocity.z = direction.z * flySpeed
		velocity.y = vertical_input * flySpeed
	else:
		velocity.x = move_toward(velocity.x, 0, flySpeed)
		velocity.z = move_toward(velocity.z, 0, flySpeed)
		velocity.y = move_toward(velocity.y, 0, flySpeed)
	

#...............................................................................
#endregion WALKING/FLYING PHYSICS PROCESS
