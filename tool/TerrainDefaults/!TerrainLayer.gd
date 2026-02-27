class_name TerrainLayer
extends Resource

## The name of this layer (e.g., "Surface", "Dirt", "Stone", "Bedrock")
@export var layer_name: String = "Unnamed"

## How this layer's depth is calculated
enum DepthMode{
	## Measured from top of terrain downward
	FROM_SURFACE, 
	## Measured from y=0 upward
	FROM_BOTTOM 
}

@export var depth_mode: DepthMode = DepthMode.FROM_SURFACE

## Minimum depth for this layer (inclusive)
## For FROM_SURFACE: 0 = the surface block itself
## For FROM_BOTTOM: 0 = y position 0
@export var min_depth: int = 0

## Maximum depth for this layer (inclusive)
## Set to -1 for "infinite" (no limit) [br]
## RECOMMENDATION: Always set the last layer to be infinite to avoid any generation issues
@export var max_depth: int = -1

## Priority when layers overlap (higher = checked first)
@export var priority: int = 0
