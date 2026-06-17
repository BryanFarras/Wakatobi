extends CanvasLayer

# ============================================================
# inventory_ui.gd — UI inventory utama
#
# Scene tree (InventoryUI.tscn):
#   InventoryUI (CanvasLayer)  ← script ini, layer: 10
#   └── Panel  ← background panel, anchor ke kanan layar
#       └── GridContainer  ← columns sesuai jumlah kolom grid
#           └── [InventorySlot x MAX_SLOTS]  ← instance InventorySlot.tscn
# ============================================================

const SLOT_SCENE := preload("res://src/systems/inventory/inventory_slot.tscn")

@onready var grid: GridContainer = $Panel/GridContainer

func _ready() -> void:
	_build_grid()
	Inventory.changed.connect(_refresh)
	hide()

func _build_grid() -> void:
	for i in Inventory.MAX_SLOTS:
		var slot := SLOT_SCENE.instantiate() as PanelContainer
		grid.add_child(slot)
	_refresh()

func _refresh() -> void:
	var slot_nodes := grid.get_children()
	for i in slot_nodes.size():
		slot_nodes[i].set_item(Inventory.slots[i])
