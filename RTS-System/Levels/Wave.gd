class_name Wave

var enemies: Array[Unit] = []

func _init(_enemies: Array[Unit]):
	self.enemies = _enemies

func is_cleared() -> bool:
	return enemies.is_empty()

func remove_enemy(enemy: Unit) -> void:
	enemies.erase(enemy)