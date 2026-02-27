## Automatically calculated from world generator settings.
## Enemies unload at the same distance as chunks, so they always
## disappear together rather than at mismatched distances.
var enemy_unload_distance : float:
	get:
		if not world_generator:
			return 200.0  # fallback if called before world_generator is set
		return (world_generator.render_distance
			* world_generator.chunk_size_x  # assuming square chunks 
			* world_generator.voxel_size)
