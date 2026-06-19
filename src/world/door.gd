@tool
extends Area2D

# ============================================================
# door.gd — Satu script untuk semua jenis pintu (masuk & keluar).
# Setiap door punya ID unik dan tahu scene+door tujuannya.
# Player akan di-spawn di Marker2D milik door tujuan.
#
# Scene tree:
#   Door (Area2D)  ← script ini
#   ├── CollisionShape2D
#   └── SpawnMarker (Marker2D)  ← posisi spawn saat player tiba lewat door ini
# ============================================================

## ID unik door ini dalam scene-nya. Dipakai oleh door lain sebagai target.
@export var door_id: String = ""

## Key scene tujuan (Legacy - jika target_scene_path diisi, key ini diabaikan).
@export var target_scene_key: String = ""

## Path scene tujuan (drag and drop file .tscn di sini)
@export_file("*.tscn") var target_scene_path: String = ""

## ID door tujuan di scene tersebut. Player akan spawn di SpawnMarker door itu.
@export var target_door_id: String = ""

@export var player_spawn_offset: Vector2 = Vector2.ZERO:
	get:
		return player_spawn_offset
	set(value):
		player_spawn_offset = value
		if spawn_marker:
			spawn_marker.position = value

@onready var spawn_marker: Marker2D = $SpawnMarker

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	spawn_marker.position = player_spawn_offset

	if door_id.is_empty():
		push_warning("Door di '%s': door_id belum diset!" % get_parent().name)

	# Daftarkan door ini ke SceneManager agar bisa dicari saat scene load
	SceneManager.register_door(door_id, spawn_marker)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if SceneManager.is_transitioning:
		return

	# Resolve path target scene
	var final_scene_path := target_scene_path
	if final_scene_path.is_empty() and not target_scene_key.is_empty():
		final_scene_path = SceneManager.get_scene_path(target_scene_key)

	if final_scene_path.is_empty():
		push_warning("Door '%s': target_scene_path atau target_scene_key belum diset!" % door_id)
		return

	if target_door_id.is_empty():
		push_warning("Door '%s': target_door_id belum diset!" % door_id)
		return

	SceneManager.go_to_door(final_scene_path, target_door_id)
