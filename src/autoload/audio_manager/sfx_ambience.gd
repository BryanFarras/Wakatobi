extends AudioStreamPlayer2D

@export var room_ambiences: Array[AudioStream] = [null, null, null]
@export var outdoor_ambiences: Array[AudioStream] = [null, null, null]
@export var ocean_ambiences: Array[AudioStream] = [null, null, null]

func play_ambience(ambience_type: String) -> void:
	var clips: Array[AudioStream] = []
	
	match ambience_type.to_lower():
		"room":
			clips = room_ambiences
		"outdoor":
			clips = outdoor_ambiences
		"ocean":
			clips = ocean_ambiences
		_:
			push_warning("SFX Ambience: unknown ambience type '%s'" % ambience_type)
			return
			
	var valid_clips = clips.filter(func(clip): return clip != null)
	if valid_clips.is_empty():
		return
		
	stream = valid_clips.pick_random()
	play()
