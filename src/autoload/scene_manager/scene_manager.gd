extends Node

# ============================================================
# SceneManager — Autoload singleton
# Daftarkan di: Project Settings → Autoload → Name: "SceneManager"
# ============================================================

@onready var animation_player: AnimationPlayer = %AnimationPlayer

var _scenes: Dictionary = {
	"world":      "res://scenes/world.tscn",
	"building_a": "res://scenes/interior.tscn",
}

var _target_door_id: String = ""
var _door_registry: Dictionary = {}

# Posisi spawn yang sudah di-resolve, menunggu scene baru siap
var _player_spawn_position: Vector2 = Vector2.INF

# -------------------------------------------------------
# Public API
# -------------------------------------------------------

## Dipanggil oleh door.gd saat _ready()
func register_door(door_id: String, marker: Marker2D) -> void:
	if door_id.is_empty():
		return
	_door_registry[door_id] = marker
	_set_player_position()

## Dipanggil oleh Door saat player menyentuhnya
func go_to_door(scene_key: String, door_id: String) -> void:
	if not _scenes.has(scene_key):
		push_error("SceneManager: scene key '%s' tidak ditemukan!" % scene_key)
		return

	_target_door_id = door_id
	_player_spawn_position = Vector2.INF
	_door_registry.clear()

	# call_deferred wajib: dipanggil dari physics callback
	call_deferred("_transition_to_scene", scene_key)

## Memainkan animasi fade dan mengembalikan sinyal untuk di-await oleh EventManager
func play_fade_animation(anim_name: String) -> Signal:
	animation_player.play(anim_name)
	return animation_player.animation_finished

# -----------------------------------------------
# Transition
# -----------------------------------------------
func _transition_to_scene(scene_key: String) -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished

	get_tree().change_scene_to_file(_scenes[scene_key])
	await get_tree().process_frame

	animation_player.play("fade_in")
	await animation_player.animation_finished

# -------------------------------------------------------
# Internal
# -------------------------------------------------------

func _set_player_position() -> void:
	if _target_door_id.is_empty():
		return
	if not _door_registry.has(_target_door_id):
		return

	# Capture posisi dari marker sekarang — marker masih valid di scene baru
	var marker := _door_registry[_target_door_id] as Marker2D
	_target_door_id = ""
	_player_spawn_position = marker.global_position

	# Defer spawn ke frame berikutnya:
	# - scene tree sudah tidak "blocked"
	# - current_scene sudah menunjuk scene baru
	call_deferred("_spawn_player")

func _spawn_player() -> void:
	if _player_spawn_position == Vector2.INF:
		return

	var scene_root := get_tree().current_scene
	PlayerManager.spawn(scene_root, _player_spawn_position)

	_player_spawn_position = Vector2.INF
