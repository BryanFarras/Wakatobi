extends CharacterBody2D

# States
enum State { ON_FOOT, BICYCLE, KAYAK }

# Export variables
@export_group("Vehicle State")
## Current player travel state
@export var current_state: State = State.ON_FOOT

@export_group("Foot Movement")
## Base walk speed on foot (pixels/sec)
@export var foot_speed: float = 130.0

@export_group("Bicycle Movement")
## Maximum bicycle speed on land (pixels/sec)
@export var bike_speed: float = 270.0
## Acceleration rate of the bicycle (lerp factor)
@export var bike_acceleration: float = 12.0
## Deceleration/braking rate of the bicycle (lerp factor)
@export var bike_friction: float = 8.0

@export_group("Kayak Movement")
## Base speed of the kayak on water (pixels/sec)
@export var kayak_speed: float = 160.0
## Low acceleration simulates heavy water inertia (lerp factor)
@export var kayak_acceleration: float = 2.0
## Low friction simulates boat sliding/drifting (lerp factor)
@export var kayak_friction: float = 0.9

@export_group("Wind Waker Sailing Physics")
## Global Wind Direction Vector (normalized in code)
@export var wind_vector: Vector2 = Vector2.RIGHT
## Wind strength affecting speed and drift
@export var wind_strength: float = 65.0
## Speed multiplier bonus when sailing in the same direction as the wind
@export var wind_boost_factor: float = 0.5
## Speed multiplier penalty when sailing against the wind
@export var wind_penalty_factor: float = 0.4
## Constant drift force multiplier pushing the boat in the wind's direction
@export var wind_drift_factor: float = 0.28

# Terrain checks
var is_in_water: bool = false
var is_near_water: bool = false # proximity to shoreline

# Onready node references
@onready var visuals: Node2D = $Visuals
@onready var visuals_foot: ColorRect = $Visuals/Foot
@onready var visuals_bike: Panel = $Visuals/Bike
@onready var visuals_kayak: Polygon2D = $Visuals/Kayak
@onready var terrain_detector: Area2D = $TerrainDetector

# HUD Node References
@onready var compass_arrow: Line2D = $HUD/WindCompass/VBox/CompassIcon/Arrow
@onready var wind_label: Label = $HUD/WindCompass/VBox/WindLabel
@onready var status_label: Label = $HUD/StatusPanel/VBox/StatusLabel
@onready var alert_label: Label = $HUD/AlertLabel

# Timer for fading alerts
var alert_fade_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	# Override PlayerManager just in case
	PlayerManager._player = self
	
	if alert_label:
		alert_label.text = ""
		
	# Setup initial visual states
	_update_visual_states()

func _physics_process(delta: float) -> void:
	# 1. Check terrain from Area2D overlapping zones
	_check_terrain()
	
	# 2. Check for automatic surfing (walking/riding into water triggers Kayak!)
	if (current_state == State.ON_FOOT or current_state == State.BICYCLE) and is_in_water:
		_transition_to_state(State.KAYAK)
		_show_alert("Menunggangi Kayak (Surfing!)")
		
	# 2b. Check for automatic landing (drifting onto dry land triggers Foot!)
	if current_state == State.KAYAK and not is_in_water and not is_near_water:
		_transition_to_state(State.ON_FOOT)
		_show_alert("Mendarat (Turun dari Kayak)")
		velocity = Vector2.ZERO
		
	# 3. Get direction input (8-Way WASD / Arrows)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 4. Handle Visual Flipping based on X input
	if input_dir.x < 0:
		visuals.scale.x = -1
	elif input_dir.x > 0:
		visuals.scale.x = 1
		
	# 5. Physics based on active state
	match current_state:
		State.ON_FOOT:
			_handle_foot_physics(input_dir, delta)
		State.BICYCLE:
			_handle_bike_physics(input_dir, delta)
		State.KAYAK:
			_handle_kayak_physics(input_dir, delta)
			
	move_and_slide()
	
	# 6. Keep visuals updated
	_update_visual_rotations(delta)
	
	# 7. Update HUD values
	_update_hud(delta)

func _check_terrain() -> void:
	is_in_water = false
	is_near_water = false
	
	if terrain_detector:
		var areas = terrain_detector.get_overlapping_areas()
		for area in areas:
			if area.is_in_group("water"):
				is_in_water = true
			if area.is_in_group("shore"):
				is_near_water = true

func _handle_foot_physics(input_dir: Vector2, delta: float) -> void:
	# Tight direct responsiveness for walking
	var target_vel = input_dir * foot_speed
	velocity = velocity.move_toward(target_vel, foot_speed * 8.0 * delta)

func _handle_bike_physics(input_dir: Vector2, delta: float) -> void:
	# High speed, tight handling (quick stops and sharp turns)
	var target_vel = input_dir * bike_speed
	if input_dir.length() > 0:
		velocity = velocity.move_toward(target_vel, bike_acceleration * bike_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, bike_friction * bike_speed * delta)

func _handle_kayak_physics(input_dir: Vector2, delta: float) -> void:
	var wind_dir = wind_vector.normalized()
	
	if input_dir.length() > 0:
		var move_dir = input_dir.normalized()
		# dot-product wind alignment: ranges from -1 (directly against) to 1 (directly with)
		var alignment = move_dir.dot(wind_dir)
		var speed_mod = 1.0
		
		if alignment > 0.0:
			# Sailing with the wind -> speed boost!
			speed_mod += alignment * wind_boost_factor * (wind_strength / 100.0)
		else:
			# Sailing against the wind -> resistance!
			speed_mod -= abs(alignment) * wind_penalty_factor * (wind_strength / 100.0)
			speed_mod = max(0.35, speed_mod) # Caps minimum sailing speed at 35%
			
		var target_vel = move_dir * kayak_speed * speed_mod
		velocity = velocity.lerp(target_vel, kayak_acceleration * delta)
	else:
		# Slow drift stop
		velocity = velocity.lerp(Vector2.ZERO, kayak_friction * delta)
		
	# Constant wind drift force pushes the kayak
	var drift_force = wind_dir * wind_strength * wind_drift_factor
	velocity += drift_force * delta
	
	# Clamp maximum velocity to prevent infinite drift acceleration
	velocity = velocity.limit_length(kayak_speed * 1.5)

func _update_visual_rotations(delta: float) -> void:
	if current_state == State.KAYAK:
		if velocity.length() > 10.0:
			# Align kayak boat polygon's rotation to its travel vector
			# Polygon is modeled pointing UP (Y negative = -PI/2 angle)
			var target_rot = velocity.angle() + PI/2
			visuals_kayak.rotation = lerp_angle(visuals_kayak.rotation, target_rot, 7.0 * delta)
	else:
		# Reset rotation when walking or biking
		visuals_kayak.rotation = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_M):
		_toggle_mount()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			# Rotate wind direction by 45 degrees clockwise
			wind_vector = wind_vector.rotated(PI / 4.0)
			_show_alert("Arah angin diputar!")
		elif event.keycode == KEY_F:
			# Cycle wind strength between 0, 30, 60, 90, 120
			if wind_strength <= 0.1:
				wind_strength = 30.0
			elif wind_strength <= 30.1:
				wind_strength = 60.0
			elif wind_strength <= 60.1:
				wind_strength = 90.0
			elif wind_strength <= 90.1:
				wind_strength = 120.0
			else:
				wind_strength = 0.0
			_show_alert("Kekuatan angin: %d" % int(wind_strength))

func _toggle_mount() -> void:
	match current_state:
		State.ON_FOOT:
			# Decide mount type based on terrain location
			if is_in_water or is_near_water:
				_transition_to_state(State.KAYAK)
				_show_alert("Menunggangi Kayak (Sailing)")
			else:
				_transition_to_state(State.BICYCLE)
				_show_alert("Menunggangi Sepeda (Cycling)")
		State.BICYCLE:
			# Can always dismount bicycle on land
			_transition_to_state(State.ON_FOOT)
			_show_alert("Turun dari Sepeda")
		State.KAYAK:
			# Pokemon style check: cannot dismount in deep water
			if is_near_water or not is_in_water:
				_transition_to_state(State.ON_FOOT)
				_show_alert("Turun dari Kayak")
				# Stop immediately on land to prevent sliding
				velocity = Vector2.ZERO
			else:
				_show_alert("Tidak bisa turun di air dalam!")

func _transition_to_state(new_state: State) -> void:
	current_state = new_state
	_update_visual_states()

func _update_visual_states() -> void:
	if not is_inside_tree(): return
	visuals_foot.visible = (current_state == State.ON_FOOT)
	visuals_bike.visible = (current_state == State.BICYCLE)
	visuals_kayak.visible = (current_state == State.KAYAK)
	
	if has_node("HUD/WindCompass"):
		$HUD/WindCompass.visible = (current_state == State.KAYAK)

func _show_alert(text: String) -> void:
	if alert_label:
		alert_label.text = text
		alert_label.modulate.a = 1.0
		alert_fade_timer = 2.0 # Show for 2 seconds

func _update_hud(delta: float) -> void:
	if not is_inside_tree(): return
	
	# Update Compass Arrow
	if compass_arrow:
		compass_arrow.rotation = wind_vector.angle()
		
	# Update wind cardinal labels
	if wind_label:
		wind_label.text = "Arah Angin: %s\nKekuatan: %d" % [_get_wind_direction_string(wind_vector), int(wind_strength)]
		
	# Update general status dashboard
	if status_label:
		var state_str = "Berjalan Kaki"
		if current_state == State.BICYCLE:
			state_str = "Bersepeda"
		elif current_state == State.KAYAK:
			state_str = "Berkayak (Berlayar)"
			
		var speed_text = "%d px/s" % int(velocity.length())
		
		# Describe wind alignment comfort level
		var wind_info = ""
		if current_state == State.KAYAK:
			var wind_dir = wind_vector.normalized()
			var move_dir = velocity.normalized()
			var alignment = move_dir.dot(wind_dir)
			if velocity.length() < 10.0:
				wind_info = "\nArus: Terbawa Angin"
			elif alignment > 0.35:
				wind_info = "\nBerlayar: Dengan Angin (Bantuan!)"
			elif alignment < -0.35:
				wind_info = "\nBerlayar: Melawan Angin (Hambatan)"
			else:
				wind_info = "\nBerlayar: Angin Samping"
				
		status_label.text = "Mode: %s\nKecepatan: %s%s" % [state_str, speed_text, wind_info]

	# Alert label fading
	if alert_label and alert_fade_timer > 0.0:
		alert_fade_timer -= delta
		if alert_fade_timer <= 0.0:
			alert_label.text = ""
		else:
			alert_label.modulate.a = clamp(alert_fade_timer / 0.5, 0.0, 1.0)

# Helper cardinal conversion
func _get_wind_direction_string(vec: Vector2) -> String:
	var angle = rad_to_deg(vec.angle())
	if angle < 0: angle += 360.0
	if angle >= 337.5 or angle < 22.5: return "Timur (East)"
	if angle >= 22.5 and angle < 67.5: return "Tenggara (Southeast)"
	if angle >= 67.5 and angle < 112.5: return "Selatan (South)"
	if angle >= 112.5 and angle < 157.5: return "Barat Daya (Southwest)"
	if angle >= 157.5 and angle < 202.5: return "Barat (West)"
	if angle >= 202.5 and angle < 247.5: return "Barat Laut (Northwest)"
	if angle >= 247.5 and angle < 292.5: return "Utara (North)"
	return "Timur Laut (Northeast)"
