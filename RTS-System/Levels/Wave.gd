class_name Wave

# max_count: how many units this wave will spawn when it starts
var max_count: int = 0
# live Unit instances currently in the world for this wave
var enemies: Array[Unit] = []

func _init(_max_count: int):
    max_count = _max_count
    enemies = []

func is_cleared() -> bool:
    # cleared when no live enemies remain
    return enemies.is_empty()

func add_enemy(enemy: Unit) -> void:
    enemies.append(enemy)

func remove_enemy(enemy: Unit) -> void:
    enemies.erase(enemy)