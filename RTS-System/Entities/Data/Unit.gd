extends CharacterBody2D

class_name Unit

var owner_id: int
var data : UnitData

var command_holder: CommandHolder
var unit_ai: UnitAI
var unit_combat: UnitCombat
var unit_visual: UnitVisual
var unit_ability_manager: UnitAbilityManager
var unit_inventory: UnitInventory

var spawned: bool = false

signal died(unit)

func create_unit():
	if !DevLogger.run_logged("_setup_data", func(): _setup_data()): return
	if !DevLogger.run_logged("_setup_components", func(): _setup_components()): return
	if !DevLogger.run_logged("_setup_scene", func(): _setup_scene()): return
	if !DevLogger.run_logged("_finalize_spawn", func(): _finalize_spawn()): return

func _setup_data():
	if data and data.stats:
		data = data.duplicate()
		data.parent = self

		data.stats = data.stats.duplicate()
		data.stats.parent = self
	else:
		return

func _setup_components():
	var animation_player = $AnimatedSprite2D
	var hp_bar = $AnimatedSprite2D/HpBar/Control
	var target_marker = $TargetMarker
	var circle_front =  $SelectionCircleFront
	var circle_back = $SelectionCircleBack
	var buff_front = $BuffLayerFront
	var buff_back = $BuffLayerBack

	command_holder = CommandHolder.new(self)
	unit_ai = UnitAI.new(self, command_holder, animation_player)
	unit_combat = UnitCombat.new(self, data, data.stats)
	unit_visual = UnitVisual.new(self, animation_player, hp_bar, target_marker, circle_front, circle_back, buff_front, buff_back)
	unit_ability_manager = UnitAbilityManager.new(self, data)

	if self is Hero:
		unit_inventory = UnitInventory.new(self)
		data.hero = self

func _setup_scene():
	var aggro_collider = $AggroRange/CollisionShape2D
	var animation_player = $AnimatedSprite2D
	add_child(unit_ai)
	add_child(unit_combat)
	add_child(unit_visual)
	if unit_ability_manager: # why is there if statement, too scared to remove it # todo
		add_child(unit_ability_manager)
	
	aggro_collider.disabled = false
	animation_player.init_animations(data.unit_model_data)
	SpatialGrid.register_unit(self)

	data.stats.recalculate_stats()
	data.stats.current_health = data.stats.max_health
	data.stats.current_mana = data.stats.max_mana

func _finalize_spawn():
	unit_ai.init_ai()
	unit_ai.set_ready()
	unit_visual.initialize_visuals()
	spawned = true

func _process(delta: float) -> void:
	## dont ask
	if spawned:
		if unit_ability_manager:
			unit_ability_manager.tick(delta)
		if unit_combat:
			unit_combat.tick(delta)

# Collision stuff
func is_valid_unit(unit) -> bool:
	if !is_instance_valid(unit) or unit == null or !unit.unit_combat or unit.unit_combat.dead:
		return false
	return true
		
func _on_aggro_range_body_entered(body: Node2D):
	if body.is_in_group("unit"):
		if !is_valid_unit(body) or !is_valid_unit(self):
			return

		if body.owner_id != self.owner_id and body not in unit_combat.possible_targets:
			unit_combat.possible_targets.append(body)
		if body.owner_id == self.owner_id and body not in unit_combat.friendly_targets:
			unit_combat.friendly_targets.append(body)
			
func _on_aggro_range_body_exited(body: Node2D):
	if is_valid_unit(self):
		if unit_combat.possible_targets.has(body):
			if body.owner_id != self.owner_id:
				unit_combat.possible_targets.erase(body)

		if unit_combat.friendly_targets.has(body):
			if body.owner_id == self.owner_id:
				unit_combat.friendly_targets.erase(body)