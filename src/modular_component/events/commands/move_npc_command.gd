# command_move_npc.gd
class_name CommandMoveNPC
extends EventCommand

enum MoveDirection { UP, DOWN, LEFT, RIGHT }
enum MovementType { TIME_BASED, TILE_BASED }

@export var npc_node_path: NodePath
@export var direction: MoveDirection = MoveDirection.DOWN
@export var movement_type: MovementType = MovementType.TIME_BASED

## Duration in seconds (used if movement_type is TIME_BASED)
@export var duration: float = 1.0

## Distance in 32px tiles (used if movement_type is TILE_BASED)
@export var tiles: int = 1

## If true, the event waits for the NPC to finish moving before running next commands
@export var wait_for_completion: bool = true

func execute() -> Signal:
	var base_node = Engine.get_main_loop().current_scene
	if EventManager.current_context_node:
		base_node = EventManager.current_context_node

	if not base_node:
		return Engine.get_main_loop().process_frame

	var npc = base_node.get_node_or_null(npc_node_path)
	if not npc and EventManager.current_context_node:
		var scene_root = Engine.get_main_loop().current_scene
		if scene_root:
			npc = scene_root.get_node_or_null(npc_node_path)

	if npc and npc.has_method("move_externally"):
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

		# Calculate dynamic duration
		var final_duration = duration
		if movement_type == MovementType.TILE_BASED:
			var speed = 50.0
			if "speed" in npc:
				speed = npc.speed
			if speed <= 0.0:
				speed = 50.0
			final_duration = (tiles * 32.0) / speed

		npc.move_externally(dir_vector, final_duration)
		
		if wait_for_completion:
			return Engine.get_main_loop().create_timer(final_duration).timeout
	else:
		push_error("CommandMoveNPC: NPC node not found or does not support external movement: ", npc_node_path)

	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	var move_desc = ""
	if movement_type == MovementType.TIME_BASED:
		move_desc = str(duration) + "s"
	else:
		move_desc = str(tiles) + " tiles"
		
	var wait_desc = "" if wait_for_completion else " (No Wait)"
	return "Move NPC: " + str(npc_node_path) + " " + MoveDirection.keys()[direction] + " " + move_desc + wait_desc
