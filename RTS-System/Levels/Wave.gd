class_name Wave

var enemies: Array[UnitData] = []

func _init(_enemies: Array[UnitData]):
	self.enemies = _enemies

func is_cleared() -> bool:
	for enemy in enemies:
		if enemy and enemy.stats.is_alive():
			return false
	return true