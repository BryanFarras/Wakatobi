# command_show_text.gd
class_name CommandShowText
extends EventCommand

@export var character_name: String = "NPC"
@export_multiline var text: String = ""
@export var left_portrait: String = ""
@export var right_portrait: String = ""

func execute() -> Signal:
	if text.strip_edges().is_empty():
		return Engine.get_main_loop().process_frame

	var raw_dialogue_text = ""
	if character_name.strip_edges().is_empty():
		raw_dialogue_text = text
	else:
		var lines = text.split("\n")
		var name_prefix = character_name.strip_edges() + ": "
		var formatted_lines = []
		for line in lines:
			var clean_line = line.strip_edges()
			if not clean_line.is_empty():
				formatted_lines.append(name_prefix + clean_line)
		raw_dialogue_text = "\n".join(formatted_lines)

	if raw_dialogue_text.is_empty():
		return Engine.get_main_loop().process_frame

	var resource = DialogueManager.create_resource_from_text(raw_dialogue_text)
	if resource:
		var balloon = DialogueManager.show_dialogue_balloon(resource)
		if balloon:
			if not left_portrait.strip_edges().is_empty() and balloon.has_method("kiri_potrait"):
				balloon.kiri_potrait(left_portrait.strip_edges())
			if not right_portrait.strip_edges().is_empty() and balloon.has_method("kanan_potrait"):
				balloon.kanan_potrait(right_portrait.strip_edges())
		return DialogueManager.dialogue_ended

	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	var truncated_text = text.replace("\n", " ").left(30)
	if text.length() > 30:
		truncated_text += "..."
	return "Show Text (" + character_name + "): \"" + truncated_text + "\""
