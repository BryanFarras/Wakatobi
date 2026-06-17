extends AudioStreamPlayer2D

@export var steps_sand: Array[AudioStream] = [null, null, null, null]
@export var steps_soil: Array[AudioStream] = [null, null, null, null]
@export var steps_wood: Array[AudioStream] = [null, null, null, null] 
@export var steps_grass: Array[AudioStream] = [null, null, null, null] 

@export var footstep_interval: float = 0.4

var _current_surface: String = ""
var _is_walking: bool = false
var _footstep_timer: Timer

func _ready() -> void:
	_footstep_timer = Timer.new()
	_footstep_timer.wait_time = footstep_interval
	_footstep_timer.one_shot = true
	_footstep_timer.timeout.connect(_on_footstep_timer_timeout)
	add_child(_footstep_timer)

func play_footstep(surface_type: String) -> void:
	var clips: Array[AudioStream] = []
	match surface_type.to_lower():
		"sand":
			clips = steps_sand
		"soil":
			clips = steps_soil
		"wood":
			clips = steps_wood
		"grass":
			clips = steps_grass
		_:
			push_warning("SFX Character: unknown surface type '%s'" % surface_type)
			return
		   
	var valid_clips = clips.filter(func(clip): return clip != null)
	if valid_clips.is_empty(): return
	_current_surface = surface_type
	_is_walking = true
	# If not already playing or timer is stopped, play immediately
	if not playing and _footstep_timer.is_stopped():
		_play_random_clip(valid_clips)
		_footstep_timer.start(footstep_interval)
   # If timer is stopped but still walking, restart timer
	elif _footstep_timer.is_stopped():
		_footstep_timer.start(footstep_interval)

func stop_footstep() -> void:
	_is_walking = false
	_current_surface = ""
	_footstep_timer.stop()
	# No need to call stop() since we don't reuse the same player

func _play_random_clip(valid_clips: Array[AudioStream]) -> void:
	var stream_to_play = valid_clips.pick_random()
	var player = AudioStreamPlayer2D.new()
	player.stream = stream_to_play
	player.position = position
	# Copy settings from SFX_Character
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = max_distance
	player.attenuation = attenuation
	player.max_polyphony = max_polyphony
	player.panning_strength = panning_strength
	player.bus = bus
	player.area_mask = area_mask
	# Add more settings as needed
	add_child(player)
	player.play()
	player.finished.connect(func():
		player.queue_free()
	)

func _on_footstep_timer_timeout() -> void:
	if _is_walking and _current_surface != "":
			play_footstep(_current_surface)


# Connect to the built-in finished signal to trigger the timer
func _on_finished() -> void:
	if _is_walking:
		_footstep_timer.start(footstep_interval)

func _notification(what: int) -> void:
	if what == NOTIFICATION_POSTINITIALIZE:
		if not is_connected("finished", _on_finished):
			finished.connect(_on_finished)
