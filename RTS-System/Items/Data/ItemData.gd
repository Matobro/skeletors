extends Resource

class_name ItemData

@export var id: String
@export var name: String
@export var description: String
@export var icon: Texture2D
@export var cost: int
@export var category: String = "Misc"
@export var is_consumable: bool = false
@export var stats: ItemStatData
