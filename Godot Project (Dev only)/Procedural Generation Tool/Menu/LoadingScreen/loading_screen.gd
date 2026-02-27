extends Node

@onready var progress_bar = $ProgressBar
@onready var status_label = $ProgressBar/Label

var world : Node3D

func _ready():
	_load_game_world()

func _load_game_world():
	# Load the world scene
	var world_scene = load("res://David/World.tscn")
	world = world_scene.instantiate()
	
	# Connect to world's generation signals
	if world is WorldGenerator:
		world.generation_progress.connect(_on_generation_progress)
		world.generation_complete.connect(_on_generation_complete)
		# Wait for things to load in
		await get_tree().process_frame
		
		get_tree().root.add_child(world)
		get_tree().current_scene = world
	else:
		get_tree().root.add_child(world)
		get_tree().current_scene = world
		queue_free()

func _on_generation_progress(current: int, total: int, status: String):
	progress_bar.value = (float(current) / total) * 100.0
	status_label.text = status + str(current) + " / " + str(total)

func _on_generation_complete():
	 # Disconnect signals
	world.generation_progress.disconnect(_on_generation_progress)
	world.generation_complete.disconnect(_on_generation_complete)
	# Switch to game scene
	queue_free()
