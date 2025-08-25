extends Node

var unit: Unit

var update_speed = 5
var current_frame = 0
@onready var hp_bar = $HpBar
@onready var avatar = $Avatar
@onready var box = $Box

func init_unit(unit_ref):
	unit = unit_ref

	if self.unit is Hero:
		var style = box.get("theme_override_styles/panel")
		style.border_color = Color.WHITE

	avatar.texture = unit.data.unit_model_data.get_avatar()

	hp_bar.max_value = unit.data.stats.max_health
	hp_bar.value = unit.data.stats.current_health
		
func _process(_delta: float) -> void:
	current_frame += 1
	if unit == null or !is_instance_valid(unit) or unit.unit_combat.dead:
		return

	if current_frame > update_speed:
		current_frame = 0
		hp_bar.max_value = unit.data.stats.max_health
		hp_bar.value = unit.data.stats.current_health
