extends Unit

class_name Heroes

func init_unit(unit_data):

    ### Hero class specific ###

    data = unit_data.duplicate()

    if data.stats is HeroStatData:
        data.stats = data.stats.duplicate()
    else:
        push_warning("Hero UnitData is wrong type (BaseStatData), should be (HeroStatData")
        data.stats = data.stats.duplicate()

    var hero_stats = data.stats as HeroStatData
    data.stats.max_health += hero_stats.get_bonus_health()
    data.stats.attack_speed += hero_stats.get_bonus_attack_speed()
    data.stats.max_mana += hero_stats.get_bonus_mana()

    ### Unit class ###
    await get_tree().process_frame
		
    animation_player.init_animations(data.unit_model_data)
    dead = false
    set_selected(false)
    aggro_collision.set_deferred("disabled", false)
    set_unit_color()
    await get_tree().process_frame
	
    init_stats()
