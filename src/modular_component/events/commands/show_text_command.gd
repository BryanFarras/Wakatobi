# command_show_text.gd
@tool
class_name CommandShowText
extends EventCommand

enum npc_selection { none, player, nelayan_1, nelayan_2, tetua_desa}

@export var character_name: String = "NPC"
@export_multiline var text: String = ""
@export var left_portrait: npc_selection
@export var right_portrait: npc_selection
@export var left_is_visible: bool
@export var right_is_visible: bool

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
			if left_portrait != npc_selection.none:
				var left_key = npc_selection.keys()[left_portrait]
				balloon.kiri_potrait(left_key)
				balloon.potrait_right.visible = left_is_visible
			else:
				balloon.potrait_right.visible = false
				balloon.kiri_potrait("")

			if right_portrait != npc_selection.none:
				var right_key = npc_selection.keys()[right_portrait]
				balloon.kanan_potrait(right_key)
				balloon.potrait_left.visible = right_is_visible
			else:
				balloon.potrait_left.visible = false
				balloon.kanan_potrait("")

			var left_key = npc_selection.keys()[left_portrait]
			var right_key = npc_selection.keys()[right_portrait]
			var left_char_name = left_key.capitalize()
			var right_char_name = right_key.capitalize()

			var is_left_speaking = left_portrait != npc_selection.none and (character_name.to_lower() == left_char_name.to_lower() or character_name.to_lower() == left_key.to_lower())
			var is_right_speaking = right_portrait != npc_selection.none and (character_name.to_lower() == right_char_name.to_lower() or character_name.to_lower() == right_key.to_lower())

			if left_is_visible and right_is_visible:
				if is_left_speaking:
					balloon.kiri()
				elif is_right_speaking:
					balloon.kanan()
				else:
					balloon.potrait_left.set_modulate(Color(1, 1, 1))
					balloon.potrait_right.set_modulate(Color(1, 1, 1))
			elif left_is_visible:
				balloon.kiri()
			elif right_is_visible:
				balloon.kanan()
		return DialogueManager.dialogue_ended

	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	var truncated_text = text.replace("\n", " ").left(30)
	if text.length() > 30:
		truncated_text += "..."
	return "Show Text (" + character_name + "): \"" + truncated_text + "\""
