# event_manager.gd (Autoload)
extends Node

var is_processing_event: bool = false
var current_context_node: Node = null

func run_event_sequence(commands: Array[EventCommand], context_node: Node = null) -> void:
	if is_processing_event:
		return
		
	is_processing_event = true
	current_context_node = context_node
	
	var player = PlayerManager.get_player()
	if player:
		player.is_interacting = true

	# Use a while loop to allow jumping over commands
	var index = 0
	while index < commands.size():
		var cmd = commands[index]
		
		if cmd is CommandIf:
			var is_true = _evaluate_condition(cmd.condition)
			if is_true:
				index += 1 # Proceed naturally into the True branch
			else:
				# Jump to the Else or End marker
				index = _find_matching_marker(commands, index, true)
				
		elif cmd is CommandElse:
			# If the pointer naturally hits an Else, it means the True branch 
			# just finished executing. We must now skip over the False branch.
			index = _find_matching_marker(commands, index, false)
			
		elif cmd is CommandEnd:
			index += 1 # Do nothing, just move past the marker
			
		else:
			# Execute standard commands (Wait, Fade, Text, etc.)
			await cmd.execute()
			index += 1

	if player:
		player.is_interacting = false
		
	current_context_node = null
	is_processing_event = false

# Internal logic to parse the condition string
func _evaluate_condition(condition: String) -> bool:
	if condition.is_empty():
		return false
	var expr = Expression.new()
	if expr.parse(condition) == OK:
		var result = expr.execute([], null, true)
		if not expr.has_execute_failed() and typeof(result) == TYPE_BOOL:
			return result
	return false

# Scans the array forward to find the correct matching block marker
func _find_matching_marker(commands: Array[EventCommand], start_idx: int, stop_at_else: bool) -> int:
	var depth = 0
	for i in range(start_idx + 1, commands.size()):
		var cmd = commands[i]
		
		if cmd is CommandIf:
			depth += 1 # Track nested If statements
		elif cmd is CommandEnd:
			if depth == 0:
				return i # Jump exactly to the End command
			depth -= 1
		elif cmd is CommandElse and stop_at_else and depth == 0:
			return i + 1 # Jump to the command immediately after Else
			
	return commands.size() # Failsafe to end of sequence
