extends Interactable

## Name of the collectible item
@export var item_name: String = "Sea Shell"
## Cargo weight added to player when collected (kg)
@export var weight: float = 4.5
## Score or monetary value of this item
@export var value: int = 150

var _active: bool = true

func _ready() -> void:
	# Set interactable properties defined in base class
	interactable_name = item_name
	status = "%s kg" % weight
	interact = _on_interact

func _on_interact() -> void:
	if not _active:
		return

	var player = PlayerManager.get_player()
	# Fallback if PlayerManager is not using the Diver
	if player == null or not player.has_method("add_cargo_weight"):
		var group_players = get_tree().get_nodes_in_group("player")
		for p in group_players:
			if p.has_method("add_cargo_weight"):
				player = p
				break
	
	if player != null and player.has_method("add_cargo_weight"):
		# Add weight and score to the player
		player.add_cargo_weight(weight)
		if player.has_method("add_score"):
			player.add_score(value)
		
		# Deactivate interactable
		_active = false
		# Disable collision shape so it can't be interacted with again
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
		
		# Smoothly slide up and fade out
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 30.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Ensure sequential completion cleanup
		var cleanup_tween = create_tween()
		cleanup_tween.tween_interval(0.4)
		cleanup_tween.tween_callback(queue_free)
