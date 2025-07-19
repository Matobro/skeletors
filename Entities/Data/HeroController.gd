extends Unit

class_name Hero

func init_unit(unit_data):

	### Hero class specific ###

	data = unit_data.duplicate()

	if data.stats is HeroStatData:
		data.stats = data.stats.duplicate()
	else:
		push_warning("Hero Stats is wrong type (BaseStatData), should be (HeroStatData")
		data.stats = data.stats.duplicate()

	data.hero = self
	data.stats.recalculate_stats()
	### Unit class ###
	await get_tree().process_frame

	animation_library.add_animation_library("animations", data.unit_library)	
	animation_player.init_animations(data.unit_model_data)
	state_machine.animation_player = animation_player
	state_machine.animation_library = animation_library
	dead = false
	set_selected(false)
	aggro_collision.set_deferred("disabled", false)
	set_unit_color()
	push_min_distance = 16 * (data.unit_model_data.scale.y)
	push_mass = data.unit_model_data.scale.y * data.unit_model_data.extra_mass
	await get_tree().process_frame

	max_push_checks = 5
	state_machine.set_ready()
	hp_bar.init_hp_bar(data.stats.current_health, data.stats.max_health)

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
	data.stats.gain_stats(data.stats.strength_per_level, data.stats.agility_per_level, data.stats.intelligence_per_level)
