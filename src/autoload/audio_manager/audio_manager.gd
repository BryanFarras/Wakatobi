extends Node2D

@onready var sfx_character: AudioStreamPlayer2D = %SFX_Character
@onready var sfx_environtment: AudioStreamPlayer2D = %SFX_Environtment
@onready var sfx_ambience: AudioStreamPlayer2D = %SFX_Ambience
@onready var music: AudioStreamPlayer2D = %Music

func play_music(clip_index: int) -> void:
	if music:
		music.play_music(clip_index)

func stop_music() -> void:
	if music:
		music.stop_music()

func play_footstep(surface_type: String) -> void:
	if sfx_character:
		sfx_character.play_footstep(surface_type)

func play_environment_sound(env_type: String) -> void:
	if sfx_environtment:
		sfx_environtment.play_environment_sound(env_type)

func play_ambience(ambience_type: String) -> void:
	if sfx_ambience:
		sfx_ambience.play_ambience(ambience_type)
