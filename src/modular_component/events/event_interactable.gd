# event_interactable.gd
extends Node2D

@onready var interactable = $Interactable

# Expose these variables to the Godot Inspector
@export var entity_name: String = "Default Name"
@export var event_sequence: Array[EventCommand]

func _ready():
	# Apply the exported Inspector data to your existing interactable logic
	interactable.interactable_name = entity_name
	interactable.interact = _on_interact

func _on_interact():
	if event_sequence.size() > 0:
		EventManager.run_event_sequence(event_sequence, self)
