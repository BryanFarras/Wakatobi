extends Area2D
class_name FishingHook

@export_group("Hook Physics")
## Sinking speed down the water column (pixels/second)
@export var sink_speed: float = 120.0
## Steering speed multiplier for horizontal movements
@export var steer_speed: float = 6.0
## Depth limit before hook is pulled back up (pixels)
@export var max_depth: float = 1800.0
## Left horizontal boundary clamping limit
@export var boundary_left: float = 50.0
## Right horizontal boundary clamping limit
@export var boundary_right: float = 1100.0

@onready var line_renderer: Line2D = $LineRenderer

var base_sink_speed: float = 120.0
var is_hook_active: bool = true
var target_x: float = 0.0

func _ready() -> void:
	base_sink_speed = sink_speed
	target_x = global_position.x
	# Connect collision signals
	area_entered.connect(_on_area_entered)
	
	# Setup procedural Line2D if not configured
	if line_renderer:
		line_renderer.width = 2.0
		line_renderer.default_color = Color(0.9, 0.9, 0.9, 0.7)

func _unhandled_input(event: InputEvent) -> void:
	if not is_hook_active:
		return
	if event is InputEventMouseMotion:
		if abs(event.relative.x) > 0.1:
			target_x = get_global_mouse_position().x

func _physics_process(delta: float) -> void:
	if not is_hook_active:
		return
		
	# 1. Automatic sinking
	global_position.y += sink_speed * delta
	
	# 2. Steerable X-axis
	var input_dir = Input.get_axis("ui_left", "ui_right")
	if input_dir != 0.0:
		# Keyboard steering
		global_position.x += input_dir * (steer_speed * 100.0) * delta
		target_x = global_position.x
	else:
		# Mouse/Touch steering (interpolates to target X position)
		global_position.x = lerp(global_position.x, target_x, steer_speed * delta)
		
	# Clamp positions within boundaries
	global_position.x = clamp(global_position.x, boundary_left, boundary_right)
	
	# 3. Maximum depth check (reset to top if nothing is caught)
	if global_position.y >= max_depth:
		_show_status_message("Kail ditarik kembali ke permukaan...")
		_reset_hook()

func _process(_delta: float) -> void:
	# Update the Line2D to draw from water surface (Y=0) to hook position
	if line_renderer and is_inside_tree():
		line_renderer.clear_points()
		# Local coordinates: Point 1 is at the surface, Point 2 is at the hook center
		line_renderer.add_point(Vector2(0.0, -global_position.y))
		line_renderer.add_point(Vector2.ZERO)

func _on_area_entered(area: Area2D) -> void:
	if not is_hook_active:
		return
		
	if area.is_in_group("fish"):
		_on_fish_hooked(area)

func _on_fish_hooked(fish: Area2D) -> void:
	is_hook_active = false
	sink_speed = 0.0 # Stop sinking physics
	
	var fish_name = fish.fish_name
	var item_id = fish.item_id
	var is_major = fish.is_major
	
	print("[FishingHook] Hooked: %s (ID: %s, Major: %s)" % [fish_name, item_id, str(is_major)])
	
	# Stop movement and trigger transition to Stardew Valley reeling minigame
	_show_status_message("IKAN TERSANGKUT! Bersiap menarik...")
	
	# Reparent the fish deferredly to avoid physics query flushing errors
	fish.call_deferred("reparent", self)
	fish.set_deferred("position", Vector2.ZERO)
	
	# Call level controller's transition method
	var level = get_tree().current_scene
	if level and level.has_method("trigger_major_fish_transition"):
		level.trigger_major_fish_transition(item_id)
	else:
		# Direct fallback
		var gameplay_manager = get_node_or_null("/root/GameplayManager")
		if gameplay_manager:
			var difficulty = 1.0
			if item_id == "yellow_tang": difficulty = 0.4
			elif item_id == "glofish": difficulty = 0.7
			elif item_id == "ikan_kakap": difficulty = 1.1
			elif item_id == "ikan_kakaktua": difficulty = 1.8
			gameplay_manager.start_fishing(difficulty, item_id)
		level.queue_free()

func _reset_hook() -> void:
	global_position.y = 50.0
	global_position.x = randf_range(boundary_left + 100.0, boundary_right - 100.0)
	target_x = global_position.x
	is_hook_active = true
	sink_speed = base_sink_speed
	_show_status_message("Turunkan kail... Hindari sampah, cari Ikan Kakaktua!")

func _show_status_message(msg: String) -> void:
	var level = get_tree().current_scene
	if level and level.has_method("update_status_label"):
		level.update_status_label(msg)

func _show_status_alert(msg: String) -> void:
	var level = get_tree().current_scene
	if level and level.has_method("show_hud_alert"):
		level.show_hud_alert(msg)
