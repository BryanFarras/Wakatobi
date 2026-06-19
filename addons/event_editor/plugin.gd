# addons/event_editor/plugin.gd
@tool
extends EditorPlugin

var dock_instance: Control

func _enter_tree() -> void:
	# Instantiate the UI script we just wrote
	dock_instance = preload("res://addons/event_editor/event_dock.gd").new()
	dock_instance.undo_redo = get_undo_redo()
	
	# Add it to the bottom panel (next to Output, Debugger, etc.)
	add_control_to_bottom_panel(dock_instance, "Event Editor")
	
	# Listen for selection changes in the editor
	var selection = get_editor_interface().get_selection()
	selection.selection_changed.connect(_on_editor_selection_changed)

func _exit_tree() -> void:
	# Clean up when the plugin is disabled
	remove_control_from_bottom_panel(dock_instance)
	if dock_instance:
		dock_instance.queue_free()

func _on_editor_selection_changed() -> void:
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	# Check if exactly one node is selected
	if selected_nodes.size() == 1:
		var node = selected_nodes[0]
		
		# Check if the selected node has our specific script attached
		var script = node.get_script()
		if script != null and script.resource_path.ends_with("event_interactable.gd"):
			dock_instance.set_target(node)
			make_bottom_panel_item_visible(dock_instance)
			return
			
	# If we deselect the node, clear the UI
	dock_instance.clear_target()