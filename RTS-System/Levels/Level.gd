class_name Level

var number: int
var waves: Array[Wave]
var current_wave_index: int = 0
var enemy_count: int

func _init(_number: int, _waves: Array[Wave]):
	self.number = _number
	self.waves = _waves

func get_current_wave() -> Wave:
	if current_wave_index < waves.size():
		return waves[current_wave_index]
	return null

func advance_wave() -> bool:
	current_wave_index += 1
	return current_wave_index < waves.size()

func is_completed() -> bool:
	return current_wave_index >= waves.size()