extends Node

# ============================================================
# inventory.gd — Autoload singleton
# Menyimpan dan mengelola item milik player.
# Daftarkan di: Project Settings → Autoload → Name: "Inventory"
# ============================================================

## Jumlah maksimal slot inventory
const MAX_SLOTS: int = 24

## Array of ItemData | null — null berarti slot kosong
var slots: Array = []

signal changed

func _ready() -> void:
	slots.resize(MAX_SLOTS)
	slots.fill(null)

# -------------------------------------------------------
# Public API
# -------------------------------------------------------

## Tambahkan item ke slot kosong pertama.
## Kembalikan true jika berhasil.
func add_item(item: ItemData) -> bool:
	var idx := _first_empty_slot()
	if idx == -1:
		push_warning("Inventory penuh!")
		return false
	slots[idx] = item
	changed.emit()
	return true

## Hapus item di slot tertentu.
func remove_at(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	slots[slot_index] = null
	changed.emit()

func erase(item_name:String) -> void:
	for i in slots.size():
		if slots[i] != null and slots[i].id == item_name:
			remove_at(i)
			break

## Cek apakah inventory punya item dengan id tertentu.
func has_item(id: String) -> bool:
	return slots.any(func(s): return s != null and s.id == id)

# -------------------------------------------------------
# Internal
# -------------------------------------------------------

func _first_empty_slot() -> int:
	for i in MAX_SLOTS:
		if slots[i] == null:
			return i
	return -1
