extends Node

var unit: Unit

var update_speed = 5
var current_frame = 0
@onready var hp_bar = $HpBar
@onready var avatar = $Avatar

func init_unit(unit_ref):
	unit = unit_ref
	avatar.texture = unit.data.avatar

	hp_bar.max_value = unit.data.stats.max_health
	hp_bar.value = unit.data.stats.current_health
		
func _process(_delta: float) -> void:
	current_frame += 1
	if current_frame > update_speed:
		current_frame = 0
		hp_bar.max_value = unit.data.stats.max_health
		hp_bar.value = unit.data.stats.current_health
