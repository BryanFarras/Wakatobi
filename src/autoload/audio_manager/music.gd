extends AudioStreamPlayer2D

@export var music_clips: Array[AudioStream] = []

func play_music(clip_index: int) -> void:
	if clip_index >= 0 and clip_index < music_clips.size() and music_clips[clip_index] != null:
		stream = music_clips[clip_index]
		play()
	else:
		push_warning("Music track index %d not found in music_clips array or is null!" % clip_index)

func stop_music() -> void:
	stop()
