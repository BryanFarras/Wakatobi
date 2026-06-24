# label_command.gd
@tool
class_name CommandLabel
extends EventCommand

## Text to display in the editor sequence list to help organize commands.
@export var label_text: String = "Section Header"

func execute() -> Signal:
	# This command does absolutely nothing at runtime.
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	return "=== " + label_text + " ==="
