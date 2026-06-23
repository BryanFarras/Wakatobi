extends Interactable
class_name InteractableComponent

# ==============================================================================
# interactable_component.gd — Reusable Quest Trigger & Dialogue Component
# Attached to Area2D nodes on NPCs or interactive world objects.
# ==============================================================================

@export_group("Dialogue Configuration")
## DialogueResource timeline containing dialogue nodes
@export var dialogue_resource: DialogueResource
## Starting node inside the dialogue resource
@export var dialogue_start_node: String = "start"
## Branch to transition to dynamically upon quest completion
@export var post_quest_start_node: String = ""

@export_group("Quest Logic")
## Key of the StoryState flag or variable required to execute dialogue
@export var required_quest_state: String = ""

@export_group("Phantom Camera Cinematic")
## Virtual camera node (PhantomCamera2D) that frames the conversation
@export var target_pcam: Node2D

var is_interacting: bool = false

func _ready() -> void:
	# Assign the Callable from base Interactable class to our handler
	interact = Callable(self, "_on_interacted")
	
	# Listen to global GameplayManager completions to transition state
	var gameplay_manager = get_node_or_null("/root/GameplayManager")
	if gameplay_manager:
		if gameplay_manager.has_signal("fishing_completed"):
			gameplay_manager.fishing_completed.connect(_on_fishing_completed)
		if gameplay_manager.has_signal("cooking_completed"):
			gameplay_manager.cooking_completed.connect(_on_cooking_completed)

func _on_interacted() -> void:
	if not is_quest_state_valid():
		print("[InteractableComponent] Quest conditions not satisfied for state: ", required_quest_state)
		return
		
	_run_dialogue()

## Checks if the current state satisfies the quest requirements
func is_quest_state_valid() -> bool:
	if required_quest_state.is_empty():
		return true
		
	# Check flag
	if StoryState.get_flag(required_quest_state):
		return true
		
	# Check variable
	var val = StoryState.get_variable(required_quest_state)
	if val != null:
		if typeof(val) == TYPE_BOOL and val == true:
			return true
		if typeof(val) == TYPE_STRING and not val.strip_edges().is_empty():
			return true
			
	return false

func _run_dialogue() -> void:
	if dialogue_resource == null:
		push_error("[InteractableComponent] dialogue_resource is not set!")
		return
		
	is_interacting = true
	
	if target_pcam:
		await trigger_quest_cutscene(target_pcam)
	else:
		# Direct fallback (dialogue without cinematic camera blends)
		var player = PlayerManager.get_player()
		if player:
			player.is_interacting = true
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start_node)
		await DialogueManager.dialogue_ended
		if player and is_instance_valid(player):
			player.is_interacting = false
			
	is_interacting = false

## Freezes player inputs, shifts camera focus to the target pcam, and releases focus upon exit
func trigger_quest_cutscene(pcam_node: Node2D) -> void:
	var player = PlayerManager.get_player()
	if player:
		player.is_interacting = true
		
	# Transition camera focus by giving the virtual camera priority
	if pcam_node and pcam_node.has_method("set_priority"):
		pcam_node.call("set_priority", 20)
		
	# Await camera transition interpolation (typically 0.6 seconds)
	await get_tree().create_timer(0.6).timeout
	
	# Display balloon
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start_node)
	
	# Wait for dialog to end
	await DialogueManager.dialogue_ended
	
	# Return focus back to player camera (setting priority lower than player camera)
	if pcam_node and pcam_node.has_method("set_priority"):
		pcam_node.call("set_priority", 0)
		
	# Await blend back
	await get_tree().create_timer(0.6).timeout
	
	if player and is_instance_valid(player):
		player.is_interacting = false

# ==============================================================================
# GameplayManager Listeners
# ==============================================================================

func _on_fishing_completed(success: bool, item_id: String) -> void:
	if success and required_quest_state == "quest1_active":
		_transition_to_post_quest("quest1_complete")

func _on_cooking_completed(success: bool, dish_name: String) -> void:
	if success and required_quest_state == "quest2_active":
		_transition_to_post_quest("quest2_complete")

func _transition_to_post_quest(next_state_flag: String) -> void:
	StoryState.set_flag(next_state_flag, true)
	if not post_quest_start_node.is_empty():
		dialogue_start_node = post_quest_start_node
	print("[InteractableComponent] Quest state transitioned. Active Dialogue Node: ", dialogue_start_node)
