extends Node

var active_script: AIScriptBase
var player: Player

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
    update_ai(delta)