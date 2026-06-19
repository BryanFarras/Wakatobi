# set_switch_command.gd
class_name CommandSetSwitch
extends EventCommand

## Nama switch/flag yang ingin diubah (e.g. "intro_done", "has_talked_to_father")
@export var switch_name: String = ""

## Nilai switch (True atau False)
@export var value: bool = true

func execute() -> Signal:
	if not switch_name.strip_edges().is_empty():
		StoryState.set_flag(switch_name.strip_edges(), value)
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	if switch_name.strip_edges().is_empty():
		return "Set Switch: [Empty]"
	return "Set Switch '" + switch_name.strip_edges() + "' to " + str(value)
