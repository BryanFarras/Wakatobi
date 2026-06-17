extends Node

# ============================================================
# PlayerManager — Autoload singleton
# Daftarkan di: Project Settings → Autoload → Name: "PlayerManager"
# ============================================================

const PLAYER_SCENE_PATH := "res://scenes/player.tscn"

var _player: CharacterBody2D = null

func _ready() -> void:
	# Pastikan Player tidak ada di scene awal (bisa dihapus dari main scene)
	if get_tree().current_scene.has_node("Player"):
		push_warning("PlayerManager: Player ditemukan di scene awal! Pastikan Player dihapus dari scene dan hanya di-instance lewat PlayerManager.")
		_player = get_tree().current_scene.get_node("Player") as CharacterBody2D
	
	if get_tree().current_scene.has_node("SpawnPoint"):
		var spawn_point := get_tree().current_scene.get_node("SpawnPoint") as Node2D
		spawn(get_tree().current_scene, spawn_point.global_position)
	else:
		push_warning("PlayerManager: SpawnPoint tidak ditemukan di scene '%s'!" % get_tree().current_scene.name)
# -------------------------------------------------------
# Public API
# -------------------------------------------------------

func spawn(parent: Node, position: Vector2) -> void:
	if _player == null or not is_instance_valid(_player):
		_instantiate(parent, position)
	else:
		_reparent(_player, parent, position)

func get_player() -> CharacterBody2D:
	return _player

func get_position() -> Vector2:
	if is_instance_valid(_player):
		return _player.global_position
	return Vector2.ZERO

# -------------------------------------------------------
# Internal
# -------------------------------------------------------

func _instantiate(parent: Node, position: Vector2) -> void:
	var packed := load(PLAYER_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("PlayerManager: PLAYER_SCENE_PATH tidak valid → '%s'" % PLAYER_SCENE_PATH)
		return

	_player = packed.instantiate() as CharacterBody2D
	parent.add_child(_player)
	_player.global_position = position

func _reparent(player: CharacterBody2D, new_parent: Node, position: Vector2) -> void:
	var old_parent := player.get_parent()
	if old_parent != null:
		old_parent.remove_child(player)

	new_parent.add_child(player)
	# global_position diset setelah add_child agar node sudah masuk scene tree
	player.global_position = position
