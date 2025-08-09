extends Node2D

var ability_config: AoeRainAbility
var world_node : Node
var _owner: Node

var waves_remaining: int
var wave_timer : Timer

var area_indicator: Node2D

func setup(config: AoeRainAbility, pos: Vector2, world: Node, owner_node: Node):
	ability_config = config
	position = pos
	world_node = world
	_owner = owner_node

	waves_remaining = ability_config.wave_count

	area_indicator = ability_config.AreaIndicator.instantiate()
	area_indicator.position = position
	area_indicator.radius = ability_config.area_radius
	area_indicator.lifetime = ability_config.duration
	print(area_indicator.radius)
	ParticleManager.add_child(area_indicator)

	wave_timer = Timer.new()
	wave_timer.wait_time = ability_config.duration / ability_config.wave_count
	wave_timer.one_shot = false
	ParticleManager.add_child(wave_timer)
	wave_timer.timeout.connect(_on_wave_timeout)
	wave_timer.start()

func _on_wave_timeout():
	if waves_remaining <= 0:
		wave_timer.stop()
		queue_free()
		return
	
	perform_wave()
	waves_remaining -= 1

	if waves_remaining <= 0:
		wave_timer.stop()
		queue_free()

func perform_wave():
	var targets = ability_config.get_targets_in_area(position, ability_config.area_radius, world_node)
	
	if ability_config.fx:
		var _scale = ability_config.area_radius / 32
		var _radius = ability_config.area_radius
		ParticleManager.play_fx(ability_config.fx, position, _scale, _radius)
	
	for target in targets:
		##if check ally orsomething
			##continue

		print("hit ", target)
		var damage = ability_config.damage_per_wave
		target.take_damage(damage)

		#if ability_config.effect_debuff != null:
			#target.apply.effect(ability_config.effect_debuff)
