extends Unit

class_name Hero

func _data_received():
	data.stats = data.stats.duplicate() as HeroStatData
	data.hero = self

	unit_inventory = UnitInventory.new(self)
	add_child(unit_inventory)

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
