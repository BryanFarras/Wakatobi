@icon("res://assets/placeholder/sign.png")
extends Node2D

# ============================================================
# sign.gd
#
# Scene tree:
#   Sign (Node2D)  ← script ini
#   ├── Sprite2D
#   ├── PhantomCamera2D       ← PCam sign, priority tinggi saat aktif (e.g. 20)
#   │   (Follow Mode: None, posisi manual = di atas sign dengan offset Y negatif)
#   │   (Zoom: e.g. Vector2(2.5, 2.5))
#   │   (Tween duration: 0.6, Transition: Sine, Ease: In Out)
#   ├── Interactable (Area2D)  ← pasang interactable.gd
#   │   └── CollisionShape2D   (layer: interactions)
#   └── SignUI (CanvasLayer)   ← UI sign, layer tinggi agar di atas world
#       └── Panel
#           └── TextureRect (background UI)
#               └── RichTextLabel  ← isi teks sign
#	└── AnimationPlayer  ← animasi show/hide UI
# ============================================================

@export_multiline var sign_text: String = ""

## Priority PCam sign saat aktif — harus lebih tinggi dari PCam player
@export var pcam_active_priority: int = 20
## Priority PCam sign saat tidak aktif — harus lebih rendah dari PCam player
@export var pcam_inactive_priority: int = 0

@onready var interactable: Area2D = %Interactable
@onready var pcam: Node2D = %PhantomCamera2D
@onready var rich_label: RichTextLabel = %RichTextLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var _player: CharacterBody2D = null
var is_interacting: bool = false

func _ready() -> void:
	interactable.interactable_name = "Sign"
	interactable.interact = _on_interact

	# PCam sign mulai dengan priority rendah (tidak aktif)
	pcam.set_priority(pcam_inactive_priority)
	pcam.set_tween_on_load(false)

func _on_interact() -> void:
	_player = PlayerManager.get_player()
	if _player == null:
		return

	# Isi teks
	rich_label.text = sign_text

	# Blokir gerakan player
	_player.is_interacting = true

	is_interacting = !is_interacting

	if is_interacting:
		_open()
	else:
		_close()


func _open() -> void:
	# Aktifkan PCam sign → Phantom Camera otomatis tween ke sana
	pcam.set_priority(pcam_active_priority)
	print("Anda dapat papan yang disentuh")
	Inventory.add_item(load("res://assets/items/papan_disentuh.tres"))
	animation_player.play("show")

func _close() -> void:
	# Kembalikan PCam ke player
	pcam.set_priority(pcam_inactive_priority)

	animation_player.play("hide")
	await animation_player.animation_finished

	if _player and is_instance_valid(_player):
		_player.is_interacting = false
