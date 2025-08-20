extends Node

var str_multiplier: int = 2
var agi_multiplier: float = 0.01
var int_multiplier: int = 2
var main_stat_multiplier: float = 2.0
var regen_modifier: float = 0.06
var armor_modifier: float = 5.0
var armor_const: float = 0.06

var movement_speed_animation_modifier: float = 3.0

func calculate_armor(armor):
	var x = armor * armor_const
	var y = (armor_const * armor) + 1
	var result = x / y
	return result

func calculate_damage(dice, damage) -> int:

	var dice_roll = randi_range(-dice, dice)
	var result = damage + dice_roll
	var final_damage = clampi(result, 1, 9999)

	return final_damage