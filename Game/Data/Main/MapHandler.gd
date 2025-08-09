extends Node

@onready var tile_map = get_tree().root.get_node("World/Map")

@export var tile_size = null
@export var used_cells = null
@export var pixel_size = null
@export var mat = null

func _ready():
	tile_size = Vector2(80, 80)
	used_cells = tile_map.get_used_rect()
	pixel_size = tile_size * Vector2(used_cells.size.x, used_cells.size.y)
	mat = tile_map.material
