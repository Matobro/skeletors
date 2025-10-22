extends Node

class_name PlayerCommandIssuer

var parent: PlayerInput
var selection_manager: SelectionManager
var id

func _init(parent_ref, selection_manager_ref, id_ref) -> void:
	parent = parent_ref
	selection_manager = selection_manager_ref
	id = id_ref

func issue_stop_command(event_info):
	if selection_manager.selected_units.size() <= 0:
		return

	for unit in selection_manager.selected_units:
		unit.command_holder.issue_command("Stop", event_info.click_target, event_info.clicked_position, event_info.shift, id, true)

func issue_hold_command(event_info):
	if selection_manager.selected_units.size() <= 0:
		return

	for unit in selection_manager.selected_units:
		unit.command_holder.issue_command("Hold", event_info.click_target, event_info.clicked_position, event_info.shift, id, true)
	
func issue_attack_command(event_info):
	print("attacking")
	if selection_manager.selected_units.size() <= 0:
		return

	for unit in selection_manager.selected_units:
		if unit != event_info.click_target:
			unit.command_holder.issue_command("Attack", event_info.click_target, event_info.clicked_position, event_info.shift, id, true)
	
func issue_attack_move_command(event_info):
	print("attack moving")
	if selection_manager.selected_units.size() <= 0:
		return

	var formation = calculate_unit_formation(event_info.total_units, event_info.clicked_position)
	for i in range (selection_manager.selected_units.size()):
		var unit = selection_manager.selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"Attack_move",
			event_info.click_target,
			target_pos,
			event_info.shift,
			id,
			true
		)

	parent.command_cooldown_frames = parent.COMMAND_COOLDOWN
	
func issue_move_command(event_info):
	if selection_manager.selected_units.size() <= 0:
		return

	var formation = calculate_unit_formation(event_info.total_units, event_info.clicked_position)
	for i in range (selection_manager.selected_units.size()):
		var unit = selection_manager.selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"Move",
			null,
			target_pos,
			event_info.shift,
			id,
			true
		)

	parent.command_cooldown_frames = parent.COMMAND_COOLDOWN

func issue_drop_item_command(event_info, slot_index):
	if selection_manager.selected_units.size() <= 0:
		return
	
	var formation = calculate_unit_formation(event_info.total_units, event_info.clicked_position)
	for i in range (selection_manager.selected_units.size()):
		var unit = selection_manager.selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"DropItem",
			null,
			target_pos,
			event_info.shift,
			id,
			true,
			Vector2.ZERO,
			{"item": slot_index}
		)

	parent.command_cooldown_frames = parent.COMMAND_COOLDOWN

func issue_give_item_command(event_info, item: ItemData):
	if selection_manager.selected_units.size() <= 0:
		return
	
	var formation = calculate_unit_formation(event_info.total_units, event_info.clicked_position)
	for i in range (selection_manager.selected_units.size()):
		var unit = selection_manager.selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"GiveItem",
			event_info.click_target,
			target_pos,
			event_info.shift,
			id,
			true,
			Vector2.ZERO,
			{"item": item}
		)

	parent.command_cooldown_frames = parent.COMMAND_COOLDOWN

func issue_pickup_item_command(event_info):
	if selection_manager.selected_units.size() <= 0:
		return
	
	var formation = calculate_unit_formation(event_info.total_units, event_info.clicked_position)
	for i in range (selection_manager.selected_units.size()):
		var unit = selection_manager.selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"PickUpItem",
			null,
			target_pos,
			event_info.shift,
			id,
			true,
			Vector2.ZERO,
			{"item": event_info.click_item}
		)

	parent.command_cooldown_frames = parent.COMMAND_COOLDOWN

func issue_cast_ability_command(context: CastContext):
	# Check if cast if valid before issuing command
	if !context.ability.can_cast(context):
		print("Cast ability command issuing cancelled")
		return

	print("Issuing cast ability command")
	context.caster.command_holder.issue_command(
		"CastAbility",
		context.target_unit,
		context.target_position,
		context.shift,
		context.caster.owner_id,
		true,
		Vector2.ZERO,
		{"context": context}
	)

func calculate_unit_formation(total_units, pos):
	if total_units == 1:
		return [pos]
	var unit_targets := []
	var spacing := 82.0
	var columns = int(ceil(sqrt(total_units)))
	var rows := int(ceil(total_units / float(columns)))
	
	var total_width = (columns - 1) * spacing
	var total_height = (rows - 1) * spacing
	
	for i in range(total_units):
		var row = float(i) / columns
		var column: int = i % columns
		
		var offset := Vector2(
			column * spacing - total_width / 2,
			row * spacing - total_height / 2
		)
		
		offset += Vector2(randf_range(-20, 20), randf_range(-20, 20))
		unit_targets.append(pos + offset)
	
	return unit_targets
