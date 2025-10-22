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
			var target = find_closest_enemy(unit)
			#validation hell, todo
			if target and is_instance_valid(target) and target.unit_combat and !target.unit_combat.dead and is_instance_valid(unit) and unit.unit_ai and (unit.unit_ai.state == "Idle"):
				unit.command_holder.issue_command("Attack_move", target, target.global_position, false, 10, false)

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
