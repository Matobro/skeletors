extends Node

var active_script: AIScriptBase
var player: Player
var ai_active: bool = true

func set_ai_script(script: AIScriptBase):
	if active_script:
		active_script.stop()

	active_script = script

	if active_script:
		active_script.start(self)

func update_ai(delta):
	if active_script:
		active_script.update(delta)

func _process(delta: float):
	if ai_active:
		update_ai(delta)

## Dev shit, remove later
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("o"):
		ai_active = !ai_active

	PlayerManager.color_rect.color = Color.GREEN if ai_active else Color.RED
	if ai_active:
		PlayerManager.ai_text.text = "AI = [color=green] enabled [/color]"
	else:
		PlayerManager.ai_text.text = "AI = [color=red] disabled [/color]"
