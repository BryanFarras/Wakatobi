# command_move_npc.gd
@tool
class_name CommandMoveNPC
extends EventCommand

enum TargetType { NPC, PLAYER }
enum MoveDirection { UP, DOWN, LEFT, RIGHT }
enum MovementType { TIME_BASED, TILE_BASED }

@export var target_type: TargetType = TargetType.NPC:
	set(value):
		target_type = value
		notify_property_list_changed()

@export var npc_node_path: NodePath
@export var direction: MoveDirection = MoveDirection.DOWN
@export var movement_type: MovementType = MovementType.TIME_BASED

## Duration in seconds (used if movement_type is TIME_BASED)
@export var duration: float = 1.0

## Distance in 32px tiles (used if movement_type is TILE_BASED)
@export var tiles: int = 1

## Speed override specifically for the Player during this command.
@export var player_speed: float = 50.0

## If true, the event waits for the target to finish moving before running next commands
@export var wait_for_completion: bool = true

func execute() -> Signal:
	var entity = null
	if target_type == TargetType.PLAYER:
		entity = PlayerManager.get_player()
	else:
		var base_node = Engine.get_main_loop().current_scene
		if EventManager.current_context_node:
			base_node = EventManager.current_context_node

		if not base_node:
			return Engine.get_main_loop().process_frame

		entity = base_node.get_node_or_null(npc_node_path)
		if not entity and EventManager.current_context_node:
			var scene_root = Engine.get_main_loop().current_scene
			if scene_root:
				entity = scene_root.get_node_or_null(npc_node_path)

	if entity and entity.has_method("move_externally"):
		var dir_vector = Vector2.ZERO
		match direction:
			MoveDirection.UP:
				dir_vector = Vector2.UP
			MoveDirection.DOWN:
				dir_vector = Vector2.DOWN
			MoveDirection.LEFT:
				dir_vector = Vector2.LEFT
			MoveDirection.RIGHT:
				dir_vector = Vector2.RIGHT

		# Check if turning only (tiles is 0 or duration is 0)
		var is_turning_only = false
		if movement_type == MovementType.TIME_BASED and duration <= 0.0:
			is_turning_only = true
		elif movement_type == MovementType.TILE_BASED and tiles == 0:
			is_turning_only = true

		if is_turning_only:
			if entity.has_method("set_direction"):
				entity.set_direction(dir_vector)
			return Engine.get_main_loop().process_frame

		# Calculate active speed
		var active_speed = 50.0
		if target_type == TargetType.PLAYER and player_speed > 0.0:
			active_speed = player_speed
		else:
			if "speed" in entity:
				active_speed = entity.speed
			if active_speed <= 0.0:
				active_speed = 50.0

		# Calculate dynamic duration
		var final_duration = duration
		if movement_type == MovementType.TILE_BASED:
			final_duration = (tiles * 32.0) / active_speed

		var initial_pos = entity.global_position
		var movement_desc = "Time-based (" + str(duration) + "s)" if movement_type == MovementType.TIME_BASED else "Tile-based (" + str(tiles) + " tiles)"
		print("[DEBUG MoveNPC] BEFORE - Entity: ", entity.name, " | Pos: ", initial_pos, " | Speed: ", active_speed, " | Duration: ", final_duration, " | ", movement_desc)

		# Execute external movement with the calculated custom speed
		entity.move_externally(dir_vector, final_duration, active_speed)
		
		if wait_for_completion:
			var timer = Engine.get_main_loop().create_timer(final_duration)
			timer.timeout.connect(func():
				var final_pos = entity.global_position
				var diff = final_pos - initial_pos
				print("[DEBUG MoveNPC] AFTER - Entity: ", entity.name, " | Pos: ", final_pos, " | Diff: ", diff)
			)
			return timer.timeout
	else:
		push_error("CommandMoveNPC: Target entity not found or does not support external movement: ", npc_node_path if target_type == TargetType.NPC else "Player")

	return Engine.get_main_loop().process_frame

func _validate_property(property: Dictionary) -> void:
	if target_type == TargetType.PLAYER:
		if property.name == "npc_node_path":
			property.usage = PROPERTY_USAGE_NO_EDITOR
	else:
		if property.name == "player_speed":
			property.usage = PROPERTY_USAGE_NO_EDITOR

func _to_string() -> String:
	var target_desc = "Player" if target_type == TargetType.PLAYER else str(npc_node_path).get_file()
	
	# Check if turning only (tiles is 0 or duration is 0)
	var is_turning_only = false
	if movement_type == MovementType.TIME_BASED and duration <= 0.0:
		is_turning_only = true
	elif movement_type == MovementType.TILE_BASED and tiles == 0:
		is_turning_only = true

	if is_turning_only:
		return "Turn: " + target_desc + " " + MoveDirection.keys()[direction]

	var move_desc = ""
	if movement_type == MovementType.TIME_BASED:
		move_desc = str(duration) + "s"
	else:
		move_desc = str(tiles) + " tiles"
		
	var wait_desc = "" if wait_for_completion else " (No Wait)"
	return "Move: " + target_desc + " " + MoveDirection.keys()[direction] + " " + move_desc + wait_desc
