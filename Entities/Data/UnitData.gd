extends Resource

#######################################################
### Unit.tscn(scene) is base for all units (heroes bosses etc)
### It holds UnitController which has UnitData, UnitStateMachine, CommandsData
### UnitController is logic for the unit, like 'die' 'move here' 'get closest enemy' etc
### UnitData holds all the data for the unit, like stats, name, model
### UnitStateMachine is 'AI' for the unit, which tells it what to do
### For example if you attack move, then you go to states.moving and move to x position
### then if theres enemy unit in aggro range you go on states.aggroing etc etc
### CommandsData is just holder for different command visuals like rallypoint and move command
### Controlling the unit happens in PlayerInput, it should be also the AI for all enemy units
### but i fucked up, probably in the future ill change PlayerInput to hold like InputSystem or something
### and have 2 versions of it, AI and Human and those get loaded into the PlayerInput based on
### if its AI or Human
#######################################################
### Creating new unit: make new resource and base it off UnitData
### Set Name, avatar, stats etc. Create new reource UnitModelData
### Create new spriteframes resource, make animations 'idle' 'walk' 'attack' 'dying'
### Put that spriteframes in UnitModelData -> Sprite Frames
#######################################################
### Spawning unit:
### var spawned_unit = unit.instantiate() <- unit is Unit.tscn
### spawned_unit.init_unit(UnitData) <- sets unit data from UnitData.tres resource
### spawned_unit.commands = CommandsData <- DefaultCommands.tres resource
### spawned_unit.owner_id = player_id <- currently 1-9, 10 is ai. In future this would be unique multiplayer id
### player_input.selectable_units.append(spawned_unit)
#######################################################

class_name UnitData

@export var unit_model_data: UnitModelData
@export var name: String
@export var description: String
@export var avatar: Texture2D
@export var stats: Dictionary = {
	"strength": 1, 
	"agility": 1, 
	"intelligence": 1, 
	"max_health": 1,
	"current_health": 1,
	"max_mana": 1, 
	"armor": 1,
	"movement_speed": 1, 
	"health_regen": 0.1, 
	"mana_regen": 0.1, 
	"attack_speed": 1.0, 
	"base_damage": 1,
	"attack_damage": 1,
	"attack_dice_roll": 1,
	"range": 1
	}
