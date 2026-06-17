# command_fade.gd
class_name CommandFade
extends EventCommand

enum FadeType { FADE_IN, FADE_OUT }

@export var fade_type: FadeType = FadeType.FADE_OUT

func execute() -> Signal:
	if fade_type == FadeType.FADE_IN:
		return SceneManager.play_fade_animation("fade_in")
	else:
		return SceneManager.play_fade_animation("fade_out")

func _to_string() -> String:
	return "Fade In" if fade_type == FadeType.FADE_IN else "Fade Out"