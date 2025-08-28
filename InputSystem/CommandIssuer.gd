extends RefCounted

class_name CommandIssuer

var input_handler: InputHandler

func _init(input_handler_ref: InputHandler) -> void:
    input_handler = input_handler_ref
    input_handler.connect("command_ready", Callable(self, "_on_command_ready"))
    
func _on_command_ready(info: InputInfo):
    match info.intent_type:
        InputInfo.IntentType.SELECT:
            pass
        InputInfo.IntentType.MOVE:
            pass
        InputInfo.IntentType.ATTACK:
            pass

