extends UnitState

func enter_state():
	pass

func exit_state():
	ai.command_handler.clear()
	parent.velocity = Vector2.ZERO
	SpatialGrid.update_unit_position(parent)

func state_logic(delta):
	if ai.get_current_command() == {}:
		ai.set_state("Idle")
		return

	if ai.pathfinder.path.size() > 0 and ai.pathfinder.path_index >= ai.pathfinder.path.size():
		on_arrival()
		
	ai.pathfinder.follow_path(delta)


func on_arrival():
	var cmd = ai.get_current_command()

	match cmd["type"]:
		"GiveItem", "DropItem", "PickUpItem":
			_process_item_command(cmd)
		"Move":
			finish_command()
		_:
			finish_command()

func _process_item_command(cmd: Dictionary):
	match cmd["type"]:
		"GiveItem":
			if is_instance_valid(cmd.target_unit):
				if parent.global_position.distance_to(cmd.target_unit.global_position) <= 100:
					parent.unit_inventory.give_item(cmd["item"], cmd.target_unit.unit_inventory)
					finish_command()
				else:
					cmd["target_position"] = cmd["target_unit"].global_position
					ai.pathfinder.request_path()
			else:
				finish_command()

		"DropItem":
			if parent.global_position.distance_to(cmd.target_position) <= 100:
				var index = cmd["item"]
				parent.unit_inventory.drop_item(index, cmd.target_position)
				finish_command()
			else:
				ai.pathfinder.request_path()

		"PickUpItem":
			if is_instance_valid(cmd["item"]) and parent.unit_inventory and parent.unit_inventory.is_space_in_inventory():
				if parent.global_position.distance_to(cmd["item"].global_position) <= 100:
					parent.unit_inventory.add_item(cmd["item"].item)
					cmd["item"].queue_free()
					finish_command()
				else:
					ai.pathfinder.request_path()
			else:
				finish_command()

func finish_command():
	ai.combat_state.clear_combat_state()
	ai.command_handler.process_next_command()
