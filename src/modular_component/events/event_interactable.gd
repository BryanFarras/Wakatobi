# event_interactable.gd
class_name EventInteractable
extends Node2D

enum TriggerType { INTERACTABLE, AUTORUN }

@export var trigger_type: TriggerType = TriggerType.INTERACTABLE
@export var entity_name: String = "Default Name"
@export var event_sequence: Array[EventCommand]

@export_group("Spawn Settings")
## StoryState flag that controls EventInteractable presence
@export var visibility_flag: String = ""
## This event will be active when this flag's boolean value matches this condition
@export var visible_when_flag_is: bool = true

func _ready():
	# 1. Verify our own story flag condition
	if not is_condition_valid():
		queue_free()
		return
		
	# 2. Enforce sibling priority: if there is another valid EventInteractable 
	# before us under the same parent, disable/free ourselves.
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child == self:
				break
			if child is EventInteractable and not child.is_queued_for_deletion():
				if child.is_condition_valid():
					queue_free()
					return

	if trigger_type == TriggerType.INTERACTABLE:
		var interactable = get_node_or_null("Interactable")
		if interactable:
			interactable.interactable_name = entity_name
			interactable.interact = _on_interact
		else:
			push_warning("EventInteractable '%s': 'Interactable' child node not found for INTERACTABLE trigger!" % name)
	elif trigger_type == TriggerType.AUTORUN:
		# Nonaktifkan interactable jika ada, agar player tidak melihat prompt/menabrak
		var interactable = get_node_or_null("Interactable")
		if interactable:
			interactable.visible = false
			var collision = interactable.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = true
		call_deferred("_run_autorun")

func is_condition_valid() -> bool:
	if not visibility_flag.strip_edges().is_empty():
		var flag_name = visibility_flag.strip_edges()
		var flag_value = StoryState.get_flag(flag_name)
		return flag_value == visible_when_flag_is
	return true

func _on_interact():
	if event_sequence.size() > 0:
		EventManager.run_event_sequence(event_sequence, self)

func _run_autorun():
	# Tunggu satu frame agar scene dan player selesai di-spawn sepenuhnya
	await get_tree().process_frame
	if event_sequence.size() > 0:
		EventManager.run_event_sequence(event_sequence, self)
