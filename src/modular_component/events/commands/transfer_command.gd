# command_transfer.gd
@tool
class_name CommandTransfer
extends EventCommand

enum TransferType { SAME_SCENE, DIFFERENT_SCENE }
enum SpawnType { DOOR, COORDINATES }
enum CharacterDirection { NONE, UP, DOWN, LEFT, RIGHT }

@export var transfer_type: TransferType = TransferType.SAME_SCENE:
	set(value):
		transfer_type = value
		notify_property_list_changed()

@export var spawn_type: SpawnType = SpawnType.DOOR:
	set(value):
		spawn_type = value
		notify_property_list_changed()

@export var target_direction: CharacterDirection = CharacterDirection.NONE

## Koordinat tile tujuan (X, Y - masing-masing berukuran 32x32 piksel)
@export var target_tile: Vector2i = Vector2i.ZERO

## Path scene tujuan (.tscn file)
@export_file("*.tscn") var target_scene_path: String = ""

## ID pintu tujuan (dipakai jika spawn_type adalah DOOR)
@export var door_id: String = ""

## Posisi piksel kustom (Legacy - dipakai jika target_tile kosong)
@export var local_position: Vector2 = Vector2.ZERO

## Key scene tujuan (Legacy - jika target_scene_path diisi, key ini diabaikan)
@export var scene_key: String = ""

func execute() -> Signal:
	# Hitung koordinat piksel tujuan
	var pixel_pos := local_position
	if target_tile != Vector2i.ZERO:
		pixel_pos = Vector2(target_tile.x * 32 + 16, target_tile.y * 32 + 16)

	var player = PlayerManager.get_player()

	# Set player direction if specified
	if target_direction != CharacterDirection.NONE:
		var dir_vector := Vector2.DOWN
		match target_direction:
			CharacterDirection.UP: dir_vector = Vector2.UP
			CharacterDirection.DOWN: dir_vector = Vector2.DOWN
			CharacterDirection.LEFT: dir_vector = Vector2.LEFT
			CharacterDirection.RIGHT: dir_vector = Vector2.RIGHT
		
		# Set pending direction for spawning in different scenes
		PlayerManager.pending_direction = dir_vector
		
		# Set direction immediately on existing player instance
		if player and is_instance_valid(player):
			if player.has_method("set_direction"):
				player.set_direction(dir_vector)
			else:
				player.last_direction = dir_vector
				if player.has_method("_handle_animation"):
					player._handle_animation()

	if transfer_type == TransferType.SAME_SCENE:
		# Instantly move the player using your PlayerManager
		if player and is_instance_valid(player):
			print("[DEBUG Transfer] Teleporting Player to position: ", pixel_pos)
			player.global_position = pixel_pos
	else:
		# Resolve scene path (supporting both new path and legacy key)
		var final_scene_path := target_scene_path
		if final_scene_path.is_empty() and not scene_key.is_empty():
			final_scene_path = SceneManager.get_scene_path(scene_key)

		if final_scene_path.is_empty():
			push_error("CommandTransfer: target scene tidak terdefinisi!")
			return Engine.get_main_loop().process_frame

		if spawn_type == SpawnType.DOOR:
			SceneManager.go_to_door(final_scene_path, door_id)
		else:
			SceneManager.go_to_scene_position(final_scene_path, pixel_pos)
		
	# Note: SceneManager handles its own fades and scene changes asynchronously.
	# A DIFFERENT_SCENE transfer should ideally be the last command in your sequence, 
	# as the node holding this event sequence will be destroyed when the scene changes.
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	var desc := ""
	if transfer_type == TransferType.SAME_SCENE:
		desc = "Transfer (Same Scene) to " + str(target_tile)
	else:
		var scene_name = target_scene_path.get_file()
		if scene_name.is_empty() and not scene_key.is_empty():
			scene_name = scene_key
		if spawn_type == SpawnType.DOOR:
			desc = "Transfer to " + scene_name + " via Door " + door_id
		else:
			desc = "Transfer to " + scene_name + " at " + str(target_tile)
	
	if target_direction != CharacterDirection.NONE:
		var dir_str = ""
		match target_direction:
			CharacterDirection.UP: dir_str = "Up"
			CharacterDirection.DOWN: dir_str = "Down"
			CharacterDirection.LEFT: dir_str = "Left"
			CharacterDirection.RIGHT: dir_str = "Right"
		desc += " (Facing " + dir_str + ")"
	return desc

func _validate_property(property: Dictionary) -> void:
	if transfer_type == TransferType.SAME_SCENE:
		if property.name in ["spawn_type", "target_scene_path", "door_id", "local_position", "scene_key"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	else:
		if property.name in ["local_position", "scene_key"]:
			if property.name == "local_position" and local_position == Vector2.ZERO:
				property.usage = PROPERTY_USAGE_NO_EDITOR
			elif property.name == "scene_key" and scene_key.is_empty():
				property.usage = PROPERTY_USAGE_NO_EDITOR
				
		if spawn_type == SpawnType.DOOR:
			if property.name == "target_tile":
				property.usage = PROPERTY_USAGE_NO_EDITOR
		elif spawn_type == SpawnType.COORDINATES:
			if property.name == "door_id":
				property.usage = PROPERTY_USAGE_NO_EDITOR
