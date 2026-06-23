extends CharacterBody2D

# ============================================================
# player_body.gd — Pasang di Player.tscn
#
# Scene tree:
#   Player (CharacterBody2D)  ← script ini
#   ├── CollisionShape2D
#   ├── Sprite2D
#   ├── PhantomCamera2D         ← PCam gameplay, priority: 10
#   │   (Follow Mode: Glued/Simple, target: Player)
#   ├── InventoryPCam           ← PCam inventory, priority: 0 saat idle
#   │   (PhantomCamera2D)
#   │   (Follow Mode: Glued/Simple, target: Player)  ← ikut player
#   │   (Zoom: e.g. Vector2(2.0, 2.0))              ← zoom in
#   │   (Offset: x positif, e.g. Vector2(-200, 0))  ← geser player ke kanan
#   │   (Tween duration: 0.5, Transition: Sine, Ease: In Out)
#   ├── InteractingComponent (Node2D)
#   │   ├── DetectionArea (Area2D)
#   │   │   └── CollisionShape2D
#   │   └── Label
#   └── InventoryUI (CanvasLayer)  ← instance InventoryUI.tscn, layer: 10
# ============================================================

@export var speed: float = 150.0
@export var run_speed: float = 250.0

## Priority PCam inventory saat terbuka — lebih tinggi dari PCam gameplay (10)
@export var inventory_pcam_active_priority: int = 20
## Priority PCam inventory saat tertutup
@export var inventory_pcam_inactive_priority: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var inventory_pcam: Node2D = $InventoryPCam
@onready var inventory_ui: CanvasLayer = $InventoryUI
@onready var animation_tree: AnimationTree = %AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_direction: Vector2 = Vector2.DOWN
var is_interacting: bool = false

# Reference to AudioManager autoload
var audio_manager := AudioManager

# Track footstep state
var _was_moving: bool = false
var _current_surface: String = "sand" # TODO: Replace with actual surface detection

func _ready() -> void:
	add_to_group("player")
	inventory_pcam.set_priority(inventory_pcam_inactive_priority)
	inventory_pcam.set_tween_on_load(false)

func _unhandled_input(event: InputEvent) -> void:
	if SceneManager.is_transitioning:
		return
		
	if event.is_action_pressed("inventory"):
		if is_interacting:
			_close_inventory()
		else:
			_open_inventory()

func _physics_process(_delta: float) -> void:
	if is_interacting or SceneManager.is_transitioning:
		velocity = Vector2.ZERO
		return

	var is_running = Input.is_key_pressed(KEY_SHIFT)
	var current_speed = run_speed if is_running else speed

	var input_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		last_direction = input_dir
		velocity = input_dir * current_speed

		# Adjust footstep interval and animation speed scale when moving
		audio_manager.sfx_character.footstep_interval = 0.25 if is_running else 0.4
		animation_player.speed_scale = 1.6 if is_running else 1.0

		# Play footstep SFX if just started moving
		if not _was_moving:
			audio_manager.play_footstep(_current_surface)
			_was_moving = true
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_speed * 0.2)

		# Stop footstep SFX if just stopped moving
		if _was_moving:
			audio_manager.sfx_character.stop_footstep()
			_was_moving = false
			# Reset animation speed scale when idle
			animation_player.speed_scale = 1.0

	move_and_slide()
	global_position = global_position.snapped(Vector2(0.1, 0.1))
	_handle_animation()

# -------------------------------------------------------
# Inventory
# -------------------------------------------------------

func _open_inventory() -> void:
	is_interacting = true
	inventory_pcam.set_priority(inventory_pcam_active_priority)

	var tween_duration: float = inventory_pcam.get_tween_duration()
	await get_tree().create_timer(tween_duration).timeout
	inventory_ui.show()

func _close_inventory() -> void:
	inventory_ui.hide()
	inventory_pcam.set_priority(inventory_pcam_inactive_priority)

	var tween_duration: float = inventory_pcam.get_tween_duration()
	await get_tree().create_timer(tween_duration).timeout
	is_interacting = false

# -------------------------------------------------------
# Animation
# -------------------------------------------------------

func set_direction(dir: Vector2) -> void:
	last_direction = dir
	_handle_animation()

func _handle_animation() -> void:
	var is_moving: bool = velocity.length() > 0
	
	# Update kondisi state machine
	animation_tree.set("parameters/conditions/walk", is_moving)
	animation_tree.set("parameters/conditions/idle", not is_moving)

	# Blend position butuh nilai -1, 0, atau 1 yang stabil
	# Kita bulatkan last_direction agar tidak ada nilai diagonal yang nanggung
	var blend_pos = Vector2(
		round(last_direction.x),
		round(last_direction.y)
	)

	animation_tree.set("parameters/idle/blend_position", blend_pos)
	animation_tree.set("parameters/walk/blend_position", blend_pos)
