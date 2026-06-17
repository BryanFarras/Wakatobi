extends Control

## Signals emitted upon winning or losing the minigame.
signal fishing_success
signal fishing_failed

## The behavior profile of the fish, controlling its swimming patterns.
enum FishProfile {
	EASY_LAZY,
	MEDIUM_SMOOTH,
	HARD_ERRATIC,
	LEGENDARY_CHAOTIC
}

## The main state of the minigame.
enum GameState {
	START_SCREEN,
	PLAYING,
	WON,
	LOST
}

@export_group("Physics Settings")
## Acceleration downwards due to gravity (pixels/second^2).
@export var gravity: float = 600.0
## Acceleration upwards when player is holding key or mouse button (pixels/second^2).
@export var thrust: float = 900.0
## Damping factor simulating water friction. Higher values slow down momentum faster.
@export var damping: float = 1.6
## Velocity multiplier when bouncing off top or bottom boundaries.
@export var bounce_factor: float = 0.35

@export_group("Fish AI Settings")
## Base movement speed of the fish.
@export var fish_speed_base: float = 4.0
## Multiplier applied to fish speed when it executes erratic/sudden movements.
@export var erratic_multiplier: float = 2.2
## Minimum duration before the fish changes its movement state or target.
@export var fish_change_interval_min: float = 0.5
## Maximum duration before the fish changes its movement state or target.
@export var fish_change_interval_max: float = 1.8

@export_group("Game Rules")
## Percentage catch progress gained per second while fish is inside player's bar.
@export var progress_increase_rate: float = 30.0
## Percentage catch progress lost per second while fish is outside player's bar.
@export var progress_decrease_rate: float = 20.0
## Starting value of the catch progress (0 to 100). Exposes a buffer so game doesn't instantly end.
@export var starting_progress: float = 30.0

@export_group("UI Node Paths")
# Onready variables referencing the UI nodes within the scene tree.
@onready var game_panel: Panel = $GamePanel
@onready var track_container: Panel = $GamePanel/VBoxContainer/GameArea/TrackContainer
@onready var player_bobber: Panel = $GamePanel/VBoxContainer/GameArea/TrackContainer/PlayerBobber
@onready var fish_icon: Panel = $GamePanel/VBoxContainer/GameArea/TrackContainer/FishIcon
@onready var catch_progress_bar: ProgressBar = $GamePanel/VBoxContainer/GameArea/CatchProgress
@onready var status_label: Label = $GamePanel/VBoxContainer/StatusLabel
@onready var instruction_label: Label = $GamePanel/VBoxContainer/InstructionLabel
@onready var restart_button: Button = $GamePanel/VBoxContainer/RestartButton

# Difficulty Buttons
@onready var easy_btn: Button = $GamePanel/VBoxContainer/DifficultyContainer/EasyBtn
@onready var med_btn: Button = $GamePanel/VBoxContainer/DifficultyContainer/MedBtn
@onready var hard_btn: Button = $GamePanel/VBoxContainer/DifficultyContainer/HardBtn
@onready var legend_btn: Button = $GamePanel/VBoxContainer/DifficultyContainer/LegendBtn

# Physics/AI state variables
var bobber_y: float = 0.0
var bobber_velocity: float = 0.0
var bobber_height: float = 0.0

var fish_y: float = 0.0
var fish_target_y: float = 0.0
var fish_height: float = 0.0
var fish_timer: float = 0.0
var fish_state: String = "IDLE"
var fish_current_speed: float = 4.0

var current_progress: float = 30.0
var current_state: GameState = GameState.START_SCREEN
var selected_profile: FishProfile = FishProfile.MEDIUM_SMOOTH
var track_height: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
	# Connect difficulty select buttons
	easy_btn.pressed.connect(func(): set_difficulty(FishProfile.EASY_LAZY))
	med_btn.pressed.connect(func(): set_difficulty(FishProfile.MEDIUM_SMOOTH))
	hard_btn.pressed.connect(func(): set_difficulty(FishProfile.HARD_ERRATIC))
	legend_btn.pressed.connect(func(): set_difficulty(FishProfile.LEGENDARY_CHAOTIC))
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Duplicate styleboxes for progress bar and bobber to prevent altering global theme/resources
	if player_bobber.has_theme_stylebox_override("panel"):
		var original_sb = player_bobber.get_theme_stylebox("panel")
		player_bobber.add_theme_stylebox_override("panel", original_sb.duplicate())
		
	if catch_progress_bar.has_theme_stylebox_override("fill"):
		var original_sb = catch_progress_bar.get_theme_stylebox("fill")
		catch_progress_bar.add_theme_stylebox_override("fill", original_sb.duplicate())
		
	# Setup initial game configuration
	set_difficulty(FishProfile.MEDIUM_SMOOTH)
	reset_game()

## Resets game UI and positions components at the center of the track.
func reset_game() -> void:
	current_state = GameState.START_SCREEN
	current_progress = starting_progress
	catch_progress_bar.value = current_progress
	
	# Fetch dimensions dynamically
	track_height = track_container.size.y
	bobber_height = player_bobber.size.y
	fish_height = fish_icon.size.y
	
	# Center elements
	bobber_y = (track_height - bobber_height) / 2.0
	bobber_velocity = 0.0
	player_bobber.position.y = bobber_y
	
	fish_y = (track_height - fish_height) / 2.0
	fish_target_y = fish_y
	fish_icon.position.y = fish_y
	
	status_label.text = "READY"
	status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	restart_button.text = "Cast Line"
	restart_button.show()
	
	# Allow selecting difficulty only outside of gameplay
	$GamePanel/VBoxContainer/DifficultyContainer.show()
	_update_difficulty_buttons_ui()

## Commences the active reel phase of the mini-game.
func start_game() -> void:
	current_state = GameState.PLAYING
	current_progress = starting_progress
	bobber_velocity = 0.0
	fish_timer = 0.0
	time_passed = 0.0
	
	restart_button.hide()
	$GamePanel/VBoxContainer/DifficultyContainer.hide()
	
	status_label.text = "REELING..."
	status_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

## Configures the fish movement parameters based on chosen difficulty.
func set_difficulty(profile: FishProfile) -> void:
	if current_state == GameState.PLAYING:
		return
	selected_profile = profile
	_update_difficulty_buttons_ui()

func _update_difficulty_buttons_ui() -> void:
	# Visual indicator of which difficulty is selected
	var active_color = Color(1.0, 1.0, 1.0, 1.0)
	var inactive_color = Color(0.5, 0.5, 0.5, 0.5)
	
	easy_btn.modulate = active_color if selected_profile == FishProfile.EASY_LAZY else inactive_color
	med_btn.modulate = active_color if selected_profile == FishProfile.MEDIUM_SMOOTH else inactive_color
	hard_btn.modulate = active_color if selected_profile == FishProfile.HARD_ERRATIC else inactive_color
	legend_btn.modulate = active_color if selected_profile == FishProfile.LEGENDARY_CHAOTIC else inactive_color

func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return
		
	time_passed += delta
	
	# Fetch sizes dynamically to ensure scaling safety
	track_height = track_container.size.y
	bobber_height = player_bobber.size.y
	fish_height = fish_icon.size.y
	
	_update_bobber_physics(delta)
	_update_fish_ai(delta)
	_update_game_logic(delta)

## Simulates gravity, thrust, damping and bouncing for the player green bar.
func _update_bobber_physics(delta: float) -> void:
	# Input checking: Holds space/enter or clicks/holds mouse left button
	var is_thrusting = Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if is_thrusting:
		bobber_velocity -= thrust * delta
	else:
		bobber_velocity += gravity * delta
		
	# Apply damping/friction
	bobber_velocity -= bobber_velocity * damping * delta
	
	# Integrate position
	bobber_y += bobber_velocity * delta
	
	# Clamp to bounds and trigger bounce
	var max_bobber_y = track_height - bobber_height
	if bobber_y <= 0.0:
		bobber_y = 0.0
		bobber_velocity = -bobber_velocity * bounce_factor
	elif bobber_y >= max_bobber_y:
		bobber_y = max_bobber_y
		bobber_velocity = -bobber_velocity * bounce_factor
		
	player_bobber.position.y = bobber_y

## Simple state machine simulating erratic and smooth movements of the fish.
func _update_fish_ai(delta: float) -> void:
	fish_timer -= delta
	var max_fish_y = track_height - fish_height
	
	# Reset target periodically
	if fish_timer <= 0.0:
		fish_timer = randf_range(fish_change_interval_min, fish_change_interval_max)
		
		match selected_profile:
			FishProfile.EASY_LAZY:
				fish_state = "SWIMMING"
				fish_current_speed = fish_speed_base * 0.75
				fish_target_y = randf_range(max_fish_y * 0.3, max_fish_y) # Prefers lower/deeper areas
				fish_timer += 0.4 # stays in state longer
				
			FishProfile.MEDIUM_SMOOTH:
				fish_state = "SWIMMING" if randf() > 0.2 else "IDLE"
				fish_current_speed = fish_speed_base
				fish_target_y = randf_range(0.0, max_fish_y)
				
			FishProfile.HARD_ERRATIC:
				var rand_val = randf()
				if rand_val < 0.2:
					fish_state = "IDLE"
				elif rand_val < 0.6:
					fish_state = "SWIMMING"
					fish_current_speed = fish_speed_base * 1.3
					fish_target_y = randf_range(0.0, max_fish_y)
				else:
					fish_state = "ERRATIC"
					fish_current_speed = fish_speed_base * erratic_multiplier
					fish_target_y = randf_range(0.0, max_fish_y)
					
			FishProfile.LEGENDARY_CHAOTIC:
				var rand_val = randf()
				if rand_val < 0.15:
					fish_state = "IDLE"
				elif rand_val < 0.45:
					fish_state = "SWIMMING"
					fish_current_speed = fish_speed_base * 1.6
					fish_target_y = randf_range(0.0, max_fish_y)
				else:
					fish_state = "DASH"
					fish_current_speed = fish_speed_base * erratic_multiplier * 1.4
					# Performs rapid large jumps to opposite side of current position
					if fish_y > max_fish_y * 0.5:
						fish_target_y = randf_range(0.0, max_fish_y * 0.3)
					else:
						fish_target_y = randf_range(max_fish_y * 0.7, max_fish_y)
						
	# Move towards current target position
	var lerp_speed = fish_current_speed
	fish_y = lerp(fish_y, fish_target_y, lerp_speed * delta)
	
	# Add wiggles/micro-movements to simulate swimming
	var wiggle = 0.0
	if fish_state == "ERRATIC":
		wiggle = sin(time_passed * 24.0) * 12.0
	elif fish_state == "DASH":
		wiggle = sin(time_passed * 36.0) * 20.0
	elif fish_state == "SWIMMING":
		wiggle = sin(time_passed * 7.0) * 4.0
		
	var visual_fish_y = clamp(fish_y + wiggle, 0.0, max_fish_y)
	fish_icon.position.y = visual_fish_y

## Updates Catch Progress based on whether the fish center falls inside the player's bobber bar.
func _update_game_logic(delta: float) -> void:
	var fish_center = fish_icon.position.y + fish_height / 2.0
	
	# Overlap calculation
	var is_catching = (fish_center >= bobber_y) and (fish_center <= bobber_y + bobber_height)
	
	if is_catching:
		current_progress += progress_increase_rate * delta
		status_label.text = "CATCHING!"
		status_label.add_theme_color_override("font_color", Color(0.25, 0.9, 0.45))
		
		# Make green bobber bar visually brighten (glowing effect)
		var style: StyleBoxFlat = player_bobber.get_theme_stylebox("panel")
		if style:
			style.bg_color = Color(0.2, 0.85, 0.4, 0.6)
			style.border_color = Color(0.4, 1.0, 0.6, 1.0)
	else:
		current_progress -= progress_decrease_rate * delta
		status_label.text = "SLIPPING!"
		status_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.2))
		
		# Dim the green bobber bar slightly
		var style: StyleBoxFlat = player_bobber.get_theme_stylebox("panel")
		if style:
			style.bg_color = Color(0.15, 0.6, 0.3, 0.35)
			style.border_color = Color(0.25, 0.8, 0.4, 0.7)
			
	# Enforce boundaries
	current_progress = clamp(current_progress, 0.0, 100.0)
	catch_progress_bar.value = current_progress
	
	# Polish: Change Progress Bar color (Red when critical, Yellow when halfway, Green when high)
	var sb: StyleBoxFlat = catch_progress_bar.get_theme_stylebox("fill")
	if sb:
		if current_progress < 35.0:
			sb.bg_color = Color(0.9, 0.25, 0.2)
		elif current_progress < 75.0:
			sb.bg_color = Color(0.95, 0.7, 0.15)
		else:
			sb.bg_color = Color(0.2, 0.8, 0.4)
			
	# Win / Loss detection
	if current_progress >= 100.0:
		end_game(true)
	elif current_progress <= 0.0:
		end_game(false)

## Ends the active reel, triggers relevant signals, and prompts user to restart.
func end_game(success: bool) -> void:
	if success:
		current_state = GameState.WON
		status_label.text = "SUCCESS!"
		status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		fishing_success.emit()
	else:
		current_state = GameState.LOST
		status_label.text = "FAILED!"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.2))
		fishing_failed.emit()
		
	restart_button.text = "Try Again"
	restart_button.show()
	$GamePanel/VBoxContainer/DifficultyContainer.show()

func _on_restart_pressed() -> void:
	if current_state != GameState.PLAYING:
		start_game()
