extends Resource

# ============================================================
# item_data.gd — Resource yang merepresentasikan satu jenis item
# Buat file .tres untuk setiap item di project
# ============================================================

class_name ItemData

@export var id: String = ""
@export var item_name: String = ""
@export var icon: Texture2D = null
@export_multiline var description: String = ""
