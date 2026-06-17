extends PanelContainer

# ============================================================
# inventory_slot_ui.gd — Satu slot di grid inventory
#
# Scene tree (InventorySlot.tscn):
#   InventorySlot (PanelContainer)  ← script ini
#   └── TextureRect  ← menampilkan icon item
# ============================================================

class_name InventorySlotUI

@onready var texture_rect: TextureRect = $TextureRect

func set_item(item: ItemData) -> void:
	if item == null:
		texture_rect.texture = null
		texture_rect.modulate.a = 0.0
	else:
		texture_rect.texture = item.icon
		texture_rect.modulate.a = 1.0
