extends Node2D

var unit_slot = preload("res://Entities/Units/Data/UnitSlot.tscn")
@onready var portrait = $Portrait/AnimatedSprite2D
@onready var portrait_box = $Portrait
@onready var name_label = $UnitStats/Name
@onready var xp_bar = $HeroStats/XpBar
@onready var damage_label = $UnitStats/DamageValue
@onready var str_label = $HeroStats/StrValue
@onready var agi_label = $HeroStats/AgiValue
@onready var int_label = $HeroStats/IntValue
@onready var armor_label = $UnitStats/ArmorValue
@onready var hp_bar = $Control/HpBar
@onready var hp_bar_label = $Control/HpValue
@onready var mana_bar = $Control/ManaBar
@onready var mana_bar_label = $Control/ManaValue
@onready var hero_stats = $HeroStats
@onready var unit_stats = $UnitStats
@onready var level_label = $HeroStats/Level
@onready var current_control_group = $CurrentControlGrid

var control_group_array = []
var ui_hidden = false
var current_data: UnitData
var update_speed = 15
var current_frame = 0

func _ready():
	show_stats(false)
	check_group()
	hero_stats.visible = false
	
func _process(_delta: float) -> void:
	current_frame += 1
	if current_frame > update_speed:
		current_frame = 0
		update_ui()

func add_unit_to_control(unit):
	var instance = unit_slot.instantiate()
	var port = unit.data.avatar.get_frame_texture("idle", 0)
	instance.unit = unit
	current_control_group.add_child(instance)
	instance.init_unit(port)
	control_group_array.append(instance)
	if control_group_array and control_group_array[0].unit == unit:
		update_unit_ui(unit.data)
	else:
		update_ui()

func check_group():
	var units = control_group_array.size()
	if units > 1:
		show_stats(false)
		portrait.visible = true
		current_control_group.visible = true
		show_bars(true)
	elif units > 0:
		portrait.visible = true
		show_stats(true)
		current_control_group.visible = false
		show_bars(true)
	else:
		portrait.visible = false
		show_stats(false)
		show_bars(false)
		current_control_group.visible = false
		
func remove_unit_from_group(unit):
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
	
func update_ui():
	update_unit_ui(current_data)

func fit_portrait():
	var frame_texture = portrait.sprite_frames.get_frame_texture("idle", 0)
	var frame_size = frame_texture.get_size()
	
	var scale_ratio = portrait_box / frame_size
	var final_scale = min(scale_ratio.x, scale_ratio.y)
	portrait.scale = Vector2.ONE * final_scale
	
func update_unit_ui(data):
	if data == null:
		current_data = null
		check_group()
		return

	check_group()
	current_data = data
	var stats = data.stats
	match data.unit_type:
		"unit":
			hero_stats.visible = false
		"hero":
			hero_stats.visible = true
			str_label.text = str(stats.strength)
			agi_label.text = str(stats.agility)
			int_label.text = str(stats.intelligence)
			
	portrait.sprite_frames = data.avatar
	portrait.play("idle")
	
	name_label.text = data.name
	var fixed_damage = get_damage(stats)
	damage_label.text = str(fixed_damage[0], "-" , fixed_damage[1])
	armor_label.text = str(stats.armor)
	hp_bar.max_value = stats.max_health
	var hp = clamp(stats.current_health, 0, 9999)
	hp_bar.value = stats.current_health
	hp_bar_label.text = str(hp, "/", stats.max_health)
	mana_bar.max_value = stats.max_mana
	mana_bar.value = stats.current_mana
	mana_bar_label.text = str(stats.current_mana, "/", stats.max_mana)

func get_damage(data):
	var damage = data.attack_damage
	var dice = data.attack_dice_roll
	var _min = damage - dice
	var _max = damage + dice
	var clamp_min = clamp(_min, 1, 9999)
	var arr = [clamp_min, _max]
	return arr
