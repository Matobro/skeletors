extends StateMachine

###################################################################################
#Unit intended behaviour:
#1. if idle, aka no player input/issued commands -> aggro if enemy comes on range
#2. commands override every action/state 
#3. aggro -> move to attack range of CLOSEST FIRST enemy, once unit aggroes,
# it doesnt change the target anymore, if another unit comes closer just ignore it
#4. once aggroed unit dies, go back to issued command, for example if it was attack move
# return to attack move, if no command aka was idle, go back to where you were idling
#5. if idling and unit attacks (out of aggro range) -> aggro that target
####################################################################################

func set_ready():
	initialized = true
	add_state("idle")
	add_state("moving")
	add_state("aggroing")
	add_state("attacking")
	add_state("dying")
	add_state("attack_moving")
	add_state("following")
	add_state("stop")
	add_state("hold")
	call_deferred("set_state", states.idle)

func state_logic(delta): #Actual state logic, what to do in states

	var command = parent.get_current_command()
	
	match state:
		states.idle:
			if command != null:
				match command.type:
					"move":
						parent.movement_target = command.position
						parent.pathfinding_agent.target_position = parent.movement_target
						parent.stored_target = parent.pathfinding_agent.target_position
						print("Path set", parent.stored_target)
						set_state(states.moving)
					"attack_move":
						parent.attack_move_target = command.position
						parent.is_attack_moving = true
						set_state(states.attack_moving)
					"stop":
						set_state(states.stop)
					"hold":
						set_state(states.hold)
						
		states.moving:
			if parent.movement_target != null:
				parent.move_to_target()
				
		states.attack_moving:
			if parent.attack_move_target != null:
				if parent.pathfinding_timer > parent.pathfinding_speed:
					parent.pathfinding_agent.target_position = parent.attack_move_target
				parent.move_to_target()
		
		states.following:
			if parent.follow_target == null or parent.follow_target.dead:
				parent.follow_target = null
				set_state(states.idle)
			if parent.follow_target != null:
				if parent.position.distance_to(parent.follow_target.global_position) < 50.0:
					animation_player.play("idle")
				else:
					animation_player.play("walk")
					if parent.pathfinding_timer > parent.pathfinding_speed:
						parent.pathfinding_agent.target_position = parent.follow_target.global_position
					parent.move_to_target()
		
		states.stop:
			pass
			
		states.aggroing:
			if parent.attack_target != null:
				if parent.pathfinding_timer > parent.pathfinding_speed:
					if parent.pathfinding_timer > parent.pathfinding_speed:
						parent.pathfinding_agent.target_position = parent.attack_target.global_position
				parent.move_to_target()
		states.attacking:
			var anim_speed = parent.data.stats.attack_speed
			var attack_point_scaled = parent.data.unit_model_data.animation_attack_point / anim_speed
			var attack_duration_scaled = parent.data.unit_model_data.animation_attack_duration / anim_speed

			if parent.is_attack_committed:
				parent.attack_anim_timer += delta
				
				###Deal damage --- stage 2
				if !parent.has_attacked and parent.attack_anim_timer >= attack_point_scaled:
					parent.perform_attack()
					parent.has_attacked = true
				
				###Finish attack animation --- stage 3
				if parent.attack_anim_timer >= attack_duration_scaled:
					parent.attack_anim_timer = 0.0
					parent.has_attacked = false
					parent.is_attack_committed = false
					
			else:
				###Finish attack
				if parent.attack_target == null or parent.attack_target.dead:
					parent.attack_target = null
					return
					##Start new attack
				elif parent.attack_timer <= 0 and !parent.is_attack_committed:
					parent.is_attack_committed = true
					parent.has_attacked = false
					parent.attack_anim_timer = 0.0
					parent.attack_timer = parent.get_attack_delay()
					animation_player.stop()
					animation_library.play("animations/attack")
					animation_library.speed_scale = anim_speed + 0.05
					### adding slight speed boost to animation so it finishes before attack finishes
			pass

func enter_state(_new_state, _old_state): #mostly for animations
	match state:
		states.idle:
			if animation_player.sprite_frames.has_animation("idle"):
				animation_player.play("idle")
		states.moving:
			animation_player.play("walk")				
		states.attack_moving:
			animation_player.play("walk")
		states.stop:
			parent.command_queue.pop_front()
			parent.clear_rally_point()
			parent.clear_unit_state()
			set_state(states.idle)
		states.hold:
			parent.command_queue.pop_front()
			parent.clear_rally_point()
			parent.clear_unit_state()
			animation_player.play("idle")
			parent.holding_position = true
		states.aggroing:
			if parent.attack_target != null:
				parent.attack_target.register_attacker(parent)
			animation_player.play("walk")
		states.attacking:
			animation_player.play("idle")
		states.dying:
			parent.set_physics_process(false)
			parent.set_collision_layer(0)
			parent.set_collision_mask(0)
			animation_player.connect("animation_finished", Callable(self, "_on_death_animation_finished"), CONNECT_ONE_SHOT)
			animation_player.play("dying")

func exit_state(_old_state, _new_state):
	match state:
		states.hold:
			parent.holding_position = false
		states.attacking:
			if parent.attack_target != null:
				parent.attack_target.unregister_attacker(parent)
				
func get_transition(_delta): #Handle transitions, if x happens go to state y
	if parent.dead and state != states.dying:
		return states.dying
	
	var aggro_target = parent.closest_enemy_in_aggro_range()
	var target_in_range = parent.closest_enemy_in_attack_range()
	
	match state:
		states.dying:
			return null
		states.idle:
			if aggro_target != null:
				if !aggro_target.dead:
					parent.attack_target = aggro_target
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
		
		states.stop:
			return null
			
		states.hold:
			return states.hold
			
		states.following:
			return null
			
		states.attack_moving:
			if parent.attack_target == null:
				if aggro_target != null:
					parent.attack_target = aggro_target
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
			if parent.attack_target != null and !parent.attack_target.dead:
				if target_in_range != null:
					return states.attacking
			elif parent.attack_target == null or parent.attack_target.dead:
				parent.attack_target = null
				return states.idle
			return null
			
		states.attacking:
			if parent.attack_target == null or parent.attack_target.dead:
				parent.on_attack_stop()
				parent.attack_target = null
				
				if parent.is_attack_moving:
					return states.attack_moving
				elif parent.get_current_command() != null:
					return states.idle
				else:
					return states.idle
			
			if target_in_range == null and !parent.is_attack_committed:
				parent.on_attack_stop()
				return states.aggroing
			
			return null
	
func _on_death_animation_finished():
	parent.queue_free()
