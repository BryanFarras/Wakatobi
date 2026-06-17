extends Interactable

## Amount of oxygen to refill (if not a full refill)
@export var refill_amount: float = 40.0
## If true, refills oxygen to maximum capacity regardless of current level
@export var is_full_refill: bool = true

var _active: bool = true

func _ready() -> void:
	# Set interactable properties defined in base class
	interactable_name = "O2 Capsule"
	status = "Ready"
	interact = _on_interact

func _on_interact() -> void:
	if not _active:
		return

	var player = PlayerManager.get_player()
	# Fallback if PlayerManager is not using the Diver
	if player == null or not player.has_method("refill_oxygen"):
		var group_players = get_tree().get_nodes_in_group("player")
		for p in group_players:
			if p.has_method("refill_oxygen"):
				player = p
				break
	
	if player != null and player.has_method("refill_oxygen"):
		# Refill oxygen
		player.refill_oxygen(refill_amount, is_full_refill)
		
		# Deactivate interactable
		_active = false
		status = "Empty"
		# Disable collision shape so it can't be interacted with again
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
		
		# Smoothly fade out the visual components
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(queue_free)
