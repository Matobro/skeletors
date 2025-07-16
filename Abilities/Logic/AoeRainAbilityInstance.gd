extends Node2D

var abiliy_config: AoeRainAbility
var world_node : Node
var _owner: Node

var waves_remaining: int
var wave_timer : Timer

func setup(config: AoeRainAbility, pos: Vector2, world: Node, owner_node: Node):
    abiliy_config = config
    position = pos
    world_node = world
    _owner = owner_node

    waves_remaining = abiliy_config.wave_count

    wave_timer = Timer.new()
    wave_timer.wait_time = abiliy_config.duration / abiliy_config.wave_count
    wave_timer.one_shot = false
    add_child(wave_timer)
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
    var targets = abiliy_config.get_targets_in_area(position, abiliy_config.area_radius, world_node)
    for target in targets:
        ##if check ally orsomething
            ##continue

        var damage = abiliy_config.damage_per_wave
        target.take_damage(damage)

        #if abiliy_config.effect_debuff != null:
            #target.apply.effect(abiliy_config.effect_debuff)

func spawn_effect():
    if abiliy_config.effect_scene != null:
        var effect = abiliy_config.effect_scene.instantiate()
        effect.global_position = position
        world_node.add_child(effect)

