# scroll_camera_command.gd
@tool
class_name CommandScrollCamera
extends EventCommand

enum ScrollType { FIXED_TILE, RELATIVE_TILE, RESET_TO_PLAYER }

@export var scroll_type: ScrollType = ScrollType.FIXED_TILE

@export_group("Fixed Coordinates")
## Target tile coordinates (32x32 pixels per tile)
@export var target_tile: Vector2i = Vector2i.ZERO

@export_group("Relative Offset")
## Relative offset in tiles (e.g. +3, -2) from current position
@export var relative_offset: Vector2i = Vector2i.ZERO

@export_group("Settings")
## Time in seconds for the camera scroll to complete
@export var duration: float = 1.0
## If true, the event sequence waits for the scroll to finish before continuing
@export var wait_for_completion: bool = true
## Custom zoom level for the scroll (e.g. Vector2(2, 2)). Leave at Vector2.ZERO to automatically inherit the current active camera's zoom level.
@export var zoom: Vector2 = Vector2.ZERO

static var active_temp_pcam: PhantomCamera2D = null

func execute() -> Signal:
	if scroll_type == ScrollType.RESET_TO_PLAYER:
		if is_instance_valid(active_temp_pcam):
			var pcam_to_free = active_temp_pcam
			active_temp_pcam = null
			
			pcam_to_free.tween_duration = duration
			pcam_to_free.set_priority(0)
			
			var timer = Engine.get_main_loop().create_timer(duration)
			timer.timeout.connect(func():
				if is_instance_valid(pcam_to_free):
					pcam_to_free.queue_free()
			)
			
			if wait_for_completion:
				return timer.timeout
		
		return Engine.get_main_loop().process_frame

	# Calculate target position in pixel space
	var target_pos := Vector2.ZERO
	if scroll_type == ScrollType.FIXED_TILE:
		target_pos = Vector2(target_tile.x * 32 + 16, target_tile.y * 32 + 16)
	elif scroll_type == ScrollType.RELATIVE_TILE:
		# Calculate relative to current camera center
		var current_cam_pos := Vector2.ZERO
		var hosts = PhantomCameraManager.get_phantom_camera_hosts()
		if hosts.size() > 0:
			current_cam_pos = hosts[0].camera_2d.global_position
		else:
			var player = PlayerManager.get_player()
			if player and is_instance_valid(player):
				current_cam_pos = player.global_position
		target_pos = current_cam_pos + Vector2(relative_offset.x * 32, relative_offset.y * 32)

	# Determine correct zoom level (default to copying the current active camera)
	var target_zoom := Vector2.ONE
	var current_cam_pos := Vector2.ZERO
	var hosts = PhantomCameraManager.get_phantom_camera_hosts()
	if hosts.size() > 0:
		current_cam_pos = hosts[0].camera_2d.global_position
		var active_pcam = hosts[0].get_active_pcam()
		if is_instance_valid(active_pcam) and active_pcam != active_temp_pcam:
			target_zoom = active_pcam.zoom
		elif is_instance_valid(active_temp_pcam):
			target_zoom = active_temp_pcam.zoom
	else:
		var player = PlayerManager.get_player()
		if player and is_instance_valid(player):
			current_cam_pos = player.global_position

	# Override zoom if a custom value was specified
	if zoom != Vector2.ZERO:
		target_zoom = zoom

	# If active_temp_pcam is invalid, create a new one
	if not is_instance_valid(active_temp_pcam):
		active_temp_pcam = PhantomCamera2D.new()
		var root_scene = Engine.get_main_loop().current_scene
		root_scene.add_child(active_temp_pcam)
		
		# Set initial position to current camera position to prevent snapping
		active_temp_pcam.global_position = current_cam_pos
	
	active_temp_pcam.follow_mode = 0 # FollowMode.NONE
	active_temp_pcam.tween_duration = duration
	active_temp_pcam.zoom = target_zoom
	active_temp_pcam.global_position = target_pos
	active_temp_pcam.set_priority(30) # Override existing cameras (typically 10-20)
	
	if wait_for_completion:
		return Engine.get_main_loop().create_timer(duration).timeout
		
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	match scroll_type:
		ScrollType.RESET_TO_PLAYER:
			return "Scroll Camera: Reset to Player (%s s)" % str(duration)
		ScrollType.FIXED_TILE:
			return "Scroll Camera: Fixed Tile %s (%s s)" % [str(target_tile), str(duration)]
		ScrollType.RELATIVE_TILE:
			return "Scroll Camera: Relative Tile %s (%s s)" % [str(relative_offset), str(duration)]
	return "Scroll Camera"
