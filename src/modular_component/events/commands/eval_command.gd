# command_eval.gd
class_name CommandEval
extends EventCommand

@export_multiline var expression_text: String = ""

func execute() -> Signal:
	if expression_text.is_empty():
		return Engine.get_main_loop().process_frame
		
	var expr = Expression.new()
	
	# Split the large text box into individual lines
	var lines = expression_text.split("\n")
	
	for line in lines:
		var clean_line = line.strip_edges()
		
		# Skip empty lines to avoid parse errors
		if clean_line.is_empty():
			continue
			
		var error = expr.parse(clean_line)
		
		if error == OK:
			expr.execute([], null, true)
			if expr.has_execute_failed():
				push_error("CommandEval execution failed on line: ", clean_line)
		else:
			push_error("CommandEval parse error on line '", clean_line, "': ", expr.get_error_text())
			
	return Engine.get_main_loop().process_frame

func _to_string() -> String:
	if expression_text.is_empty():
		return "Eval (Empty)"
	# Return the first line of the expression to keep the list clean
	return "Eval: " + expression_text.split("\n")[0]