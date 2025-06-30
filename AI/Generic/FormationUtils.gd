extends Node

func get_staggered_attack_position(index: int, target_pos: Vector2, radius: float) -> Vector2:
	var angle = (PI * 2 / 8) * index 
	return target_pos + Vector2(cos(angle), sin(angle)) * radius
