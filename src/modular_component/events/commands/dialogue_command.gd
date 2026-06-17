# command_dialogue.gd
class_name CommandDialogue
extends EventCommand

@export var dialogue_resource: DialogueResource
@export var start_node: String = "Awal"
@export var left_portrait: String = ""
@export var right_portrait: String = ""

func execute() -> Signal:
	if dialogue_resource:
		var balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, start_node)
		if balloon:
			if not left_portrait.strip_edges().is_empty() and balloon.has_method("kiri_potrait"):
				balloon.kiri_potrait(left_portrait.strip_edges())
			if not right_portrait.strip_edges().is_empty() and balloon.has_method("kanan_potrait"):
				balloon.kanan_potrait(right_portrait.strip_edges())
		return DialogueManager.dialogue_ended
	else:
		push_error("CommandDialogue: dialogue_resource is not set!")
		
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	var name_str = dialogue_resource.resource_path.get_file().get_basename() if dialogue_resource else "Empty"
	return "Dialogue: " + name_str + " (" + start_node + ")"
