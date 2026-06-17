class_name CommandIf
extends EventCommand

@export_multiline var condition: String = ""

func execute() -> Signal:
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	return "If:  " + str(condition)