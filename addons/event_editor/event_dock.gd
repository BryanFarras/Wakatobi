# addons/event_editor/event_dock.gd
@tool
extends VBoxContainer

var target_node: Node2D
var command_list: ItemList
var type_selector: OptionButton
var add_btn: Button
var editor_panel: VBoxContainer # New panel for editing properties

# A dictionary to store { "CommandClassName": "res://path/to/script.gd" }
var available_commands: Dictionary = {}

# Define commands that should never appear in the manual add dropdown
var hidden_commands = ["CommandElse", "CommandEnd"]

# Place this below your variables, before _init()
class DragList extends ItemList:
	var dock: Control

	func _get_drag_data(at_position: Vector2) -> Variant:
		var idx = get_item_at_position(at_position, true)
		if idx == -1: 
			return null
		
		# Create a visual preview of what we are dragging
		var label = Label.new()
		label.text = get_item_text(idx)
		set_drag_preview(label)
		
		return {"source": "command_list", "index": idx}
		
	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		return typeof(data) == TYPE_DICTIONARY and data.get("source") == "command_list"
		
	func _drop_data(at_position: Vector2, data: Variant) -> void:
		var target_idx = get_item_at_position(at_position, true)
		if target_idx == -1: 
			target_idx = item_count # Drop at the very bottom if not on an item
			
		dock._move_command(data["index"], target_idx)

func _init() -> void:
	custom_minimum_size = Vector2(0, 300)
	
	var title = Label.new()
	title.text = "Event Sequence Editor"
	add_child(title)
	
	command_list = DragList.new()
	command_list.dock = self # Give the list a reference to this script
	command_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Connect the selection signal to trigger the editor panel
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
	
	# Add a separator and the editor panel
	var separator = HSeparator.new()
	add_child(separator)
	
	editor_panel = VBoxContainer.new()
	editor_panel.custom_minimum_size = Vector2(0, 100)
	add_child(editor_panel)
	
	_discover_commands()
	_populate_dropdown()

func _discover_commands() -> void:
	available_commands.clear()
	var classes = ProjectSettings.get_global_class_list()
	
	for cls_data in classes:
		if cls_data["base"] == "EventCommand":
			var cmd_class_name = cls_data["class"]
			
			# Only add the command if it is not in the hidden list
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
	# 1. Capture the current selection
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
				
		# 2. Restore the selection highlight
		if current_selection != -1 and current_selection < command_list.item_count:
			# The 'false' argument is critical. It prevents the list from emitting 
			# the 'item_selected' signal again, which would cause an infinite loop.
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
		var new_cmd = script.new()
		sequence.append(new_cmd)
		
		# Auto-append an End block if we just added an If block
		if new_cmd is CommandIf:
			sequence.append(CommandEnd.new())
		
		target_node.notify_property_list_changed()
		refresh_list()

func _move_command(from_index: int, to_index: int) -> void:
	if not target_node or not "event_sequence" in target_node:
		return
		
	var sequence = target_node.get("event_sequence")
	
	if from_index == to_index:
		return
		
	# Extract the command and remove it from its old position
	var cmd = sequence[from_index]
	sequence.remove_at(from_index)
	
	# Adjust the target index to account for the array shifting
	if to_index > from_index:
		to_index -= 1
		
	# Insert it at the new position
	sequence.insert(to_index, cmd)
	
	target_node.notify_property_list_changed()
	refresh_list()
	_clear_editor_panel() # Clear the editing panel so we do not edit the wrong index

# ==========================================
# Property Editing Logic
# ==========================================

func _clear_editor_panel() -> void:
	for child in editor_panel.get_children():
		child.queue_free()

func _on_command_selected(index: int) -> void:
	_clear_editor_panel()
	
	var sequence = target_node.get("event_sequence")
	var cmd = sequence[index]
	if not cmd:
		return
		
	var header_hbox = HBoxContainer.new()
	editor_panel.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "Editing Command " + str(index)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var inspect_btn = Button.new()
	inspect_btn.text = "Edit in Inspector"
	inspect_btn.pressed.connect(func(): EditorInterface.inspect_object(cmd))
	header_hbox.add_child(inspect_btn)
	
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) 
	
	# Prevent direct deletion of Else and End blocks
	if cmd is CommandElse or cmd is CommandEnd:
		delete_btn.disabled = true
		delete_btn.tooltip_text = "Must delete the parent If command."
		
	delete_btn.pressed.connect(func(): _delete_command(index))
	header_hbox.add_child(delete_btn)
	
	# Removed the 10px spacers here to tighten the UI
	
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
			if has_else:
				sequence.remove_at(else_idx)
			else:
				sequence.insert(index + 1, CommandElse.new())
			target_node.notify_property_list_changed()
			refresh_list()
			_on_command_selected(index) 
		)
		editor_panel.add_child(else_btn)
		# Removed the second 10px spacer here
		
	var props = cmd.get_property_list()
	for prop in props:
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and prop["usage"] & PROPERTY_USAGE_EDITOR:
			_create_input_field(cmd, prop)

func _delete_command(index: int) -> void:
	if not target_node or not "event_sequence" in target_node:
		return
		
	var sequence = target_node.get("event_sequence")
	if index < 0 or index >= sequence.size():
		return
		
	var cmd = sequence[index]
	
	if cmd is CommandIf:
		# Array to hold indices of blocks to delete
		var elements_to_delete = [index]
		var depth = 0
		
		for i in range(index + 1, sequence.size()):
			var check_cmd = sequence[i]
			if check_cmd is CommandIf:
				depth += 1
			elif check_cmd is CommandEnd:
				if depth == 0:
					elements_to_delete.append(i)
					break # Reached the end of this IF block
				depth -= 1
			elif check_cmd is CommandElse and depth == 0:
				elements_to_delete.append(i)
				
		# Sort descending. Removing from highest index to lowest ensures 
		# we don't accidentally shift the positions of the remaining items.
		elements_to_delete.sort_custom(func(a, b): return a > b)
		
		for i in elements_to_delete:
			sequence.remove_at(i)
	else:
		sequence.remove_at(index)
		
	target_node.notify_property_list_changed()
	refresh_list()
	_clear_editor_panel()

func _create_input_field(cmd: Resource, prop: Dictionary) -> void:
	var hbox = HBoxContainer.new()
	editor_panel.add_child(hbox)
	
	var label = Label.new()
	label.text = prop["name"].capitalize()
	label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(label)
	
	var current_value = cmd.get(prop["name"])
	
	if prop["type"] == TYPE_INT and prop["hint"] == PROPERTY_HINT_ENUM:
		var dropdown = OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var options = prop["hint_string"].split(",")
		for i in range(options.size()):
			var opt_name = options[i].split(":")[0].strip_edges()
			dropdown.add_item(opt_name, i)
			
		dropdown.selected = current_value if current_value != null else 0
		dropdown.item_selected.connect(func(index):
			cmd.set(prop["name"], index)
			target_node.notify_property_list_changed()
			refresh_list() # Added here
		)
		hbox.add_child(dropdown)

	elif prop["type"] == TYPE_FLOAT or prop["type"] == TYPE_INT:
		var spin = SpinBox.new()
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value = current_value if current_value != null else 0
		spin.step = 0.1 if prop["type"] == TYPE_FLOAT else 1.0
		spin.min_value = -10000
		spin.max_value = 10000
		
		spin.value_changed.connect(func(new_val):
			cmd.set(prop["name"], new_val)
			target_node.notify_property_list_changed()
			refresh_list() # Added here
		)
		hbox.add_child(spin)
		
	elif prop["type"] == TYPE_STRING:
		if prop["hint"] == PROPERTY_HINT_MULTILINE_TEXT:
			var text_edit = TextEdit.new()
			text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_edit.custom_minimum_size = Vector2(0, 100)
			text_edit.text = current_value if current_value != null else ""
			
			text_edit.text_changed.connect(func():
				cmd.set(prop["name"], text_edit.text)
				target_node.notify_property_list_changed()
				refresh_list() # Added here
			)
			hbox.add_child(text_edit)
		else:
			var line_edit = LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = current_value if current_value != null else ""
			
			line_edit.text_changed.connect(func(new_text):
				cmd.set(prop["name"], new_text)
				target_node.notify_property_list_changed()
				refresh_list() # Added here
			)
			hbox.add_child(line_edit)
	elif prop["type"] == TYPE_NODE_PATH:
		var line_edit = LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.text = str(current_value) if current_value else ""
		
		line_edit.text_changed.connect(func(new_text):
			cmd.set(prop["name"], NodePath(new_text))
			target_node.notify_property_list_changed()
			refresh_list()
		)
		hbox.add_child(line_edit)
	elif prop["type"] == TYPE_OBJECT:
		var picker = EditorResourcePicker.new()
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var base_type = "Resource"
		if prop.has("class_name") and prop["class_name"] != "":
			base_type = prop["class_name"]
		elif prop.has("hint_string") and prop["hint_string"] != "":
			base_type = prop["hint_string"]
			
		picker.base_type = base_type
		picker.edited_resource = current_value
		
		picker.resource_changed.connect(func(res):
			cmd.set(prop["name"], res)
			target_node.notify_property_list_changed()
			refresh_list()
		)
		hbox.add_child(picker)
			
	elif prop["type"] == TYPE_VECTOR2:
		var vec_hbox = HBoxContainer.new()
		vec_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var x_spin = SpinBox.new()
		x_spin.prefix = "X: "
		x_spin.min_value = -10000
		x_spin.max_value = 10000
		x_spin.value = current_value.x if current_value != null else 0.0
		
		var y_spin = SpinBox.new()
		y_spin.prefix = "Y: "
		y_spin.min_value = -10000
		y_spin.max_value = 10000
		y_spin.value = current_value.y if current_value != null else 0.0
		
		vec_hbox.add_child(x_spin)
		vec_hbox.add_child(y_spin)
		hbox.add_child(vec_hbox)
		
		x_spin.value_changed.connect(func(new_val):
			var current = cmd.get(prop["name"])
			current.x = new_val
			cmd.set(prop["name"], current)
			target_node.notify_property_list_changed()
			refresh_list() # Added here
		)
		
		y_spin.value_changed.connect(func(new_val):
			var current = cmd.get(prop["name"])
			current.y = new_val
			cmd.set(prop["name"], current)
			target_node.notify_property_list_changed()
			refresh_list() # Added here
		)
