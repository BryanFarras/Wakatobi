# show_balloon_command.gd
class_name CommandShowBalloon
extends EventCommand

enum TargetType { PLAYER, NPC }
enum BalloonType {
	EXCLAMATION = 0,
	QUESTION = 1,
	MUSIC_NOTE = 2,
	HEART = 3,
	ANGER = 4,
	SWEAT = 5,
	FRUSTRATION = 6,
	SILENCE = 7,
	IDEA = 8,
	SLEEP = 9
}

@export var target_type: TargetType = TargetType.NPC
@export var npc_node_path: NodePath
@export var balloon_type: BalloonType = BalloonType.EXCLAMATION
@export var vertical_offset: float = -36.0
@export var wait_for_completion: bool = true

func execute() -> Signal:
	# Find target node
	var target_node: Node2D = null
	if target_type == TargetType.PLAYER:
		target_node = PlayerManager.get_player()
	else:
		var base_node = Engine.get_main_loop().current_scene
		if EventManager.current_context_node:
			base_node = EventManager.current_context_node
		
		if base_node:
			target_node = base_node.get_node_or_null(npc_node_path)
			if not target_node and EventManager.current_context_node:
				var scene_root = Engine.get_main_loop().current_scene
				if scene_root:
					target_node = scene_root.get_node_or_null(npc_node_path)

	if not target_node:
		push_error("CommandShowBalloon: Target node not found!")
		return Engine.get_main_loop().process_frame

	# Instantiate balloon sprite
	var balloon = Sprite2D.new()
	balloon.texture = load("res://assets/Sample Project/Graphics/System/Balloon2.png")
	if not balloon.texture:
		push_error("CommandShowBalloon: Balloon2.png not found!")
		balloon.queue_free()
		return Engine.get_main_loop().process_frame
		
	balloon.hframes = 8
	balloon.vframes = 10
	balloon.frame_coords = Vector2i(0, int(balloon_type))
	balloon.position = Vector2(0, vertical_offset)
	target_node.add_child(balloon)

	# Execute the animation in a deferred loop or coroutine
	var tree = target_node.get_tree()
	
	if wait_for_completion:
		# If we wait, we run the animation inline using await
		for frame in range(8):
			if not is_instance_valid(balloon):
				break
			balloon.frame_coords = Vector2i(frame, int(balloon_type))
			await tree.create_timer(0.075).timeout
		if is_instance_valid(balloon):
			balloon.queue_free()
		return Engine.get_main_loop().process_frame
	else:
		# If we don't wait, we run the animation asynchronously (background task)
		_run_async_animation(balloon, int(balloon_type), tree)
		return Engine.get_main_loop().process_frame

func _run_async_animation(balloon: Sprite2D, row_index: int, tree: SceneTree) -> void:
	for frame in range(8):
		if not is_instance_valid(balloon):
			return
		balloon.frame_coords = Vector2i(frame, row_index)
		await tree.create_timer(0.075).timeout
	if is_instance_valid(balloon):
		balloon.queue_free()

func _to_string() -> String:
	var target_str = "Player" if target_type == TargetType.PLAYER else str(npc_node_path)
	var wait_str = "" if wait_for_completion else " (No Wait)"
	return "Show Balloon: " + BalloonType.keys()[balloon_type] + " on " + target_str + wait_str
