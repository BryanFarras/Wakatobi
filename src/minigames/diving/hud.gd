extends CanvasLayer

@onready var oxygen_bar: ProgressBar = $Control/OxygenPanel/OxygenContainer/ProgressBar
@onready var oxygen_label: Label = $Control/OxygenPanel/OxygenContainer/Label
@onready var depth_label: Label = $Control/StatsPanel/StatsContainer/DepthLabel
@onready var weight_label: Label = $Control/StatsPanel/StatsContainer/WeightLabel
@onready var score_label: Label = $Control/StatsPanel/StatsContainer/ScoreLabel
@onready var fainted_screen: ColorRect = $Control/FaintedScreen
@onready var retry_button: Button = $Control/FaintedScreen/VBoxContainer/RetryButton

var _diver: CharacterBody2D = null
var _fill_stylebox: StyleBoxFlat

func _ready() -> void:
	# Hide fainted screen at startup
	fainted_screen.hide()
	retry_button.pressed.connect(_on_retry_pressed)
	
	# Create a custom stylebox for the progress bar fill to change colors programmatically
	_setup_oxygen_style()
	
	# Find and connect to diver signals
	_find_diver()

func _setup_oxygen_style() -> void:
	_fill_stylebox = StyleBoxFlat.new()
	_fill_stylebox.bg_color = Color(0.12, 0.68, 0.85, 1.0) # Aqua Cyan
	_fill_stylebox.corner_radius_top_left = 4
	_fill_stylebox.corner_radius_bottom_left = 4
	_fill_stylebox.corner_radius_top_right = 4
	_fill_stylebox.corner_radius_bottom_right = 4
	oxygen_bar.add_theme_stylebox_override("fill", _fill_stylebox)

func _find_diver() -> void:
	# Wait for PlayerManager and group initialization
	var diver = get_tree().get_first_node_in_group("player")
	if diver != null:
		_connect_diver(diver)
	else:
		await get_tree().process_frame
		diver = get_tree().get_first_node_in_group("player")
		if diver != null:
			_connect_diver(diver)

func _connect_diver(diver: CharacterBody2D) -> void:
	_diver = diver
	_diver.oxygen_changed.connect(_on_oxygen_changed)
	_diver.weight_changed.connect(_on_weight_changed)
	_diver.depth_changed.connect(_on_depth_changed)
	_diver.score_changed.connect(_on_score_changed)
	_diver.player_fainted.connect(_on_player_fainted)
	
	# Initialize UI
	_on_oxygen_changed(_diver.current_oxygen, _diver.max_oxygen)
	_on_weight_changed(_diver.current_weight, _diver.weight_limit)
	_on_depth_changed(0.0)
	_on_score_changed(_diver.score)

func _on_oxygen_changed(current: float, max_val: float) -> void:
	oxygen_bar.max_value = max_val
	oxygen_bar.value = current
	oxygen_label.text = "O2: %d / %d" % [int(current), int(max_val)]
	
	# Premium visual touch: color shifts depending on remaining O2
	var ratio = current / max_val
	if ratio > 0.45:
		_fill_stylebox.bg_color = Color(0.12, 0.68, 0.85, 1.0) # Aqua Cyan
	elif ratio > 0.20:
		_fill_stylebox.bg_color = Color(0.95, 0.55, 0.08, 1.0) # Amber Warning
	else:
		# Flash or red warning
		_fill_stylebox.bg_color = Color(0.88, 0.17, 0.17, 1.0) # Crimson Danger

func _on_weight_changed(current: float, limit: float) -> void:
	weight_label.text = "Cargo: %.1f / %.1f kg" % [current, limit]
	if current > limit:
		# Make it red to warn player
		weight_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	else:
		weight_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _on_depth_changed(depth: float) -> void:
	depth_label.text = "Depth: %.1f m" % depth

func _on_score_changed(score_val: int) -> void:
	score_label.text = "Cargo Value: $%d" % score_val

func _on_player_fainted() -> void:
	fainted_screen.show()
	fainted_screen.modulate.a = 0.0
	
	# Smooth fade-in of the game over UI
	var tween = create_tween()
	tween.tween_property(fainted_screen, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_retry_pressed() -> void:
	# Reload current scene to restart minigame
	get_tree().reload_current_scene()
