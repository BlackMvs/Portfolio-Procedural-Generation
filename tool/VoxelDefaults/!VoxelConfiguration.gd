class_name VoxelConfiguration
extends Resource

## The name of this voxel type (for identification and debugging)
@export var voxel_name: String = "Unnamed"

## The scene to spawn for this voxel (drag and drop your cube scene here)
@export var voxel_scene: PackedScene

## Which layers this voxel can spawn in (use the layer names from WorldGenerator)
## Leave empty to use height range only (legacy mode)
@export var layer_names: Array[String] = []

## Minimum Y coordinate where this voxel can spawn
@export var min_spawn_height: int = 0

## Maximum Y coordinate where this voxel can spawn
@export var max_spawn_height: int = 64

## Chance this voxel will spawn (0.0 = never, 1.0 = always, 0.1 = 10% chance)
@export_range(0.0, 1.0) var spawn_chance: float = 1.0

## Priority for spawning (higher values spawn first when voxels overlap)
@export var priority: int = 0
