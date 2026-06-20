extends Control

# Almanac Entry Data Structure
var data_fauna: Array[Dictionary] = [
	{
		"id": &"ikan_kakaktua",
		"name": "Ikan Kakaktua",
		"flag": "almanac_ikan_kakaktua_unlocked",
		"default_unlocked": true,
		"category": "Fauna - Herbivora",
		"description_short": "Ikan pelindung terumbu karang.",
		"description_long": "Ikan Kakaktua (Parrotfish) memainkan peran vital dalam menjaga kelestarian terumbu karang di perairan Wakatobi. Dengan giginya yang kuat seperti paruh burung, ikan ini mengikis alga berlebih pada karang mati. Proses pencernaannya menghancurkan batu karang menjadi butiran pasir putih halus, membantu membentuk keindahan pantai pasir putih Wakatobi.",
		"color": Color(0.12, 0.72, 0.62) # Teal
	},
	{
		"id": &"dugong",
		"name": "Dugong Wakatobi",
		"flag": "almanac_dugong_unlocked",
		"default_unlocked": false,
		"category": "Fauna - Mamalia Laut",
		"description_short": "Mamalia laut pemakan lamun.",
		"description_long": "Dugong (Dugong dugon) adalah mamalia laut herbivora langka yang mendiami padang lamun di sekitar perairan dangkal Wakatobi. Dikenal secara lokal sebagai 'Putri Duyung', keberadaan mereka menandakan kesehatan ekosistem lamun setempat. Dugong dilindungi secara ketat karena populasinya yang kritis akibat kerusakan habitat dan polusi pesisir.",
		"color": Color(0.48, 0.58, 0.68) # Slate Gray
	},
	{
		"id": &"penyu_hijau",
		"name": "Penyu Hijau",
		"flag": "almanac_penyu_hijau_unlocked",
		"default_unlocked": true,
		"category": "Fauna - Reptil Laut",
		"description_short": "Reptil penjelajah samudra.",
		"description_long": "Penyu Hijau (Chelonia mydas) sering bersarang di pantai berpasir sepi di gugusan pulau Wakatobi. Mereka mengarungi ribuan mil samudra sebelum kembali ke tempat menetas mereka untuk bertelur. Menjaga kebersihan pantai dari sampah plastik sangat krusial bagi keselamatan penyu muda yang baru menetas.",
		"color": Color(0.24, 0.62, 0.28) # Forest Green
	},
	{
		"id": &"hiu_martil",
		"name": "Hiu Martil",
		"flag": "almanac_hiu_martil_unlocked",
		"default_unlocked": false,
		"category": "Fauna - Predator Utama",
		"description_short": "Predator puncak perairan dalam.",
		"description_long": "Hiu Martil (Sphyrna lewini) kadangkala melintas di sepanjang 'Drop-off Wall' perairan dalam Wakatobi. Struktur kepalanya yang unik memberikan pandangan 360 derajat yang sangat membantunya dalam berburu ikan pelagis. Kehadirannya menunjukkan rantai makanan laut yang seimbang dan sehat.",
		"color": Color(0.18, 0.28, 0.44) # Deep Ocean Blue
	}
]

var data_culture: Array[Dictionary] = [
	{
		"id": &"tradisi_karia",
		"name": "Tradisi Karia'a",
		"flag": "almanac_tradisi_karia_unlocked",
		"default_unlocked": true,
		"category": "Budaya - Upacara Adat",
		"description_short": "Festival kedewasaan anak-anak.",
		"description_long": "Karia'a merupakan festival adat suku Wangi-Wangi di Wakatobi yang merayakan transisi anak-anak menuju usia akil baligh dan kedewasaan. Anak-anak mengenakan kostum adat berwarna cerah berkilau dengan hiasan kepala bunga perak khas, diarak keliling desa diiringi tabuhan gendang dan tarian bersama yang riuh gembira.",
		"color": Color(0.9, 0.55, 0.08) # Gold/Orange
	},
	{
		"id": &"legenda_imbu",
		"name": "Legenda Imbu",
		"flag": "almanac_legenda_imbu_unlocked",
		"default_unlocked": false,
		"category": "Budaya - Mitos & Legenda",
		"description_short": "Gurita raksasa penjaga palung.",
		"description_long": "Legenda Imbu mengisahkan sesosok makhluk gurita raksasa mitis yang dipercaya menghuni gua bawah laut dalam atau palung laut Wakatobi. Masyarakat lokal meyakini Imbu hanya akan muncul ke permukaan ketika lautan terancam oleh kerusakan lingkungan atau ketika keseimbangan alam terusik oleh keserakahan manusia.",
		"color": Color(0.68, 0.18, 0.18) # Crimson Red
	},
	{
		"id": &"tari_lariangi",
		"name": "Tari Lariangi",
		"flag": "almanac_tari_lariangi_unlocked",
		"default_unlocked": true,
		"category": "Budaya - Seni Pertunjukan",
		"description_short": "Tarian istana warisan Kaledupa.",
		"description_long": "Tari Lariangi adalah tarian tradisional asal Pulau Kaledupa yang telah ada sejak abad ke-14 pada masa Kesultanan Buton. Ditarikan secara anggun oleh para gadis remaja mengenakan kostum megah berlapis emas dan hiasan kepala tinggi yang disebut 'Panto'. Gerakannya menyampaikan petuah moral dan sejarah leluhur.",
		"color": Color(0.72, 0.18, 0.58) # Magenta/Royal
	}
]

var data_diary: Array[Dictionary] = [
	{
		"id": &"diary_day1",
		"name": "Hari 1: Selamat Datang di Wakatobi",
		"flag": "diary_day1_unlocked",
		"default_unlocked": true,
		"category": "Catatan - Jurnal Petualang",
		"description_short": "Awal dari penjelajahan bahari.",
		"description_long": "Kapal akhirnya merapat! Wakatobi menyapaku dengan embusan angin sepoi-sepoi dan gradasi air laut yang sangat jernih dari hijau toska ke biru tua. Penduduk setempat tersenyum ramah di dermaga. Aku telah menyiapkan jurnal ini untuk mencatat segala keajaiban alam dan tradisi budaya yang akan kutemui di sini.",
		"color": Color(0.2, 0.5, 0.8) # Sky Blue
	},
	{
		"id": &"diary_day2",
		"name": "Hari 2: Arsitek Pasir Putih",
		"flag": "diary_day2_unlocked",
		"default_unlocked": true,
		"category": "Catatan - Penyelaman Karang",
		"description_short": "Menemukan Ikan Kakaktua beraksi.",
		"description_long": "Penyelaman pagi ini sungguh menakjubkan. Di antara terumbu karang yang warna-warni, aku melihat seekor Ikan Kakaktua besar yang sibuk mengunyah permukaan karang mati yang tertutup alga. Suara kunyahannya terdengar jelas di dalam air! Ternyata sebagian besar pasir putih halus di pantai indah tempatku menginap berasal dari sistem pencernaan ikan luar biasa ini.",
		"color": Color(0.1, 0.6, 0.5) # Sea Green
	},
	{
		"id": &"diary_day3",
		"name": "Hari 3: Gemerlap Warna Karia'a",
		"flag": "diary_day3_unlocked",
		"default_unlocked": true,
		"category": "Catatan - Festival Budaya",
		"description_short": "Menghadiri festival adat Wangi-Wangi.",
		"description_long": "Seluruh desa tumpah ruah ke jalanan hari ini! Musik tabuhan gendang menghentak serempak menyambut barisan pawai anak-anak yang diarak di atas tandu kayu berhias. Wajah mereka dirias dengan sangat cantik, mengenakan mahkota bunga perak berkilau yang memantulkan sinar matahari khatulistiwa. Sebuah tradisi penghormatan kedewasaan yang sangat sakral sekaligus meriah.",
		"color": Color(0.85, 0.45, 0.1) # Ochre Gold
	}
]

# UI Node References
@onready var main_index_view: Control = $Control/ViewContainer/MainIndexView
@onready var book_sub_view: Control = $Control/ViewContainer/BookSubView

# Main Index Node References
@onready var stat_fauna: Label = $Control/ViewContainer/MainIndexView/GridMenu/FaunaCard/StatsLabel
@onready var stat_culture: Label = $Control/ViewContainer/MainIndexView/GridMenu/CultureCard/StatsLabel
@onready var stat_diary: Label = $Control/ViewContainer/MainIndexView/GridMenu/DiaryCard/StatsLabel

# Book Sub-View Node References
@onready var category_title: Label = $Control/ViewContainer/BookSubView/LeftPage/CategoryTitle
@onready var grid_container: GridContainer = $Control/ViewContainer/BookSubView/LeftPage/ScrollContainer/GridContainer
@onready var empty_state_label: Label = $Control/ViewContainer/BookSubView/RightPage/EmptyStateLabel
@onready var detail_content: VBoxContainer = $Control/ViewContainer/BookSubView/RightPage/DetailContent

@onready var detail_name: Label = $Control/ViewContainer/BookSubView/RightPage/DetailContent/ItemName
@onready var detail_tag: Label = $Control/ViewContainer/BookSubView/RightPage/DetailContent/TagLabel
@onready var detail_mock_rect: ColorRect = $Control/ViewContainer/BookSubView/RightPage/DetailContent/MockVisualBox
@onready var detail_mock_label: Label = $Control/ViewContainer/BookSubView/RightPage/DetailContent/MockVisualBox/MockLabel
@onready var detail_description: Label = $Control/ViewContainer/BookSubView/RightPage/DetailContent/DescScroll/DescLabel

# Bottom Reputation Bar References
@onready var reputation_label: Label = $Control/BottomBar/ReputationContainer/ReputationLabel
@onready var reputation_progress: ProgressBar = $Control/BottomBar/ReputationContainer/ProgressBar

# Global State Variables
var current_category: String = ""
var selected_item_id: StringName = &""

func _ready() -> void:
	# Add custom flag entries to StoryState for initial setup if not defined
	_init_story_state_defaults()

	# Connect card buttons
	$Control/ViewContainer/MainIndexView/GridMenu/FaunaCard/SelectButton.pressed.connect(_on_fauna_pressed)
	$Control/ViewContainer/MainIndexView/GridMenu/CultureCard/SelectButton.pressed.connect(_on_culture_pressed)
	$Control/ViewContainer/MainIndexView/GridMenu/DiaryCard/SelectButton.pressed.connect(_on_diary_pressed)
	
	# Connect sub-page back button
	$Control/ViewContainer/BookSubView/LeftPage/BackButton.pressed.connect(_on_back_pressed)

	# Connect close book button
	$Control/CloseBookButton.pressed.connect(_on_close_book_pressed)

	# Initial setup
	_update_stats()
	_update_reputation()
	_show_view("index")

# Initialize default states in StoryState autoload if available
func _init_story_state_defaults() -> void:
	if not Engine.has_singleton("StoryState") and not get_node_or_null("/root/StoryState"):
		push_warning("StoryState autoload not found! Running in standalone mode.")
		return
		
	var story_state = get_node("/root/StoryState")
	
	# Set up initial test data status (Ikan Kakaktua = Unlocked, Dugong = Locked, etc.)
	for entry in data_fauna:
		if story_state.get_flag(entry.flag) == false and entry.default_unlocked:
			story_state.set_flag(entry.flag, true)
			
	for entry in data_culture:
		if story_state.get_flag(entry.flag) == false and entry.default_unlocked:
			story_state.set_flag(entry.flag, true)
			
	for entry in data_diary:
		if story_state.get_flag(entry.flag) == false and entry.default_unlocked:
			story_state.set_flag(entry.flag, true)
			
	# Initialize default reputation variables if empty
	if story_state.get_variable("reputation_level") == null:
		story_state.set_variable("reputation_level", 2)
	if story_state.get_variable("reputation_points") == null:
		story_state.set_variable("reputation_points", 65.0)

# Switch screens smoothly using simple alpha fading and transitions
func _show_view(view_name: String) -> void:
	if view_name == "index":
		main_index_view.show()
		book_sub_view.hide()
		# Update index views
		_update_stats()
		_update_reputation()
		
		# Micro-animation for cards entrance
		main_index_view.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(main_index_view, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		main_index_view.hide()
		book_sub_view.show()
		
		# Micro-animation for sub-page entrance
		book_sub_view.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(book_sub_view, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Check and update Almanac completion stats
func _update_stats() -> void:
	var story_state = get_node_or_null("/root/StoryState")
	
	# Fauna stats
	var unlocked_fauna = 0
	for entry in data_fauna:
		if _is_unlocked(entry, story_state):
			unlocked_fauna += 1
	stat_fauna.text = "Terbuka: %d / %d" % [unlocked_fauna, data_fauna.size()]
	
	# Culture stats
	var unlocked_culture = 0
	for entry in data_culture:
		if _is_unlocked(entry, story_state):
			unlocked_culture += 1
	stat_culture.text = "Terbuka: %d / %d" % [unlocked_culture, data_culture.size()]
	
	# Diary stats
	var unlocked_diary = 0
	for entry in data_diary:
		if _is_unlocked(entry, story_state):
			unlocked_diary += 1
	stat_diary.text = "Catatan: %d Entri" % [unlocked_diary]

# Update Wakatobi reputation status bar
func _update_reputation() -> void:
	var story_state = get_node_or_null("/root/StoryState")
	var level = 2
	var points = 65.0
	
	if story_state:
		level = story_state.get_variable("reputation_level", 2)
		points = story_state.get_variable("reputation_points", 65.0)
		
	var level_titles = {
		1: "Pemula Laut",
		2: "Penjelajah Wakatobi",
		3: "Ahli Konservasi",
		4: "Pelindung Karang"
	}
	var title = level_titles.get(level, "Penjelajah Wakatobi")
	
	reputation_label.text = "Reputasi: Level %d (%s)" % [level, title]
	reputation_progress.value = points

# Helper check if entry is unlocked
func _is_unlocked(entry: Dictionary, story_state: Node) -> bool:
	if story_state:
		return story_state.get_flag(entry.flag)
	return entry.default_unlocked

# Category navigations
func _on_fauna_pressed() -> void:
	current_category = "fauna"
	category_title.text = "Satwa & Ekosistem"
	_populate_grid(data_fauna)
	_show_view("sub")

func _on_culture_pressed() -> void:
	current_category = "culture"
	category_title.text = "Budaya & Legenda"
	_populate_grid(data_culture)
	_show_view("sub")

func _on_diary_pressed() -> void:
	current_category = "diary"
	category_title.text = "Catatan Harian"
	_populate_grid(data_diary)
	_show_view("sub")

func _on_back_pressed() -> void:
	_show_view("index")

func _on_close_book_pressed() -> void:
	# Hide or quit the almanac
	# In actual game, we might emit a signal or close the screen
	print("Almanac Book UI Closed.")
	# Smooth fade out and hide
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		hide()
		modulate.a = 1.0 # Reset for next opening
	)

# Dynamically populate the grid elements
func _populate_grid(entries: Array[Dictionary]) -> void:
	# Clear previous grid slots
	for child in grid_container.get_children():
		child.queue_free()
		
	var story_state = get_node_or_null("/root/StoryState")
	var first_unlocked_entry: Dictionary = {}
	
	for entry in entries:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.clip_text = true
		
		# Check unlock status
		var is_open = _is_unlocked(entry, story_state)
		if is_open:
			btn.text = entry.name
			btn.pressed.connect(func(): _show_details(entry))
			# Store first unlocked entry to show by default
			if first_unlocked_entry.is_empty():
				first_unlocked_entry = entry
			
			# Visual feedback when hovered
			btn.mouse_entered.connect(func():
				var hover_tween = create_tween()
				hover_tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08)
			)
			btn.mouse_exited.connect(func():
				var hover_tween = create_tween()
				hover_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
			)
			# Reset pivot offset to center so scaling looks correct
			btn.pivot_offset = btn.custom_minimum_size / 2
		else:
			btn.text = "???"
			btn.disabled = true
			btn.tooltip_text = "Terkunci: Selesaikan quest untuk membuka entri ini."
			
		grid_container.add_child(btn)
		
	# Show detail panel for the first unlocked entry or show empty state
	if not first_unlocked_entry.is_empty():
		_show_details(first_unlocked_entry)
	else:
		_show_empty_details()

func _show_empty_details() -> void:
	detail_content.hide()
	empty_state_label.show()

# Update detail view when entry is selected
func _show_details(entry: Dictionary) -> void:
	empty_state_label.hide()
	detail_content.show()
	
	detail_name.text = entry.name
	detail_tag.text = entry.category
	detail_mock_rect.color = entry.color
	
	# Short abbreviation or icon letter inside the color rect
	detail_mock_label.text = entry.name.substr(0, 2).upper()
	detail_description.text = entry.description_long
	
	# Micro-animation: Pop scale the detail content for premium feedback
	detail_content.modulate.a = 0.0
	detail_content.scale = Vector2(0.98, 0.98)
	detail_content.pivot_offset = Vector2(detail_content.size.x / 2, 0)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(detail_content, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(detail_content, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
