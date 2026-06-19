extends Node

signal state_changed(key: StringName, value: Variant)

var flags: Dictionary = {}
var variables: Dictionary = {}

func set_flag(name: String, value: bool) -> void:
	flags[name] = value
	state_changed.emit(StringName(name), value)

func get_flag(name: String, default: bool = false) -> bool:
	return flags.get(name, default)

func set_variable(name: String, value: Variant) -> void:
	variables[name] = value
	state_changed.emit(StringName(name), value)

func get_variable(name: String, default: Variant = null) -> Variant:
	return variables.get(name, default)

func reset() -> void:
	flags.clear()
	variables.clear()

func get_state() -> Dictionary:
	return {
		"flags": flags,
		"variables": variables
	}

func load_state(data: Dictionary) -> void:
	if data.has("flags") and data["flags"] is Dictionary:
		flags = data["flags"]
	if data.has("variables") and data["variables"] is Dictionary:
		variables = data["variables"]

# --- Dynamic Property Support ---
# This allows StoryState.some_flag = true, and if StoryState.some_flag: ...
# Note: Undefined properties return false by default.

func _get(property: StringName) -> Variant:
	var prop_str = str(property)
	if flags.has(prop_str):
		return flags[prop_str]
	if variables.has(prop_str):
		return variables[prop_str]
	# Safe fallback for booleans
	return false

func _set(property: StringName, value: Variant) -> bool:
	var prop_str = str(property)
	if typeof(value) == TYPE_BOOL:
		flags[prop_str] = value
		state_changed.emit(property, value)
		return true
	else:
		variables[prop_str] = value
		state_changed.emit(property, value)
		return true
