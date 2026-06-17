# event_command.gd
class_name EventCommand
extends Resource

# This function must be overridden by specific commands.
# It returns a Signal so the EventManager can 'await' its completion.
func execute() -> Signal:
	# A dummy signal to return in the base class
	return Engine.get_main_loop().process_frame
