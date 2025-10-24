extends Node

var current_level: Level

var _wave_increment: int = 2
var _enemy_increment: int = 3

func start_game():
	current_level = Level.new(1, 3, 10)
	print("Game started! " + current_level.describe())


func next_level():
	var next_number = current_level.number + 1
	var next_waves = current_level.wave_count + _wave_increment
	var next_enemies = current_level.enemy_count + _enemy_increment

	current_level = Level.new(next_number, next_waves, next_enemies)
