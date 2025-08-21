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
	var effective_armor = armor * armor_const
	var normalizer = (armor_const * armor) + 1
	var percentage_blocked = effective_armor / normalizer
	return percentage_blocked

## Returns actual damage
func calculate_damage(dice, damage) -> int:
	var variance = int(damage * dice)
	var roll = randi_range(-variance, variance)
	var raw_damage = damage + roll
	return clampi(raw_damage, 1, 9999)

## Returns damage in range, example [190-210]
func get_damage_range(damage: int, dice: float) -> Array:
	var variance = int(damage * dice)
	var min_damage = clamp(damage - variance, 1, 99999)
	var max_damage = clamp(damage + variance, 1, 99999)
	return [min_damage, max_damage]