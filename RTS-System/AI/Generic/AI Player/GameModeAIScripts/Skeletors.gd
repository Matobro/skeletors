extends AIScriptBase

var controller
var check_timer = AI_LOGIC_SPEED

const AI_LOGIC_SPEED = 1.0

func start(controller_ref):
    controller = controller_ref
    check_timer = AI_LOGIC_SPEED

func update(delta):
    check_timer -= delta
    if check_timer <= 0:
        check_timer = AI_LOGIC_SPEED

        var units = UnitHandler.get_units_by_player(10)
        for unit in units:
            if unit.is_ready:
                var target = find_closest_enemy(unit)
                if target and is_instance_valid(target) and (unit.state_machine.state == "Idle" or unit.state_machine.state == "Move"):
                    unit.command_component.issue_command("Attack", target, target.global_position, false, 10)

func find_closest_enemy(unit) -> Unit:
    var all_units = UnitHandler.all_units
    var closest = null
    var min_dist = INF

    for u in all_units:
        if u.owner_id == 10:
            continue
        var d = unit.global_position.distance_to(u.global_position)
        if d < min_dist:
            min_dist = d
            closest = u

    return closest