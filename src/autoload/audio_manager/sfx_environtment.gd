extends AudioStreamPlayer2D

@export var bushes_sounds: Array[AudioStream] = [null, null, null]
@export var beach_wave_sounds: Array[AudioStream] = [null, null, null]
@export var wind_sounds: Array[AudioStream] = [null, null, null]

func play_environment_sound(env_type: String) -> void:
	var clips: Array[AudioStream] = []
	
	match env_type.to_lower():
		"bushes":
			clips = bushes_sounds
		"beach_wave", "beach_waves":
			clips = beach_wave_sounds
		"wind":
			clips = wind_sounds
		_:
			push_warning("SFX Environment: unknown environment type '%s'" % env_type)
			return
			
	var valid_clips = clips.filter(func(clip): return clip != null)
	if valid_clips.is_empty():
		return
		
	stream = valid_clips.pick_random()
	play()
