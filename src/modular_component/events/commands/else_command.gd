class_name CommandElse
extends EventCommand

func execute() -> Signal:
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	return "Else"