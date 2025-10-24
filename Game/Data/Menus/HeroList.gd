extends Panel

class_name HeroList
@onready var hero_slot_scene = preload("res://Game/Data/Menus/Data/HeroSlot.tscn")
@onready var grid_container = $ScrollContainer/GridContainer
@onready var hero_info = $"../HeroInfoPanel"

func _ready() -> void:
	populate_hero_list_ui(UnitDatabase.get_hero_data())
	
func populate_hero_list_ui(hero_list: Array[UnitData]):
	if hero_list.size() <= 0:
		print("Hero list is empty.")
		return
		
	for hero in hero_list:
		var hero_slot = hero_slot_scene.instantiate()
		hero_slot.setup(hero)
		grid_container.add_child(hero_slot)

		hero_slot.connect("pressed", Callable(self, "on_hero_clicked").bind(hero_slot.hero))

func on_hero_clicked(data: UnitData):
	hero_info.load_hero_info(data)
