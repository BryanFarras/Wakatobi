extends CharacterBody2D

# Signals
signal oxygen_changed(current: float, max_value: float)
signal weight_changed(current: float, limit: float)
signal depth_changed(depth: float)
signal score_changed(score: int)
signal player_fainted

# Movement Exports
@export_group("Movement Physics")
## Normal swimming speed (pixels/sec)
@export var normal_speed: float = 160.0
## Swimming speed when dashing (pixels/sec)
@export var dash_speed: float = 280.0
## Acceleration rate (lerp factor)
@export var acceleration: float = 5.0
## Friction/damping rate when no input is pressed (lerp factor)
@export var friction: float = 3.0

# Oxygen System Exports
@export_group("Oxygen System")
## Maximum oxygen level (doubles as health and time)
@export var max_oxygen: float = 100.0
## Passive oxygen depletion per second
@export var passive_depletion_rate: float = 0.8
## Oxygen depletion per second while dashing
@export var dash_depletion_rate: float = 4.5

# Weight System Exports
@export_group("Weight System")
## Weight limit (kg) before movement penalty is applied
@export var weight_limit: float = 30.0
## Speed multiplier penalty applied per kg over the limit
@export var weight_penalty_factor: float = 0.02

# Depth Tracker Exports
@export_group("Depth Tracking")
## The Y position representing the water surface (depth = 0)
@export var water_surface_y: float = 0.0
## Scale factor to convert pixels to depth meters
@export var depth_scale: float = 0.05

# Internal State Variables
var current_oxygen: float = 100.0
var current_weight: float = 0.0
var score: int = 0
var is_dashing: bool = false
var is_fainted: bool = false
var is_interacting: bool = false # Managed by InteractingComponent compatibility

# Onready Node References
@onready var visuals: Node2D = $Visuals
@onready var bubble_particles: CPUParticles2D = $Visuals/BubbleParticles

func _ready() -> void:
	# Add to global group
	add_to_group("player")
	
	# Override PlayerManager player reference so existing scripts find us
	PlayerManager._player = self
	
	# Initialize values
	current_oxygen = max_oxygen
	oxygen_changed.emit(current_oxygen, max_oxygen)
	weight_changed.emit(current_weight, weight_limit)
	score_changed.emit(score)
	
	if bubble_particles:
		bubble_particles.emitting = false

func _physics_process(delta: float) -> void:
	if is_fainted:
		# Slow drag to a stop, then slowly sink or float
		velocity = velocity.move_toward(Vector2(0, 15.0), 20.0 * delta)
		move_and_slide()
		return

	# If interacting with dialogue/sign UI, decelerate and stop
	if is_interacting:
		velocity = velocity.move_toward(Vector2.ZERO, normal_speed * friction * delta)
		move_and_slide()
		if bubble_particles:
			bubble_particles.emitting = false
		return

	# Handle Oxygen depletion
	_handle_oxygen(delta)

	# Get movement input (8-way)
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Determine dash state
	is_dashing = input_vector.length() > 0 and (Input.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SHIFT))

	# Calculate movement target
	if input_vector.length() > 0:
		var current_max_speed = dash_speed if is_dashing else normal_speed
		# Apply cargo weight slowdown penalty
		current_max_speed *= _get_weight_speed_multiplier()
		
		var target_velocity = input_vector.normalized() * current_max_speed
		velocity = velocity.lerp(target_velocity, acceleration * delta)
		
		# Visual trail: emit bubbles while moving
		if bubble_particles:
			bubble_particles.emitting = true
			# Increase bubble rate when sprinting
			bubble_particles.amount = 30 if is_dashing else 15
	else:
		# Smooth damping
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		if bubble_particles:
			bubble_particles.emitting = false

	move_and_slide()
	
	# Update visual orientation (flipping & tilting)
	_handle_visuals(delta)
	
	# Track depth based on global Y coordinate
	_handle_depth()

func _handle_oxygen(delta: float) -> void:
	var depletion_rate = dash_depletion_rate if is_dashing else passive_depletion_rate
	current_oxygen -= depletion_rate * delta
	
	if current_oxygen <= 0.0:
		current_oxygen = 0.0
		_faint()
	
	oxygen_changed.emit(current_oxygen, max_oxygen)

func _handle_visuals(delta: float) -> void:
	if velocity.length() > 5.0:
		# Flip sprite based on movement direction
		if velocity.x < -1.0:
			visuals.scale.x = -1
		elif velocity.x > 1.0:
			visuals.scale.x = 1
			
		# Tilting effect: Dave the Diver tilts up/down while swimming
		var angle = velocity.angle()
		# Adjust rotation calculation based on horizontal flipping
		var target_rot = angle
		if visuals.scale.x < 0:
			target_rot = angle + PI
			# Map angle correctly between -PI and PI
			if target_rot > PI:
				target_rot -= 2 * PI
		
		# Clamp visual tilt so the diver doesn't go upside down
		target_rot = clamp(target_rot, -0.45, 0.45)
		visuals.rotation = lerp_angle(visuals.rotation, target_rot, 8.0 * delta)
	else:
		# Return to upright position when standing still
		visuals.rotation = lerp_angle(visuals.rotation, 0.0, 6.0 * delta)

func _handle_depth() -> void:
	var current_depth = max(0.0, (global_position.y - water_surface_y) * depth_scale)
	depth_changed.emit(current_depth)

func _get_weight_speed_multiplier() -> float:
	if current_weight <= weight_limit:
		return 1.0
	
	var excess = current_weight - weight_limit
	var penalty = excess * weight_penalty_factor
	return max(0.35, 1.0 - penalty) # Caps minimum speed at 35% of normal

func _faint() -> void:
	is_fainted = true
	if bubble_particles:
		bubble_particles.emitting = false
	
	# Visual indication of fainting (rotate player upside down)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "rotation", PI, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "modulate", Color(0.7, 0.7, 0.8, 1.0), 1.0)
	
	player_fainted.emit()
	print("Diver has fainted from oxygen depletion!")

# Public API for Collectibles / Refills

func refill_oxygen(amount: float, full_refill: bool = false) -> void:
	if is_fainted:
		return
		
	if full_refill:
		current_oxygen = max_oxygen
	else:
		current_oxygen = min(max_oxygen, current_oxygen + amount)
	
	oxygen_changed.emit(current_oxygen, max_oxygen)
	print("Oxygen refilled: %s / %s" % [current_oxygen, max_oxygen])

func add_cargo_weight(amount: float) -> void:
	if is_fainted:
		return
		
	current_weight += amount
	weight_changed.emit(current_weight, weight_limit)
	print("Added weight: %s kg (total: %s kg)" % [amount, current_weight])

func add_score(amount: int) -> void:
	if is_fainted:
		return
		
	score += amount
	score_changed.emit(score)
	print("Score increased: %s (total: %s)" % [amount, score])
