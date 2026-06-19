# addons/event_editor/event_dock.gd
@tool
extends VBoxContainer

var target_node: Node2D
var command_list: ItemList
var type_selector: OptionButton
var add_btn: Button
var editor_panel: VBoxContainer # Panel for Delete/Else commands

# Passed from plugin.gd to handle undo/redo and mark scene as dirty
var undo_redo: EditorUndoRedoManager

# Global variable for copy-pasted command resource
var copied_command: Resource = null

# A dictionary to store { "CommandClassName": "res://path/to/script.gd" }
var available_commands: Dictionary = {}

# Define commands that should never appear in the manual add dropdown
var hidden_commands = ["CommandElse", "CommandEnd"]

class DragList extends ItemList:
	var dock: Control

	func _get_drag_data(at_position: Vector2) -> Variant:
		var idx = get_item_at_position(at_position, true)
		if idx == -1: 
			return null
		
		var label = Label.new()
		label.text = get_item_text(idx)
		set_drag_preview(label)
		
		return {"source": "command_list", "index": idx}
		
	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		return typeof(data) == TYPE_DICTIONARY and data.get("source") == "command_list"
		
	func _drop_data(at_position: Vector2, data: Variant) -> void:
		var target_idx = get_item_at_position(at_position, true)
		if target_idx == -1: 
			target_idx = item_count
			
		dock._move_command(data["index"], target_idx)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed:
			if event.ctrl_pressed:
				if event.keycode == KEY_C:
					dock.copy_selected()
					accept_event()
				elif event.keycode == KEY_V:
					dock.paste_selected()
					accept_event()
			elif event.keycode == KEY_DELETE:
				dock.delete_selected()
				accept_event()

func _init() -> void:
	custom_minimum_size = Vector2(0, 300)
	
	var title = Label.new()
	title.text = "Event Sequence Editor"
	add_child(title)
	
	command_list = DragList.new()
	command_list.dock = self
	command_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	command_list.item_selected.connect(_on_command_selected)
	add_child(command_list)
	
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	type_selector = OptionButton.new()
	type_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(type_selector)
	
	add_btn = Button.new()
	add_btn.text = "Add Command"
	add_btn.pressed.connect(_on_add_pressed)
	hbox.add_child(add_btn)
	
	var separator = HSeparator.new()
	add_child(separator)
	
	editor_panel = VBoxContainer.new()
	editor_panel.custom_minimum_size = Vector2(0, 40)
	add_child(editor_panel)
	
	_discover_commands()
	_populate_dropdown()
	
	# Auto-refresh the list in real-time when properties are edited in the Inspector
	EditorInterface.get_inspector().property_edited.connect(func(property):
		refresh_list()
	)

func _discover_commands() -> void:
	available_commands.clear()
	var classes = ProjectSettings.get_global_class_list()
	
	for cls_data in classes:
		if cls_data["base"] == "EventCommand":
			var cmd_class_name = cls_data["class"]
			if not cmd_class_name in hidden_commands:
				available_commands[cmd_class_name] = cls_data["path"]

func _populate_dropdown() -> void:
	type_selector.clear()
	var index = 0
	for cmd_name in available_commands.keys():
		type_selector.add_item(cmd_name, index)
		index += 1

func set_target(node: Node2D) -> void:
	target_node = node
	_discover_commands()
	_populate_dropdown()
	refresh_list()
	_clear_editor_panel()

func clear_target() -> void:
	target_node = null
	command_list.clear()
	_clear_editor_panel()

func refresh_list() -> void:
	var selected_items = command_list.get_selected_items()
	var current_selection = selected_items[0] if selected_items.size() > 0 else -1
	
	command_list.clear()
	if target_node and "event_sequence" in target_node:
		var sequence = target_node.get("event_sequence")
		var current_depth: int = 0
		
		for i in range(sequence.size()):
			var cmd = sequence[i]
			
			if cmd is CommandEnd or cmd is CommandElse:
				current_depth = max(0, current_depth - 1)
			
			var display_text = "Empty Slot"
			if cmd != null:
				# Connect to changed signal for auto-refresh
				if not cmd.changed.is_connected(refresh_list):
					cmd.changed.connect(refresh_list)
					
				var cmd_str = str(cmd)
				if not cmd_str.begins_with("<"):
					display_text = cmd_str
				else:
					var script = cmd.get_script()
					if script and "class_name" in str(script.source_code):
						display_text = script.resource_path.get_file().get_basename()
					else:
						display_text = "Command"
					
			var indent_spaces = "    ".repeat(current_depth)
			command_list.add_item(str(i) + ": " + indent_spaces + display_text)
			
			if cmd is CommandIf or cmd is CommandElse:
				current_depth += 1
				
		if current_selection != -1 and current_selection < command_list.item_count:
			command_list.select(current_selection, false)

func _on_add_pressed() -> void:
	if not target_node or not "event_sequence" in target_node:
		return
		
	var selected_idx = type_selector.get_selected_id()
	if selected_idx == -1: return
		
	var class_name_str = type_selector.get_item_text(selected_idx)
	var script_path = available_commands[class_name_str]
	var script = load(script_path)
	
	if script:
		var sequence = target_node.get("event_sequence")
		var new_sequence = sequence.duplicate()
		var new_cmd = script.new()
		new_sequence.append(new_cmd)
		
		if new_cmd is CommandIf:
			new_sequence.append(CommandEnd.new())
			
		if undo_redo:
			undo_redo.create_action("Add Event Command")
			undo_redo.add_do_property(target_node, "event_sequence", new_sequence)
			undo_redo.add_undo_property(target_node, "event_sequence", sequence)
			undo_redo.commit_action()
		else:
			target_node.set("event_sequence", new_sequence)
			target_node.notify_property_list_changed()
		
		refresh_list()

func _move_command(from_index: int, to_index: int) -> void:
	if not target_node or not "event_sequence" in target_node:
		return
		
	var sequence = target_node.get("event_sequence")
	if from_index == to_index:
		return
		
	var new_sequence = sequence.duplicate()
	var cmd = new_sequence[from_index]
	new_sequence.remove_at(from_index)
	
	if to_index > from_index:
		to_index -= 1
		
	new_sequence.insert(to_index, cmd)
	
	if undo_redo:
		undo_redo.create_action("Move Event Command")
		undo_redo.add_do_property(target_node, "event_sequence", new_sequence)
		undo_redo.add_undo_property(target_node, "event_sequence", sequence)
		undo_redo.commit_action()
	else:
		target_node.set("event_sequence", new_sequence)
		target_node.notify_property_list_changed()
	
	refresh_list()
	_clear_editor_panel()

# ==========================================
# Command Actions and Copy/Paste/Delete
# ==========================================

func _clear_editor_panel() -> void:
	for child in editor_panel.get_children():
		child.queue_free()

func _on_command_selected(index: int) -> void:
	_clear_editor_panel()
	
	if not target_node or not "event_sequence" in target_node:
		return
		
	var sequence = target_node.get("event_sequence")
	if index < 0 or index >= sequence.size():
		return
		
	var cmd = sequence[index]
	if not cmd:
		return
		
	# Inspect the selected object in Godot's built-in Inspector
	EditorInterface.inspect_object(cmd)
	
	var header_hbox = HBoxContainer.new()
	editor_panel.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "Selected Command " + str(index) + " (Editing in Inspector)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) 
	
	if cmd is CommandElse or cmd is CommandEnd:
		delete_btn.disabled = true
		delete_btn.tooltip_text = "Must delete the parent If command."
		
	delete_btn.pressed.connect(func(): _delete_command(index))
	header_hbox.add_child(delete_btn)
	
	if cmd is CommandIf:
		var else_btn = Button.new()
		var has_else = false
		var depth = 0
		var else_idx = -1
		
		for i in range(index + 1, sequence.size()):
			var check_cmd = sequence[i]
			if check_cmd is CommandIf: depth += 1
			elif check_cmd is CommandEnd:
				if depth == 0: break
				depth -= 1
			elif check_cmd is CommandElse and depth == 0:
				has_else = true
				else_idx = i
				break
				
		else_btn.text = "Remove False Condition (Else)" if has_else else "Add False Condition (Else)"
		else_btn.pressed.connect(func():
			var new_sequence = sequence.duplicate()
			if has_else:
				new_sequence.remove_at(else_idx)
			else:
				new_sequence.insert(index + 1, CommandElse.new())
				
			if undo_redo:
				undo_redo.create_action("Toggle Else Condition")
				undo_redo.add_do_property(target_node, "event_sequence", new_sequence)
				undo_redo.add_undo_property(target_node, "event_sequence", sequence)
				undo_redo.commit_action()
			else:
				target_node.set("event_sequence", new_sequence)
				target_node.notify_property_list_changed()
			
			refresh_list()
			_on_command_selected(index) 
		)
		editor_panel.add_child(else_btn)

func _delete_command(index: int) -> void:
	if not target_node or not "event_sequence" in target_node:
		return
		
	var sequence = target_node.get("event_sequence")
	if index < 0 or index >= sequence.size():
		return
		
	var new_sequence = sequence.duplicate()
	var cmd = new_sequence[index]
	
	if cmd is CommandIf:
		var elements_to_delete = [index]
		var depth = 0
		
		for i in range(index + 1, new_sequence.size()):
			var check_cmd = new_sequence[i]
			if check_cmd is CommandIf:
				depth += 1
			elif check_cmd is CommandEnd:
				if depth == 0:
					elements_to_delete.append(i)
					break
				depth -= 1
			elif check_cmd is CommandElse and depth == 0:
				elements_to_delete.append(i)
				
		elements_to_delete.sort_custom(func(a, b): return a > b)
		for i in elements_to_delete:
			new_sequence.remove_at(i)
	else:
		new_sequence.remove_at(index)
		
	if undo_redo:
		undo_redo.create_action("Delete Event Command")
		undo_redo.add_do_property(target_node, "event_sequence", new_sequence)
		undo_redo.add_undo_property(target_node, "event_sequence", sequence)
		undo_redo.commit_action()
	else:
		target_node.set("event_sequence", new_sequence)
		target_node.notify_property_list_changed()
		
	refresh_list()
	_clear_editor_panel()

func copy_selected() -> void:
	if not target_node or not "event_sequence" in target_node:
		return
	var selected = command_list.get_selected_items()
	if selected.size() > 0:
		var index = selected[0]
		var sequence = target_node.get("event_sequence")
		var cmd = sequence[index]
		if cmd:
			copied_command = cmd
			print("Event Editor: Copied command at index ", index)

func paste_selected() -> void:
	if not target_node or not "event_sequence" in target_node or not copied_command:
		return
	var sequence = target_node.get("event_sequence")
	var selected = command_list.get_selected_items()
	var insert_idx = sequence.size()
	if selected.size() > 0:
		insert_idx = selected[0] + 1
	
	var new_sequence = sequence.duplicate()
	var pasted_cmd = copied_command.duplicate()
	new_sequence.insert(insert_idx, pasted_cmd)
	
	if undo_redo:
		undo_redo.create_action("Paste Event Command")
		undo_redo.add_do_property(target_node, "event_sequence", new_sequence)
		undo_redo.add_undo_property(target_node, "event_sequence", sequence)
		undo_redo.commit_action()
	else:
		target_node.set("event_sequence", new_sequence)
		target_node.notify_property_list_changed()
	
	refresh_list()
	
	command_list.select(insert_idx)
	_on_command_selected(insert_idx)
	print("Event Editor: Pasted command at index ", insert_idx)

func delete_selected() -> void:
	var selected = command_list.get_selected_items()
	if selected.size() > 0:
		_delete_command(selected[0])
