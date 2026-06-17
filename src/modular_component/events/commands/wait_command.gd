# command_wait.gd
class_name CommandWait
extends EventCommand

@export var wait_time: float = 1.0

func execute() -> Signal:
	# Creates a timer in the scene tree and returns its timeout signal
	return Engine.get_main_loop().create_timer(wait_time).timeout

func _to_string() -> String:
	return "Wait " + str(wait_time) + "s"
