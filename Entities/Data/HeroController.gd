extends Unit

class_name Hero

func init_unit(unit_data):

	### Hero class specific ###

	data = unit_data.duplicate()

	if data.stats is HeroStatData:
		data.stats = data.stats.duplicate()
	else:
		push_warning("Hero UnitData is wrong type (BaseStatData), should be (HeroStatData")
		data.stats = data.stats.duplicate()

	var hero_stats = data.stats as HeroStatData
	data.hero = self
	data.stats.max_health += hero_stats.get_bonus_health()
	data.stats.attack_speed += hero_stats.get_bonus_attack_speed()
	data.stats.max_mana += hero_stats.get_bonus_mana()
	data.stats.attack_damage += hero_stats.get_bonus_attack_damage()

	### Unit class ###
	await get_tree().process_frame
		
	animation_player.init_animations(data.unit_model_data)
	dead = false
	set_selected(false)
	aggro_collision.set_deferred("disabled", false)
	set_unit_color()
	await get_tree().process_frame
	
	init_stats()

func get_xp(amount):
	data.stats.xp += amount
	while data.stats.xp >= get_xp_for_level(data.stats.level + 1):
		data.stats.level += 1
		level_up()

func get_xp_progress_ratio() -> float:
	var current_xp = data.stats.xp - get_xp_for_current_level()
	var required_xp = get_xp_for_next_level() - get_xp_for_current_level()
	if required_xp == 0:
		return 1.0
	return clamp(float(current_xp) / float(required_xp), 0.0, 1.0)

func get_xp_for_current_level() -> int:
	return get_xp_for_level(data.stats.level)

func get_xp_for_next_level() -> int:
	return get_xp_for_level(data.stats.level + 1)

func get_xp_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 0
	return round(100 * pow(lvl, 1.5))

func level_up():
	pass
