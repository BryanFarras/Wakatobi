extends Node2D

@export_group("Spawning Config")
## Pre-packaged Fish Scene or base Area2D template
@export var fish_scene_path: String = "res://src/minigames/fishing/fish_behavior.tscn"
## Count of fish to spawn at startup
@export var spawn_counts: Dictionary = {
	"yellow_tang": 4,
	"glofish": 4,
	"ikan_kakap": 3,
	"ikan_kakaktua": 2
}

@export_group("Level Boundaries")
## Sinking boundaries for camera and hook positioning
@export var boundary_left: float = 50.0
@export var boundary_right: float = 1100.0
@export var max_depth: float = 1800.0

@onready var camera: Camera2D = $Camera2D
@onready var hook: Area2D = $Hook
@onready var fish_spawner: Node2D = $FishSpawner
@onready var depth_label: Label = $HUD/InfoPanel/VBox/DepthLabel
@onready var status_label: Label = $HUD/InfoPanel/VBox/StatusLabel
@onready var alert_label: Label = $HUD/AlertLabel
@onready var flash_rect: ColorRect = $HUD/FlashRect

# Camera shake properties
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var max_camera_y: float = 1500.0

# Alarm/alert fade
var alert_fade_timer: float = 0.0

func _ready() -> void:
	# Hide flash transition screen
	if flash_rect:
		flash_rect.modulate.a = 0.0
		flash_rect.hide()
		
	if alert_label:
		alert_label.text = ""
		
	# Populate fish
	_spawn_all_fish()
	
	update_status_label("Turunkan kail..., cari Ikan Kakaktua!")

func _physics_process(delta: float) -> void:
	# 1. Camera Vertical Tracking following Hook Y position
	if camera and hook:
		# Interpolate camera Y towards hook Y, locked horizontally
		var target_camera_y = hook.global_position.y
		# Clamped so camera does not show areas above sea level (Y=0) or below sea bed
		target_camera_y = clamp(target_camera_y, 300.0, max_depth - 300.0)
		camera.global_position.y = lerp(camera.global_position.y, target_camera_y, 5.0 * delta)
		
	# 2. Camera Shake logic
	if shake_timer > 0.0 and camera:
		shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_timer <= 0.0:
			camera.offset = Vector2.ZERO

	# 3. Update HUD depth label
	if depth_label and hook:
		# Convert pixels to depth meters
		var depth_m = int(hook.global_position.y / 15.0)
		depth_label.text = "Kedalaman: %d meter" % depth_m

	# 4. Alert fade timer
	if alert_fade_timer > 0.0 and alert_label:
		alert_fade_timer -= delta
		if alert_fade_timer <= 0.0:
			alert_label.text = ""
		else:
			alert_label.modulate.a = clamp(alert_fade_timer / 0.5, 0.0, 1.0)

# ==============================================================================
# Fish Spawner Logic
# ==============================================================================

func _spawn_all_fish() -> void:
	# Load the fish scene template dynamically
	var fish_scene = load(fish_scene_path)
	if not fish_scene:
		push_error("[PreFishingLevel] Fish template scene not found: " + fish_scene_path)
		return

	# Define depth zones and properties for each species
	var species_data = {
		"yellow_tang": {
			"name": "Yellow Tang",
			"is_major": false,
			"speed": 90.0,
			"y_min": 150.0,
			"y_max": 500.0,
			"color": Color(1.0, 0.85, 0.25, 1.0)
		},
		"glofish": {
			"name": "Glofish Tetra",
			"is_major": false,
			"speed": 110.0,
			"y_min": 200.0,
			"y_max": 550.0,
			"color": Color(0.2, 0.9, 0.35, 1.0)
		},
		"ikan_kakap": {
			"name": "Ikan Kakap",
			"is_major": false,
			"speed": 75.0,
			"y_min": 600.0,
			"y_max": 1100.0,
			"color": Color(0.95, 0.22, 0.22, 1.0)
		},
		"ikan_kakaktua": {
			"name": "Ikan Kakaktua",
			"is_major": true,
			"speed": 60.0,
			"y_min": 1150.0,
			"y_max": 1650.0,
			"color": Color(0.15, 0.72, 0.65, 1.0)
		}
	}

	for species_id in spawn_counts.keys():
		var count = spawn_counts[species_id]
		var data = species_data[species_id]
		
		for i in range(count):
			var fish_instance = fish_scene.instantiate() as Area2D
			
			# Configure custom attributes before entering tree
			fish_instance.item_id = species_id
			fish_instance.fish_name = data["name"]
			fish_instance.is_major = data["is_major"]
			fish_instance.speed = data["speed"]
			fish_instance.color = data["color"]
			
			# Position fish randomly within its designated depth zone
			var spawn_x = randf_range(boundary_left + 100.0, boundary_right - 100.0)
			var spawn_y = randf_range(data["y_min"], data["y_max"])
			fish_instance.global_position = Vector2(spawn_x, spawn_y)
			
			# Inject boundary clamping limits
			fish_instance.boundary_left = boundary_left
			fish_instance.boundary_right = boundary_right
			
			fish_spawner.add_child(fish_instance)

# ==============================================================================
# Visual Hooks & Callbacks
# ==============================================================================

func update_status_label(msg: String) -> void:
	if status_label:
		status_label.text = msg

func show_hud_alert(msg: String) -> void:
	if alert_label:
		alert_label.text = msg
		alert_label.modulate.a = 1.0
		alert_fade_timer = 2.0 # Show alert for 2 seconds

## Triggers camera shake, screen flash, and calls GameplayManager.start_fishing
func trigger_major_fish_transition(item_id: String) -> void:
	# Define difficulty and visuals based on item_id
	var difficulty: float = 1.0
	var alert_msg: String = "IKAN TERSANGKUT!"
	var intensity: float = 6.0
	
	match item_id:
		"yellow_tang":
			difficulty = 0.4
			alert_msg = "YELLOW TANG TERSANGKUT!"
			intensity = 4.0
		"glofish":
			difficulty = 0.7
			alert_msg = "GLOFISH TERSANGKUT!"
			intensity = 6.0
		"ikan_kakap":
			difficulty = 1.1
			alert_msg = "IKAN KAKAP TERSANGKUT!"
			intensity = 9.0
		"ikan_kakaktua", "ikan_kakatua":
			difficulty = 1.8
			alert_msg = "IKAN KAKAKTUA TERSANGKUT!"
			intensity = 15.0
			
	# 1. Play camera shake
	shake_timer = 1.4
	shake_intensity = intensity
	
	# 2. Flash screen
	if flash_rect:
		flash_rect.show()
		flash_rect.modulate.a = 1.0
		var flash_tween = create_tween()
		flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# 3. Alert HUD
	show_hud_alert(alert_msg)
	
	# 4. Wait for visual drama to finish, then transition into reel minigame
	await get_tree().create_timer(1.5).timeout
	
	var gameplay_manager = get_node_or_null("/root/GameplayManager")
	if gameplay_manager:
		var reward_id = item_id
		if reward_id == "ikan_kakatua":
			reward_id = "ikan_kakaktua"
		gameplay_manager.start_fishing(difficulty, reward_id)
		
	queue_free()

## Triggers floating catch notifications or small visual feedback when capturing bonus fish
func show_bonus_catch_effect(fish_name: String, pos: Vector2) -> void:
	# Add a floating label effect
	var floating_label = Label.new()
	floating_label.text = "+ " + fish_name
	floating_label.global_position = pos - Vector2(40.0, 20.0)
	floating_label.add_theme_font_size_override("font_size", 14)
	floating_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2, 1.0))
	add_child(floating_label)
	
	# Animate float up and fade out
	var tween = create_tween().set_parallel(true)
	tween.tween_property(floating_label, "global_position:y", floating_label.global_position.y - 60.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(floating_label, "modulate:a", 0.0, 0.8)
	
	# Clean up effect label
	tween.chain().tween_callback(floating_label.queue_free)
	
	show_hud_alert("Dapat " + fish_name + "!")
