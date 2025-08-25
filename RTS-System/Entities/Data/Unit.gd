extends CharacterBody2D

class_name Unit

###UNIT DATA###
@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_collision: CollisionShape2D = $AggroRange/CollisionShape2D
@onready var hp_bar: Control = $AnimatedSprite2D/HpBar/Control
@onready var collider = $CollisionShape2D
@onready var target_marker = $TargetMarker

var owner_id: int
var data : UnitData

var command_holder: CommandHolder
var unit_ai: UnitAI
var unit_combat: UnitCombat
var unit_visual: UnitVisual
var unit_ability_manager: UnitAbilityManager
var unit_inventory: UnitInventory

signal died(unit)

func init_unit():
	data = data.duplicate()
	await get_tree().process_frame

	_data_received()
	await get_tree().process_frame

	init_stats()
	assign_stuff()

func _data_received():
	# hook for Hero
	pass

func init_stats():
	if data.stats is BaseStatData:
		data.stats = data.stats.duplicate()
	
func assign_stuff():
	aggro_collision.set_deferred("disabled", false)

	data.avatar = data.unit_model_data.sprite_frames
	animation_player.init_animations(data.unit_model_data, self)

	data.parent = self
	data.stats.parent = self
	
	create_unit()

func create_unit():
	command_holder = CommandHolder.new(self)
	unit_ai = UnitAI.new(self, command_holder)
	unit_ai.init_ai()
	unit_combat = UnitCombat.new(self, data.stats)
	unit_visual = UnitVisual.new(self, animation_player, hp_bar, target_marker)
	unit_ability_manager = UnitAbilityManager.new(self, data)
	add_child(unit_ai)
	add_child(unit_combat)
	add_child(unit_visual)

	SpatialGrid.register_unit(self)
	data.stats.recalculate_stats()

func get_stat(stat: String):
	return data.stats[stat]
		
func _on_aggro_range_body_entered(body: Node2D):
	if body.is_in_group("unit"):
		if body.owner_id != self.owner_id and body not in unit_combat.possible_targets:
			unit_combat.possible_targets.append(body)
		if body.owner_id == self.owner_id and body not in unit_combat.friendly_targets:
			unit_combat.friendly_targets.append(body)
			
func _on_aggro_range_body_exited(body: Node2D):
	if unit_combat.possible_targets.has(body):
		if body.owner_id != self.owner_id:
			unit_combat.possible_targets.erase(body)

	if unit_combat.friendly_targets.has(body):
		if body.owner_id == self.owner_id:
			unit_combat.friendly_targets.erase(body)
