extends Node2D

# ============================================================
# interacting_component.gd — Component untuk player
#
# Scene tree:
#   Player (CharacterBody2D)
#   └── InteractingComponent (Node2D)  ← script ini
#       ├── DetectionArea (Area2D)
#       │   └── CollisionShape2D
#       └── Label  ← prompt "E  Sign"
#
# DetectionArea → Collision Mask: layer "interactions"
# ============================================================

@onready var detection_area: Area2D = $DetectionArea
@onready var label: Label = $Label

var _nearby: Array[Area2D] = []
var _closest: Area2D = null

func _ready() -> void:
	label.hide()
	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
	# Sembunyikan prompt saat player sedang dalam mode interaksi
	if get_parent().is_interacting:
		label.hide()
		return
	_update_closest()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _closest != null:
		_closest.interact.call()

func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("get_prompt"):
		return
	if not _nearby.has(area):
		_nearby.append(area)

func _on_area_exited(area: Area2D) -> void:
	_nearby.erase(area)
	if _closest == area:
		_closest = null
		label.hide()

func _update_closest() -> void:
	_nearby = _nearby.filter(func(a): return is_instance_valid(a))

	if _nearby.is_empty():
		_set_closest(null)
		return

	var player_pos: Vector2 = get_parent().global_position
	_nearby.sort_custom(func(a, b):
		return a.global_position.distance_squared_to(player_pos) \
			 < b.global_position.distance_squared_to(player_pos)
	)

	_set_closest(_nearby[0])

func _set_closest(interactable: Area2D) -> void:
	if _closest == interactable:
		return
	_closest = interactable

	if _closest == null:
		label.hide()
	else:
		label.text = "E  %s" % _closest.get_prompt()
		label.show()
