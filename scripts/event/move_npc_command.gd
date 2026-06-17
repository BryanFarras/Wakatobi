# command_move_npc.gd
class_name CommandMoveNPC
extends EventCommand

enum MoveDirection { UP, DOWN, LEFT, RIGHT }

@export var npc_node_path: NodePath
@export var direction: MoveDirection = MoveDirection.DOWN
@export var duration: float = 1.0

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

		npc.move_externally(dir_vector, duration)
		return Engine.get_main_loop().create_timer(duration).timeout
	else:
		push_error("CommandMoveNPC: NPC node not found or does not support external movement: ", npc_node_path)

	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	return "Move NPC: " + str(npc_node_path) + " " + MoveDirection.keys()[direction] + " (" + str(duration) + "s)"
