extends Node2D

#######################################################
#######################################################
###                                                 ###
###                                                 ###
###                                                 ###
###                                                 ###
### I DONT WANT TO TOUCH THIS SHIT EVER AGAIN       ###
### 17/07/2025                                      ###
### MATO                                            ###
### FUUUUUUUU I HAD TO TOUCH THIS (xp bar)          ###
###                                                 ###
### 06/08                                           ###
### MATO                                            ###
### NOOOOOOO AGAIIIIN                               ###
###                                                 ###
###                                                 ###
#######################################################
#######################################################

var unit_slot = preload("res://RTS-System/Entities/Data/UnitSlot.tscn")
@onready var portrait = $Portrait/AnimatedSprite2D
@onready var portrait_box = $Portrait
@onready var portrait_panel = $PortraitPanel
var portrait_stylebox = null
@onready var name_label = $UnitStats/Name
@onready var xp_bar = $HeroStats/XpBar
@onready var hp_bar = $Control/HpBar
@onready var hp_bar_label = $Control/HpValue
@onready var mana_bar = $Control/ManaBar
@onready var mana_bar_label = $Control/ManaValue
@onready var hero_stats = $HeroStats
@onready var unit_stats = $UnitStats
@onready var level_label = $HeroStats/Level
@onready var current_control_group = $CurrentControlGrid

@onready var stat_names = {
	"damage": $UnitStats/Damage,
	"armor": $UnitStats/Armor,
	"str": $HeroStats/Str,
	"agi": $HeroStats/Agi,
	"int": $HeroStats/Int,
	"xp_bar": $HeroStats/XpBar,
	"hp_bar": $Control/HpBar,
	"mp_bar": $Control/ManaBar
}
@onready var stat_labels = {
	"damage": $UnitStats/DamageValue,
	"armor": $UnitStats/ArmorValue,
	"str": $HeroStats/StrValue,
	"agi": $HeroStats/AgiValue,
	"int": $HeroStats/IntValue,
}
@onready var ability_buttons = [
	$ActionMenu/GridContainer/AbilityButton0,
	$ActionMenu/GridContainer/AbilityButton1,
	$ActionMenu/GridContainer/AbilityButton2,
	$ActionMenu/GridContainer/AbilityButton3,
	$ActionMenu/GridContainer/AbilityButton4,
	$ActionMenu/GridContainer/AbilityButton5,
	$ActionMenu/GridContainer/AbilityButton6,
	$ActionMenu/GridContainer/AbilityButton7,
]

var og_color = null
var control_group_array = []
var ui_hidden = false
var current_data: UnitData
var update_speed = 5
var current_frame = 0
var parent = null

func _ready():
	for stat_name in stat_names.keys():
		var label = stat_names[stat_name]
		label.connect("mouse_entered", Callable(self, "_on_stat_hover_entered").bind(stat_name))
		label.connect("mouse_exited", Callable(self, "_on_stat_hover_exited"))
		
func init_node():
	portrait_stylebox = portrait_panel.get("theme_override_styles/panel")
	og_color = portrait_stylebox.bg_color
	show_stats(false)
	check_group()
	hero_stats.visible = false
	
func _process(_delta: float) -> void:
	current_frame += 1
	if current_frame > update_speed:
		current_frame = 0
		check_group()

##########################################################
### CONTROL GROUP LOGIC ##################################
##########################################################

func add_unit_to_control(unit):
	var instance = unit_slot.instantiate()
	var port = unit.data.avatar.get_frame_texture("idle", 0)
	instance.unit = unit
	current_control_group.add_child(instance)
	instance.init_unit(port)
	control_group_array.append(instance)

func remove_unit_from_control(unit):
	var next_unit = get_next_in_group()
	var was_first = null
	if control_group_array.size() > 0 and is_instance_valid(control_group_array[0]):
		if control_group_array[0].unit == unit:
			was_first = true
	
	for i in control_group_array.size():
		if control_group_array[i] and control_group_array[i].unit == unit:
			control_group_array.remove_at(i)
			break
			
	for child in current_control_group.get_children():
		if child.unit == unit:
			child.queue_free()
			break
	
	if was_first and next_unit != null:
		update_unit_ui(next_unit.data)
	
func get_next_in_group():
	var x = 0
	for i in control_group_array.size():
		if is_instance_valid(control_group_array[i]):
			x += 1
			if x > 1:
				var unit = control_group_array[i].unit
				return unit

	return null

func clear_control_group():
	for unit in control_group_array:
		if unit != null:
			unit.queue_free()
			
	control_group_array.clear()
	show_stats(false)

##############################################################
### CONTROL GROUP LOGIC END ##################################
##############################################################

##############################################################
### UI LOGIC #################################################
##############################################################

func hide_all_ui():
	current_data = null
	hero_stats.visible = false
	unit_stats.visible = false
	portrait.visible = false
	current_control_group.visible = false
	show_bars(false)
	ui_hidden = true
	if portrait_stylebox:
		portrait_stylebox.bg_color = og_color

func show_single_unit(unit):
	current_data = unit.data

	current_control_group.visible = false
	portrait.visible = true
	show_bars(true)
	ui_hidden = false

	update_unit_ui(current_data)

func show_control_group():
	current_data = control_group_array[0].unit.data
	hero_stats.visible = false
	unit_stats.visible = false
	portrait.visible = true
	current_control_group.visible = true
	show_bars(true)
	ui_hidden = true

	update_unit_ui(current_data)

func check_group():
	var units = control_group_array.size()
	#If more than 1 unit selected
	if units > 1:
		show_control_group()
	#If one selected
	elif units == 1 and is_instance_valid(control_group_array[0]):
		show_single_unit(control_group_array[0].unit)
	#If nothing selected
	else:
		hide_all_ui()
		
func show_stats(value):
	unit_stats.visible = value
	hp_bar.visible = value
	hp_bar_label.visible = value
	mana_bar.visible = value
	mana_bar_label.visible = value
	ui_hidden = !value

func show_bars(value):
	hp_bar.visible = value
	hp_bar_label.visible = value
	mana_bar.visible = value
	mana_bar_label.visible = value

func fit_portrait():
	var frame_texture = portrait.sprite_frames.get_frame_texture("idle", 0)
	var frame_size = frame_texture.get_size()
	
	var scale_ratio = portrait_box / frame_size
	var final_scale = min(scale_ratio.x, scale_ratio.y)
	portrait.scale = Vector2.ONE * final_scale

########################################################################
### UI LOGIC END #######################################################
########################################################################

func update_unit_ui(data):
	if data == null:
		return

	var stats = data.stats

	#Switch between unit-hero ui
	if !ui_hidden:
		match data.unit_type:
			"unit":
				unit_stats.visible = true
				hero_stats.visible = false
			"neutral": 
				unit_stats.visible = true
				hero_stats.visible = false
			"hero":
				unit_stats.visible = true
				hero_stats.visible = true
				stat_labels["str"].text = str(stats.strength)
				stat_labels["agi"].text = str(stats.agility)
				stat_labels["int"].text = str(stats.intelligence)
				xp_bar.max_value = data.hero.get_xp_for_next_level() - data.hero.get_xp_for_current_level()
				xp_bar.value = data.stats.xp - data.hero.get_xp_for_current_level()
				level_label.text = str(stats.level)
				
	portrait.sprite_frames = data.avatar
	portrait.play("idle")
	var portrait_color = PlayerManager.get_player_color(data.parent.owner_id)
	var faded_color = portrait_color.lerp(og_color, 0.75)
	portrait_stylebox.bg_color = faded_color

	name_label.text = data.name

	var fixed_damage = get_damage(stats)
	stat_labels["damage"].text = str(fixed_damage[0], "-" , fixed_damage[1])

	stat_labels["armor"].text = str(stats.armor)

	hp_bar.max_value = stats.max_health

	var hp = clamp(stats.current_health, 0, 99999)
	hp_bar.value = stats.current_health
	hp_bar_label.text = str(int(hp), "/", int(stats.max_health))

	mana_bar.max_value = stats.max_mana
	mana_bar.value = stats.current_mana
	mana_bar_label.text = str(int(stats.current_mana), "/", int(stats.max_mana))

	for i in ability_buttons.size():
		var button = ability_buttons[i]
		if i < data.parent.abilities.size():
			button.visible = true
			button.setup(data.parent.abilities[i], data.parent, i)
		else:
			button.visible = false

func get_damage(data):
	var damage = data.attack_damage
	var dice = data.attack_dice_roll
	var _min = damage - dice
	var _max = damage + dice
	var clamp_min = clamp(_min, 1, 999999)
	var arr = [clamp_min, _max]
	return arr

func gather_stat_info(data, stat_name):
	var main_stat = ""
	if data.unit_type == "hero":
		main_stat = data.stats.main_stat
	match stat_name:
		"damage":
			var damage_range = get_damage(data.stats)
			return str("Damage: %d - %d" % [damage_range[0], damage_range[1]], "\n",
			"\nAttacks per second : ", data.stats.attack_speed)
		"armor":
			return str("Armor: ", data.stats.armor, "\n",
			"\nDamage reduced by: ", int(StatModifiers.calculate_armor(data.stats.armor) * 100), "%\n",
			"\nMovement speed: ", data.stats.movement_speed)
		"str":
			if main_stat == "strength":
				return str("Strength: ", data.stats.strength, "\n",
				"\nEvery ", StatModifiers.main_stat_multiplier, " strength increases damage by 1. \n",
				"\nHealth is increased by ", StatModifiers.str_multiplier, " for every strength.\n",
				"\nHealth regeneration is increased by ", StatModifiers.regen_modifier, " for every strength.")
			else:
				return str("Strength: ", data.stats.strength, "\n",
				"\nHealth is increased by ", StatModifiers.str_multiplier, " for every strength.\n",
				"\nHealth regeneration is increased by ", StatModifiers.regen_modifier, " for every strength.")
		"agi":
			if main_stat == "agility":
				return str("Agility: ", data.stats.agility, "\n",
				"\nEvery ", StatModifiers.main_stat_multiplier, " agility increases damage by 1. \n",
				"\nAttack speed is increased by ", StatModifiers.agi_multiplier, " for every agility.\n",
				"\nEvery ", StatModifiers.armor_modifier, " agility increases armor by 1")
			else:	
				return str("Agility: ", data.stats.agility, "\n",
				"\nAttack speed is increased by ", StatModifiers.agi_multiplier, " for every agility. \n",
				"\nEvery ", StatModifiers.armor_modifier, " agility increases armor by 1") 
		"int":
			if main_stat == "intelligence":
				return str("Intelligence: ", data.stats.intelligence, "\n",
				"\nEvery ", StatModifiers.main_stat_multiplier, " intelligence increases damage by 1. \n",
				"\nMana is increased by ", StatModifiers.int_multiplier, " for every intelligence.\n",
				"\nMana regeneration is increased by ", StatModifiers.regen_modifier, " for every intelligence.")
			else:	
				return str("Intelligence: ", data.stats.intelligence, "\n",
				"\nMana is increased by ", StatModifiers.int_multiplier, " for every intelligence.\n",
				"\nMana regeneration is increased by ", StatModifiers.regen_modifier, " for every intelligence.")
		"xp_bar":
			return str("--------------------[" ,data.stats.xp, " / ", data.parent.get_xp_for_next_level(), "]--------------------")
		"hp_bar":
			return str("Health regeneration: ", data.stats.health_regen, "/s")
		"mp_bar":
			return str("Mana regeneration: ", data.stats.mana_regen, "/s")
		_:
			return ""

func _on_stat_hover_entered(stat_name):
	var label = stat_names[stat_name]
	var text = gather_stat_info(current_data, stat_name)

	TooltipManager.show_tooltip(parent.player_id, text, label.global_position)
	
func _on_stat_hover_exited():
	TooltipManager.hide_tooltip(parent.player_id)
