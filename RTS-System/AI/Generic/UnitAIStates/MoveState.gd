extends UnitState

func enter_state():
	pass

func exit_state():
	ai.command_handler.clear()
	parent.velocity = Vector2.ZERO

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
		"GiveItem":
			if is_instance_valid(cmd.target_unit):
				parent.unit_inventory.give_item(cmd["item"], cmd.target_unit.unit_inventory)
			finish_command()
		"DropItem":
			var index = cmd["item"]
			parent.unit_inventory.drop_item(index, cmd.target_position)
			finish_command()
		"PickUpItem":
			if is_instance_valid(cmd["item"]) and parent.unit_inventory.is_space_in_inventory():
				parent.unit_inventory.add_item(cmd["item"].item)
				cmd["item"].queue_free()
			finish_command()
		"Move":
			finish_command()
		_:
			finish_command()

func finish_command():
	ai.command_handler.process_next_command()
