extends RefCounted

class_name InputHandler
var input_receiver
var player_id

signal command_ready(info: InputInfo)

func _init(input_receiver_ref: InputReceiver, player_id_ref) -> void:
	input_receiver = input_receiver_ref
	input_receiver.connect("intent_issued", self, "_on_intent")

	player_id = player_id_ref

func _on_intent(info: InputInfo):
	match info.mouse_button:
		InputInfo.CursorButton.LEFT:
			info.intent_type = InputInfo.IntentType.SELECT
		
		InputInfo.CursorButton.RIGHT:
			if info.clicked_unit:
				if info.clicked_unit._is_enemy(info.clicked_unit):
					info.intent_type = InputInfo.IntentType.ATTACK
				elif !info.clicked_unit._is_enemy(info.clicked_unit):
					info.intent_type = InputInfo.IntentType.MOVE
			else:
				info.intent_type = InputInfo.IntentType.MOVE

	if info.intent_Type != InputInfo.IntentType.NONE:
		emit_signal("command_ready", info)
			
func _is_enemy(unit: Unit) -> bool:
	return unit.owner_id == player_id