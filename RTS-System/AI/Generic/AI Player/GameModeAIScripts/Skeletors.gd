extends AIScriptBase

var controller
var check_timer: float = 0.0

var ai_units: Array
var unit_index: int = 0

const AI_LOGIC_SPEED: float = 0.1

func start(controller_ref):
	controller = controller_ref
	check_timer = AI_LOGIC_SPEED
	unit_index = 0

func update(delta):
	check_timer -= delta
	if check_timer > 0:
		return

	check_timer = AI_LOGIC_SPEED

	# Refresh units
	if ai_units.is_empty() or unit_index >= ai_units.size():
		ai_units = UnitHandler.get_units_by_player(10)
		unit_index = 0
		if ai_units.is_empty():
			return
	
	var unit = ai_units[unit_index]
	unit_index += 1

	if !is_valid_unit(unit):
		return
	
	var target = find_closest_enemy(unit)
	if unit.unit_ai and (unit.unit_ai.state == "Idle" or unit.unit_ai.state == "Attack_move"):
		# Attack move to nearest target pos
		if is_valid_unit(target):
			var pos = get_position_for_command(target.global_position)
			unit.command_holder.issue_command("Attack_move", null, pos, false, 10, true)
		# Attack move to center of map
		else:
			unit.command_holder.issue_command("Attack_move", null, Vector2.ZERO, false, 10, false)

func is_valid_unit(unit) -> bool:
	if !unit or !is_instance_valid(unit) or !unit.unit_combat or unit.unit_combat.dead or !is_instance_valid(unit):
		return false
	return true

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

func get_position_for_command(pos) -> Vector2:
	var desired_cell = SpatialGrid.grid_manager._get_cell_coords(pos)
	var free_cell = SpatialGrid.astar_manager._get_nearest_spawnable_cell(desired_cell)
	var command_pos = SpatialGrid.grid_manager.cell_center_to_world(free_cell)
	return command_pos
