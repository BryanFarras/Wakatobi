extends Area2D
class_name Interactable

# ============================================================
# interactable.gd — Pasang langsung di objek interactable
#
# Scene tree contoh (Sign):
#   Sign (Node2D)
#   ├── Sprite2D
#   ├── CollisionShape2D  (visual/physics body jika perlu)
#   └── Interactable (Area2D)  ← script ini
#       └── CollisionShape2D  ← area deteksi interaksi
#
# Collision layer node ini harus diset ke layer "interactions"
# ============================================================

## Nama objek yang ditampilkan di label interaksi
@export var interactable_name: String = ""

## Status objek (opsional, bisa dipakai untuk tampilkan konteks)
## Contoh: "Terkunci", "Sudah dibaca", dll
@export var status: String = ""

## Logic interaksi — override di script turunan atau set dari luar
var interact: Callable = func() -> void:
	push_warning("Interactable '%s' belum punya logic interaksi! Override 'interact' dengan fungsi yang dipanggil saat player berinteraksi." % interactable_name)

## Teks yang ditampilkan di interaction label milik InteractingComponent
func get_prompt() -> String:
	if status.is_empty():
		return interactable_name
	return "%s  [%s]" % [interactable_name, status]
