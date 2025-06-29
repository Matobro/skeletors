extends StateMachine

func _ready():
	add_state("idle")
	add_state("moving")
	add_state("aggroing")
	add_state("attacking")
	add_state("dying")
	add_state("attack_moving")
	call_deferred("set_state", states.idle)

func state_logic(delta): #Actual state logic, what to do in states
	#print("Player: ", parent.owner_id, " ", parent.data.name, " ", state) #print unit state, eg; "Player 1 Skeletor Idle"
	### show state over unit ###
	if parent.command_queue.size() > 0:
		parent.dev_state.text = parent.command_queue[0].type
	############################
	var command = parent.get_current_command()
	
	match state:
		states.idle:
			if command != null:
				match command.type:
					"move":
						parent.movement_target = command.position
						set_state(states.moving)
					"attack_move":
						parent.attack_move_target = command.position
						parent.is_attack_moving = true
						set_state(states.attack_moving)
						
		states.moving:
			if parent.movement_target != null:
				parent.move_to_target(parent.movement_target)
				
		states.attack_moving:
			if parent.attack_move_target != null:
				parent.move_to_target(parent.attack_move_target)
				
		states.aggroing:
			if parent.attack_target != null:
				parent.move_to_target(parent.attack_target.position)
				
		states.attacking:
			pass
			
		states.dying:
			pass

func enter_state(new_state, old_state): #mostly for animations
	match state:
		states.idle:
			pass
		states.moving:
			pass
		states.aggroing:
			pass
		states.attacking:
			pass
		states.dying:
			pass
			
func get_transition(delta): #Handle transitions, if x happens go to state y
	match state:
		states.idle:
			if parent.closest_enemy_in_aggro_range() != null:
				parent.attack_target = parent.closest_enemy_in_aggro_range()
				return states.aggroing
			return null #good to know that if you dont return null / have return value for each path it doesnt just 'stay in current state' but instead do nothing sometimes
			
		states.moving:
			if parent.movement_target != null:
				if parent.position.distance_to(parent.movement_target) < 5.0:
					parent.movement_target = null
					parent.clear_rally_point()
					parent.command_queue.pop_front()
					return states.idle
			return null
			
		states.attack_moving:
			if parent.attack_target == null:
				var target_in_aggro_range = parent.closest_enemy_in_aggro_range()
				if target_in_aggro_range != null:
					parent.attack_target = target_in_aggro_range
					return states.aggroing
			if parent.attack_move_target != null:
				if parent.position.distance_to(parent.attack_move_target) < 5.0:
					parent.attack_move_target = null
					parent.is_attack_moving = false
					parent.clear_rally_point()
					parent.command_queue.pop_front()
					return states.idle
			return null
			
		states.aggroing:
			if parent.attack_target != null:
				if parent.closest_enemy_in_attack_range() != null:
					return states.attacking
			return null
			
		states.attacking:
			if parent.attack_target != null:
				if parent.closest_enemy_in_attack_range() != null:
					return states.attacking
				return states.aggroing
			return states.idle
				
				
				
