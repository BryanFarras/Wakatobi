# command_transfer.gd
class_name CommandTransfer
extends EventCommand

enum TransferType { SAME_SCENE, DIFFERENT_SCENE }

@export var transfer_type: TransferType = TransferType.SAME_SCENE
@export var local_position: Vector2 = Vector2.ZERO
@export var scene_key: String = ""
@export var door_id: String = ""

func execute() -> Signal:
	if transfer_type == TransferType.SAME_SCENE:
		# Instantly move the player using your PlayerManager
		var player = PlayerManager.get_player()
		if player:
			player.global_position = local_position
	else:
		# Trigger the scene transition using your SceneManager
		SceneManager.go_to_door(scene_key, door_id)
		
	# Note: SceneManager.go_to_door handles its own fades and scene changes asynchronously.
	# A DIFFERENT_SCENE transfer should ideally be the last command in your sequence, 
	# as the node holding this event sequence will be destroyed when the scene changes.
	return Engine.get_main_loop().process_frame