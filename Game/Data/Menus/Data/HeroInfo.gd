extends Node

class_name HeroInfo
@onready var hero_name = $HeroName
@onready var hero_icon_box = $HeroIconBox
@onready var hero_icon = $HeroIconBox/TextureRect
@onready var hero_attribute_box = $HeroAttributeBox
@onready var str_value = $HeroAttributeBox/StrValue
@onready var agi_value = $HeroAttributeBox/AgiValue
@onready var int_value = $HeroAttributeBox/IntValue
@onready var main_stat_value = $HeroMainStatBox/MainStatValue
@onready var description_value = $HeroDescription/DescriptionValue
@onready var stats_left = $HeroStats/Stats1
@onready var stats_right = $HeroStats/Stats2

var selected_hero
		
func _ready() -> void:
	var hero_list = UnitDatabase.get_hero_list()
	load_hero_info(hero_list.get(0))

func load_hero_info(hero: UnitData):
	selected_hero = hero
	var stats: HeroStatData = hero.stats
		
	hero_name.text = hero.name
	hero_icon.texture = hero.unit_model_data.get_avatar()
	str_value.text = str(stats.strength, " + ", stats.strength_per_level, " / level")
	agi_value.text = str(stats.agility, " + ", stats.agility_per_level, " / level")
	int_value.text = str(stats.intelligence, " + ", stats.intelligence_per_level, " / level")
	main_stat_value.text = get_main_stat_text(stats.main_stat)
	description_value.text = hero.description

	var damage_range = StatModifiers.get_damage_range(stats.base_damage, stats.attack_dice_roll)

	stats_left.text = str(
	"Range: ", get_range_text(hero), "\n",
	"Damage: ", damage_range[0], "-", damage_range[1], "\n",
	"A..Speed: ", stats.base_attack_speed, " atk/s\n",
	"M..Speed: ", stats.base_movement_speed, "\n",
	"Armor: ", stats.base_armor)

	stats_right.text = str(
	"HP: ", stats.base_max_hp, "\n",
	"H..Regen: ", stats.base_health_regen, "/s\n",
	"MP: ", stats.base_max_mana, "\n",
	"M..Regen: ", stats.base_mana_regen, "/s\n")

func get_range_text(data) -> String:
	if data.is_ranged:
		return str(data.stats.base_range)
	else:
		return str("Melee")

func get_main_stat_text(stat):
	match stat:
		"strength":
			return str("[color=red]", "Strength", "[/color]")
		"agility":
			return str("[color=green]", "Agility", "[/color]")
		"intelligence":
			return str("[color=cyan]", "Intelligence", "[/color]")
		_:
			return str("huh...")

func get_selected_hero() -> UnitData:
	return selected_hero
