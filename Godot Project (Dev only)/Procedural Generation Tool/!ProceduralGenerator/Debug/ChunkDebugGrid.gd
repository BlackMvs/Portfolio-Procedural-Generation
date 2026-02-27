extends Node3D
class_name ChunkDebugGrid

#TODO chunk debug generation not working on the y axis, fix it 

var grid_visible: bool = false
var immediate_mesh: ImmediateMesh
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var render_distance: int = 3  # How many chunks to show in each direction

# Reference to world generator to get chunk info
var world_generator: Node = null
var chunk_size: Vector3 = Vector3(16, 32, 16)

func _ready():
	# Create the mesh instance for drawing lines
	mesh_instance = MeshInstance3D.new()
	immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	add_child(mesh_instance)
	
	# Create a material for the grid lines
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0, 1, 0, 0.5)  # Green with transparency
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true  # Make lines visible through blocks
	mesh_instance.material_override = material
	
	mesh_instance.visible = false

func _process(_delta):
	# Update grid every frame when visible (for smooth following of player)
	if grid_visible:
		update_grid()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle_grid()

func toggle_grid():
	grid_visible = !grid_visible
	mesh_instance.visible = grid_visible
	
	if grid_visible:
		update_grid()
	
	print("Chunk debug grid: ", "ON" if grid_visible else "OFF")

func set_world_generator(generator: Node):
	world_generator = generator
	if world_generator:
		chunk_size = Vector3(
			world_generator.chunk_size_x, 
			world_generator.chunk_size_y, 
			world_generator.chunk_size_z
		)

func update_grid():
	if not world_generator:
		return
	
	immediate_mesh.clear_surfaces()
	
	# Start drawing
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Draw loaded chunks
	for chunk_key in world_generator.loaded_chunks.keys():
		# chunk_key is Vector3i(chunk_x, chunk_y, chunk_z)
		draw_chunk_box(chunk_key)
	
	immediate_mesh.surface_end()

func draw_chunk_box(chunk_pos: Vector3i):
	# Calculate world position of chunk corners
	# Multiply each component separately for non-cubic chunks
	var world_pos = Vector3(
		chunk_pos.x * chunk_size.x,
		chunk_pos.y * chunk_size.y,
		chunk_pos.z * chunk_size.z
	)
	
	# Define the 8 corners of the chunk using the Vector3 size
	var corners = [
		world_pos,  # 0: bottom-front-left
		world_pos + Vector3(chunk_size.x, 0, 0),  # 1: bottom-front-right
		world_pos + Vector3(chunk_size.x, 0, chunk_size.z),  # 2: bottom-back-right
		world_pos + Vector3(0, 0, chunk_size.z),  # 3: bottom-back-left
		world_pos + Vector3(0, chunk_size.y, 0),  # 4: top-front-left
		world_pos + Vector3(chunk_size.x, chunk_size.y, 0),  # 5: top-front-right
		world_pos + Vector3(chunk_size.x, chunk_size.y, chunk_size.z),  # 6: top-back-right
		world_pos + Vector3(0, chunk_size.y, chunk_size.z),  # 7: top-back-left
	]
	
	# Draw bottom face
	draw_line_between(corners[0], corners[1])
	draw_line_between(corners[1], corners[2])
	draw_line_between(corners[2], corners[3])
	draw_line_between(corners[3], corners[0])
	
	# Draw top face
	draw_line_between(corners[4], corners[5])
	draw_line_between(corners[5], corners[6])
	draw_line_between(corners[6], corners[7])
	draw_line_between(corners[7], corners[4])
	
	# Draw vertical edges
	draw_line_between(corners[0], corners[4])
	draw_line_between(corners[1], corners[5])
	draw_line_between(corners[2], corners[6])
	draw_line_between(corners[3], corners[7])

func draw_line_between(from: Vector3, to: Vector3):
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)

# INFO Call this when chunks are loaded/unloaded to update the grid
func on_chunks_changed():
	if grid_visible:
		update_grid()
