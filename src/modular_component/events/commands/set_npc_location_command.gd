# set_npc_location_command.gd
@tool
class_name CommandSetNPCLocation
extends EventCommand

enum CharacterDirection { NONE, UP, DOWN, LEFT, RIGHT }

@export var npc_node_path: NodePath
## Koordinat tile tujuan (X, Y - masing-masing berukuran 32x32 piksel)
@export var target_tile: Vector2i = Vector2i.ZERO
@export var target_direction: CharacterDirection = CharacterDirection.NONE

func execute() -> Signal:
	var base_node = Engine.get_main_loop().current_scene
	if EventManager.current_context_node:
		base_node = EventManager.current_context_node

	if not base_node:
		return Engine.get_main_loop().process_frame

	var entity = base_node.get_node_or_null(npc_node_path)
	if not entity and EventManager.current_context_node:
		var scene_root = Engine.get_main_loop().current_scene
		if scene_root:
			entity = scene_root.get_node_or_null(npc_node_path)

	if entity and is_instance_valid(entity):
		var pixel_pos = Vector2(target_tile.x * 32 + 16, target_tile.y * 32 + 16)
		entity.global_position = pixel_pos
		
		# Set NPC direction if specified
		if target_direction != CharacterDirection.NONE:
			var dir_vector := Vector2.ZERO
			match target_direction:
				CharacterDirection.UP: dir_vector = Vector2.UP
				CharacterDirection.DOWN: dir_vector = Vector2.DOWN
				CharacterDirection.LEFT: dir_vector = Vector2.LEFT
				CharacterDirection.RIGHT: dir_vector = Vector2.RIGHT
			
			if entity.has_method("set_direction"):
				entity.set_direction(dir_vector)
				
		print("[DEBUG SetNPCLocation] Teleporting NPC: ", entity.name, " to tile: ", target_tile, " (pixel: ", pixel_pos, ") facing: ", CharacterDirection.keys()[target_direction])
	else:
		push_error("CommandSetNPCLocation: Target NPC not found: " + str(npc_node_path))

	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	var npc_name = str(npc_node_path).get_file()
	if npc_name.is_empty():
		npc_name = "[Empty]"
	var dir_desc = ""
	if target_direction != CharacterDirection.NONE:
		dir_desc = " facing " + CharacterDirection.keys()[target_direction]
	return "Set Location: " + npc_name + " to tile " + str(target_tile) + dir_desc
