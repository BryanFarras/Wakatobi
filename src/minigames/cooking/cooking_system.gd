extends Control

# Signals
signal dish_cooked(dish_name: String, score: float)

# Cooking Station Physics Parameters
@export_group("Cooking Station Physics")
## Rate of natural temperature cooling per second
@export var heat_decay_rate: float = 14.0
## Increase in temperature per blow of the Semprong pipe
@export var heat_blow_power: float = 9.0
## Optimal temperature lower boundary (Green Zone Min)
@export var green_zone_min: float = 65.0
## Optimal temperature upper boundary (Green Zone Max)
@export var green_zone_max: float = 85.0
## Required total time (seconds) inside optimal zone to finish cooking
@export var cooking_time: float = 8.0

# Prep Station Parameters
@export_group("Prep Station Configuration")
## Speed of the Kapeo QTE cursor sweeping back and forth
@export var kapeo_qte_speed: float = 3.5
## Target mouse drag distance (pixels) to finish Hanga-Hanga grinding
@export var hanga_hanga_target_distance: float = 6000.0
## Filling rate (percentage/sec) of the Kaloli mold while holding
@export var kaloli_fill_rate: float = 40.0

# Game State Variables
var current_station: String = "prep" # "prep", "cooking", "serving"
var selected_dish: String = "" # "kasuami" or "parende"
var current_prep_step: int = 0 # 0, 1, 2... depending on dish

# Kasuami Prep States
var kapeo_moisture: float = 100.0
var kapeo_score: float = 100.0
var qte_time: float = 0.0
var hanga_hanga_distance: float = 0.0
var mold_level: float = 0.0
var is_molding: bool = false
var kaloli_score: float = 100.0

# Sup Parende Prep States
var cuts_completed: Array[bool] = [false, false, false] # 3 cuts needed
var drag_active: bool = false
var cut_score: float = 100.0
# Ingredients counts
var count_lemongrass: int = 0
var count_shallots: int = 0
var count_chili: int = 0

# Cooking Physics States
var current_heat: float = 0.0
var cooking_progress: float = 0.0
var total_cook_seconds: float = 0.0
var optimal_cook_seconds: float = 0.0
var fish_dropped: bool = false
var fish_drop_perfect: bool = true # Check if dropped in green zone

# Final Scores
var prep_accuracy: float = 0.0
var cook_accuracy: float = 0.0
var final_accuracy: float = 0.0

# UI Node References
@onready var prep_station: Control = $MainContainer/PrepStation
@onready var cooking_station: Control = $MainContainer/CookingStation
@onready var serving_station: Control = $MainContainer/ServingStation

# Station tab buttons (to disable/enable sequentially)
@onready var tab_prep: Button = $TitleBar/Tabs/BtnPrep
@onready var tab_cook: Button = $TitleBar/Tabs/BtnCook
@onready var tab_serve: Button = $TitleBar/Tabs/BtnServe

# Prep - Selection
@onready var selection_panel: VBoxContainer = $MainContainer/PrepStation/SelectionPanel
# Prep - Kasuami Panels
@onready var kasuami_prep: VBoxContainer = $MainContainer/PrepStation/KasuamiPrep
@onready var kapeo_panel: Control = $MainContainer/PrepStation/KasuamiPrep/KapeoPanel
@onready var kapeo_moisture_bar: ProgressBar = $MainContainer/PrepStation/KasuamiPrep/KapeoPanel/MoistureBar
@onready var qte_bar: ColorRect = $MainContainer/PrepStation/KasuamiPrep/KapeoPanel/QteBar
@onready var qte_cursor: ColorRect = $MainContainer/PrepStation/KasuamiPrep/KapeoPanel/QteBar/QteCursor
@onready var hanga_panel: Control = $MainContainer/PrepStation/KasuamiPrep/HangaHangaPanel
@onready var hanga_progress_bar: ProgressBar = $MainContainer/PrepStation/KasuamiPrep/HangaHangaPanel/FinenessBar
@onready var kaloli_panel: Control = $MainContainer/PrepStation/KasuamiPrep/KaloliPanel
@onready var mold_progress_bar: ProgressBar = $MainContainer/PrepStation/KasuamiPrep/KaloliPanel/MoldBar
@onready var mold_visual: ColorRect = $MainContainer/PrepStation/KasuamiPrep/KaloliPanel/MoldVisual

# Prep - Parende Panels
@onready var parende_prep: VBoxContainer = $MainContainer/PrepStation/ParendePrep
@onready var cutting_panel: Control = $MainContainer/PrepStation/ParendePrep/CuttingPanel
@onready var cutting_line_draw: Line2D = $MainContainer/PrepStation/ParendePrep/CuttingPanel/LineDraw
@onready var fish_slices: Control = $MainContainer/PrepStation/ParendePrep/CuttingPanel/FishSlices
@onready var gathering_panel: Control = $MainContainer/PrepStation/ParendePrep/GatheringPanel
@onready var ingredient_list_label: Label = $MainContainer/PrepStation/ParendePrep/GatheringPanel/GatheredList

# Cooking Station UI
@onready var heat_bar: ProgressBar = $MainContainer/CookingStation/CookingControls/HeatBar
@onready var green_zone_visual: ColorRect = $MainContainer/CookingStation/CookingControls/HeatBar/GreenZoneVisual
@onready var cook_progress_bar: ProgressBar = $MainContainer/CookingStation/CookingControls/CookProgressBar
@onready var cook_status_label: Label = $MainContainer/CookingStation/CookingControls/StatusLabel
@onready var btn_drop_fish: Button = $MainContainer/CookingStation/CookingControls/ActionGrid/BtnDropFish
@onready var cook_title_label: Label = $MainContainer/CookingStation/CookingControls/CookTitle

# Serving Station UI
@onready var eval_dish_title: Label = $MainContainer/ServingStation/EvaluationPanel/VBox/DishTitle
@onready var eval_stars: Label = $MainContainer/ServingStation/EvaluationPanel/VBox/StarsLabel
@onready var eval_breakdown: Label = $MainContainer/ServingStation/EvaluationPanel/VBox/ScoreBreakdown
@onready var eval_review: Label = $MainContainer/ServingStation/EvaluationPanel/VBox/ReviewLabel

func _ready() -> void:
	# Connect Tab navigation
	tab_prep.pressed.connect(func(): _switch_station("prep"))
	tab_cook.pressed.connect(func(): _switch_station("cooking"))
	tab_serve.pressed.connect(func(): _switch_station("serving"))
	
	# Connect Selection
	$MainContainer/PrepStation/SelectionPanel/Btns/BtnKasuami.pressed.connect(func(): _start_dish("kasuami"))
	$MainContainer/PrepStation/SelectionPanel/Btns/BtnParende.pressed.connect(func(): _start_dish("parende"))
	
	# Connect Kasuami Prep Buttons
	$MainContainer/PrepStation/KasuamiPrep/KapeoPanel/BtnSqueeze.pressed.connect(_on_kapeo_squeeze)
	var btn_mold = $MainContainer/PrepStation/KasuamiPrep/KaloliPanel/BtnMold
	btn_mold.button_down.connect(func(): is_molding = true)
	btn_mold.button_up.connect(func(): is_molding = false)
	$MainContainer/PrepStation/KasuamiPrep/KaloliPanel/BtnFinishMold.pressed.connect(_on_kaloli_finished)
	
	# Connect Hanga-Hanga Panel Input
	var hanga_trigger = $MainContainer/PrepStation/KasuamiPrep/HangaHangaPanel/GrindArea
	hanga_trigger.gui_input.connect(_on_hanga_hanga_input)

	# Connect Sup Parende Prep Input & Buttons
	var cut_trigger = $MainContainer/PrepStation/ParendePrep/CuttingPanel/CutArea
	cut_trigger.gui_input.connect(_on_cutting_input)
	
	$MainContainer/PrepStation/ParendePrep/GatheringPanel/Grid/AddLemongrass.pressed.connect(func(): _add_ingredient("lemongrass"))
	$MainContainer/PrepStation/ParendePrep/GatheringPanel/Grid/AddShallot.pressed.connect(func(): _add_ingredient("shallot"))
	$MainContainer/PrepStation/ParendePrep/GatheringPanel/Grid/AddChili.pressed.connect(func(): _add_ingredient("chili"))
	$MainContainer/PrepStation/ParendePrep/GatheringPanel/BtnFinishGather.pressed.connect(_on_ingredients_finished)
	
	# Connect Cooking Buttons
	$MainContainer/CookingStation/CookingControls/ActionGrid/BtnBlow.pressed.connect(_on_blow_pressed)
	btn_drop_fish.pressed.connect(_on_drop_fish_pressed)
	
	# Connect Serving Buttons
	$MainContainer/ServingStation/EvaluationPanel/VBox/Btns/BtnServe.pressed.connect(_on_serve_dish)
	$MainContainer/ServingStation/EvaluationPanel/VBox/Btns/BtnRestart.pressed.connect(_reset_minigame)
	
	# Set up green zone indicators visually on the progress bar
	_setup_heat_bar_visuals()
	
	# Start minigame state
	_reset_minigame()

func _setup_heat_bar_visuals() -> void:
	# Place the green zone ColorRect relative to optimal temperature limits
	green_zone_visual.anchor_left = green_zone_min / 100.0
	green_zone_visual.anchor_right = green_zone_max / 100.0

func _reset_minigame() -> void:
	selected_dish = ""
	current_prep_step = 0
	
	# Kasuami Reset
	kapeo_moisture = 100.0
	kapeo_score = 100.0
	hanga_hanga_distance = 0.0
	mold_level = 0.0
	is_molding = false
	kaloli_score = 100.0
	
	# Sup Parende Reset
	cuts_completed = [false, false, false]
	cut_score = 100.0
	count_lemongrass = 0
	count_shallots = 0
	count_chili = 0
	_update_ingredient_label()
	
	# Cooking Reset
	current_heat = 20.0 # start lukewarm
	cooking_progress = 0.0
	total_cook_seconds = 0.0
	optimal_cook_seconds = 0.0
	fish_dropped = false
	fish_drop_perfect = true
	
	# UI resets
	_reset_fish_slices_visual()
	cook_progress_bar.value = 0.0
	kapeo_moisture_bar.value = 100.0
	hanga_progress_bar.value = 0.0
	mold_progress_bar.value = 0.0
	mold_visual.color.a = 0.2
	
	# Lock Cooking and Serving tabs initially
	tab_prep.disabled = false
	tab_cook.disabled = true
	tab_serve.disabled = true
	
	selection_panel.show()
	kasuami_prep.hide()
	parende_prep.hide()
	
	_switch_station("prep")

func _switch_station(station: String) -> void:
	current_station = station
	prep_station.visible = (station == "prep")
	cooking_station.visible = (station == "cooking")
	serving_station.visible = (station == "serving")
	
	# Update tab highlights
	tab_prep.flat = (station != "prep")
	tab_cook.flat = (station != "cooking")
	tab_serve.flat = (station != "serving")
	
	if station == "cooking":
		# Setup cooking titles depending on dish
		if selected_dish == "kasuami":
			cook_title_label.text = "Mengukus Kasuami (Simmering)"
			btn_drop_fish.hide()
			fish_dropped = true # Kasuami is already in the steamer
		else:
			cook_title_label.text = "Memasak Sup Parende (Boiling)"
			btn_drop_fish.show()
			fish_dropped = false
			cook_status_label.text = "Panaskan air tungku! Masukkan Ikan di Zona Hijau."

func _start_dish(dish: String) -> void:
	selected_dish = dish
	selection_panel.hide()
	current_prep_step = 0
	
	if dish == "kasuami":
		kasuami_prep.show()
		_show_prep_step_panel(0) # show Kapeo
	else:
		parende_prep.show()
		_show_prep_step_panel(0) # show Cutting

func _show_prep_step_panel(step: int) -> void:
	current_prep_step = step
	if selected_dish == "kasuami":
		kapeo_panel.visible = (step == 0)
		hanga_panel.visible = (step == 1)
		kaloli_panel.visible = (step == 2)
	else:
		cutting_panel.visible = (step == 0)
		gathering_panel.visible = (step == 1)

func _advance_prep_step() -> void:
	var next_step = current_prep_step + 1
	if selected_dish == "kasuami":
		if next_step <= 2:
			_show_prep_step_panel(next_step)
		else:
			_finish_prep()
	else:
		if next_step <= 1:
			_show_prep_step_panel(next_step)
		else:
			_finish_prep()

func _finish_prep() -> void:
	# Enable cooking tab
	tab_cook.disabled = false
	_switch_station("cooking")

func _process(delta: float) -> void:
	# 1. Kapeo QTE Cursor Sweeping
	if current_station == "prep" and selected_dish == "kasuami" and current_prep_step == 0:
		qte_time += delta * kapeo_qte_speed
		var cursor_pos = abs(sin(qte_time))
		# Position cursor horizontally across the bar
		qte_cursor.anchor_left = cursor_pos - 0.02
		qte_cursor.anchor_right = cursor_pos + 0.02
	
	# 2. Kaloli Filling Check
	if current_station == "prep" and selected_dish == "kasuami" and current_prep_step == 2:
		if is_molding:
			mold_level += delta * kaloli_fill_rate
			mold_progress_bar.value = mold_level
			# Fade the visual opacity of the cone representing filled flour
			mold_visual.color.a = clamp(mold_level / 100.0, 0.2, 1.2)
			
			# Visual warning if overflowing
			if mold_level > 100.0:
				mold_visual.color = Color(0.9, 0.3, 0.3, 1.0) # turn red
			else:
				mold_visual.color = Color(0.95, 0.85, 0.65, 1.0) # standard flour color

	# 3. Cooking Station Heat Balance and Steaming Physics
	if current_station == "cooking":
		# Temperature decay over time
		current_heat = max(0.0, current_heat - heat_decay_rate * delta)
		heat_bar.value = current_heat
		
		# If temperature is inside the green zone
		var is_optimal = current_heat >= green_zone_min and current_heat <= green_zone_max
		
		if is_optimal:
			cook_status_label.text = "Optimal! Pertahankan Suhu."
			cook_status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		elif current_heat < green_zone_min:
			cook_status_label.text = "Suhu Terlalu Rendah! Tiup Api."
			cook_status_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
		else:
			cook_status_label.text = "Terlalu Panas! Biarkan Dingin."
			cook_status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			
		# Increase cooking progress only after fish is dropped or if doing kasuami
		if fish_dropped:
			total_cook_seconds += delta
			if is_optimal:
				optimal_cook_seconds += delta
				# Cook 2.5x faster when temperature is kept in optimal green zone
				cooking_progress += delta * (100.0 / cooking_time)
			else:
				# slow cooking progress even outside green zone (rawer heat)
				cooking_progress += delta * (100.0 / cooking_time) * 0.2
				
			cook_progress_bar.value = min(100.0, cooking_progress)
			
			if cooking_progress >= 100.0:
				_finish_cooking()

# ========================================================
# Prep Station Mini-game Handlers
# ========================================================

# A. Kapeo (Squeezing)
func _on_kapeo_squeeze() -> void:
	var cursor_pos = abs(sin(qte_time))
	# Target Green QTE Zone is in the middle: 0.40 to 0.60
	if cursor_pos >= 0.40 and cursor_pos <= 0.60:
		# Perfect hit!
		kapeo_moisture = max(0.0, kapeo_moisture - 15.0)
		_flash_screen(Color(0.2, 0.8, 0.4, 0.2)) # green flash
	else:
		# Missed hit
		kapeo_moisture = max(0.0, kapeo_moisture - 4.0)
		kapeo_score = max(20.0, kapeo_score - 8.0) # penalty
		_flash_screen(Color(0.8, 0.2, 0.2, 0.2)) # red flash
		
	kapeo_moisture_bar.value = kapeo_moisture
	
	if kapeo_moisture <= 0.0:
		_advance_prep_step()

# B. Hanga-Hanga (Crumbing)
func _on_hanga_hanga_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var movement = event.relative.length()
		hanga_hanga_distance += movement
		var fineness = min(100.0, (hanga_hanga_distance / hanga_hanga_target_distance) * 100.0)
		hanga_progress_bar.value = fineness
		
		if fineness >= 100.0 and current_prep_step == 1:
			_advance_prep_step()

# C. Kaloli (Molding)
func _on_kaloli_finished() -> void:
	if mold_level < 50.0:
		# Too empty! Cannot finish yet
		return
		
	# Ideal target is exactly 100% mold filled
	var difference = abs(mold_level - 100.0)
	kaloli_score = max(20.0, 100.0 - difference * 3.5)
	
	_advance_prep_step()

# D. Sup Parende Fish Cutting (Line Drag check)
func _on_cutting_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_active = true
				cutting_line_draw.clear_points()
				cutting_line_draw.add_point(event.position)
			else:
				drag_active = false
				_check_cut_lines()
				
	elif event is InputEventMouseMotion and drag_active:
		cutting_line_draw.add_point(event.position)

func _check_cut_lines() -> void:
	if cutting_line_draw.points.size() < 2:
		return
		
	# We check if drawing coordinates crossed vertical cut lines
	# Panel width is 480 pixels. Slices at X = 120, 240, 360
	var points = cutting_line_draw.points
	var min_y = 9999.0
	var max_y = -9999.0
	var crossed_x: Array[float] = []
	
	for p in points:
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
		crossed_x.append(p.x)
		
	# A valid cut drag must travel vertically (at least 60 pixels)
	var vertical_travel = max_y - min_y
	if vertical_travel < 60.0:
		cutting_line_draw.clear_points()
		return
		
	# Find which X boundary it crossed
	# Average X of the stroke
	var sum_x = 0.0
	for x in crossed_x:
		sum_x += x
	var avg_x = sum_x / crossed_x.size()
	
	# Target slices
	var targets = [120.0, 240.0, 360.0]
	var cut_made = false
	
	for i in range(targets.size()):
		if not cuts_completed[i]:
			var dist = abs(avg_x - targets[i])
			if dist < 30.0: # Close enough to the line
				cuts_completed[i] = true
				cut_made = true
				# visual feedback: move slices apart
				_animate_fish_slice(i)
				# Assess accuracy penalty for offset cuts
				cut_score = max(20.0, cut_score - dist * 1.2)
				break
				
	cutting_line_draw.clear_points()
	
	# Check if all 3 slices are complete
	if cuts_completed[0] and cuts_completed[1] and cuts_completed[2]:
		# wait a tiny bit to show the split animation, then advance
		var t = create_tween()
		t.tween_interval(0.5)
		t.tween_callback(func(): _advance_prep_step())

func _animate_fish_slice(slice_idx: int) -> void:
	# Shifts visual ColorRects left or right to simulate slices splitting apart
	var slices = fish_slices.get_children()
	if slice_idx < slices.size():
		var tween = create_tween()
		if slice_idx == 0:
			tween.tween_property(slices[0], "position:x", slices[0].position.x - 20.0, 0.3)
		elif slice_idx == 1:
			tween.tween_property(slices[1], "position:x", slices[1].position.x - 10.0, 0.3)
			tween.tween_property(slices[2], "position:x", slices[2].position.x + 10.0, 0.3)
		elif slice_idx == 2:
			tween.tween_property(slices[3], "position:x", slices[3].position.x + 20.0, 0.3)

func _reset_fish_slices_visual() -> void:
	if not is_inside_tree(): return
	var slices = fish_slices.get_children()
	if slices.size() >= 4:
		slices[0].position.x = 20
		slices[1].position.x = 130
		slices[2].position.x = 250
		slices[3].position.x = 370

# E. Ingredient Gathering
func _add_ingredient(type: String) -> void:
	if type == "lemongrass":
		count_lemongrass += 1
	elif type == "shallot":
		count_shallots += 1
	elif type == "chili":
		count_chili += 1
	_update_ingredient_label()

func _update_ingredient_label() -> void:
	ingredient_list_label.text = "Bahan dimasukkan:\n• %d Batang Serai\n• %d Siung Bawang Merah\n• %d Cabai Wakatobi" % [
		count_lemongrass, count_shallots, count_chili
	]

func _on_ingredients_finished() -> void:
	# Correct recipe ratios: 2 Lemongrass, 3 Shallots, 2 Chili
	var diff_l = abs(count_lemongrass - 2)
	var diff_s = abs(count_shallots - 3)
	var diff_c = abs(count_chili - 2)
	
	var total_errors = diff_l + diff_s + diff_c
	# 20% penalty per ingredient count error
	var ingredients_score = max(10.0, 100.0 - total_errors * 20.0)
	
	# Combine cutting and ingredient scores
	prep_accuracy = (cut_score + ingredients_score) / 2.0
	_advance_prep_step()

# ========================================================
# Cooking Station Handlers
# ========================================================

func _on_blow_pressed() -> void:
	current_heat = min(100.0, current_heat + heat_blow_power)
	# Blow particle effect mock
	_flash_pot(Color(1.0, 0.7, 0.2, 0.3))

func _on_drop_fish_pressed() -> void:
	if fish_dropped:
		return
		
	fish_dropped = true
	btn_drop_fish.disabled = true
	
	# Validate if heat is in the green zone when dropping fish
	var is_optimal = current_heat >= green_zone_min and current_heat <= green_zone_max
	if is_optimal:
		fish_drop_perfect = true
		cook_status_label.text = "SUKSES! Ikan masuk di suhu optimal."
		_flash_pot(Color(0.2, 0.9, 0.4, 0.4))
	else:
		fish_drop_perfect = false
		cook_status_label.text = "BURUK! Air terlalu dingin/panas saat memasukkan ikan."
		_flash_pot(Color(0.9, 0.2, 0.2, 0.4))
		
	# Small delay before resuming cook label status
	var t = create_tween()
	t.tween_interval(1.5)
	t.tween_callback(func():
		if current_station == "cooking":
			cook_status_label.text = "Mengukus..."
	)

func _finish_cooking() -> void:
	# Calculate cooking heat accuracy
	if total_cook_seconds > 0.0:
		var heat_score = (optimal_cook_seconds / total_cook_seconds) * 100.0
		cook_accuracy = heat_score
	else:
		cook_accuracy = 0.0
		
	# Apply Sup Parende drop timing penalty
	if selected_dish == "parende" and not fish_drop_perfect:
		cook_accuracy = max(10.0, cook_accuracy - 35.0) # 35% flat penalty
		
	# If Kasuami, prep score is calculated from Kapeo, Hanga, and Kaloli
	if selected_dish == "kasuami":
		prep_accuracy = (kapeo_score + 100.0 + kaloli_score) / 3.0
		
	final_accuracy = (prep_accuracy + cook_accuracy) / 2.0
	
	# Enable serving tab and switch
	tab_serve.disabled = false
	_switch_station("serving")
	_populate_serving_eval()

# ========================================================
# Serving Station Handlers & Scoring
# ========================================================

func _populate_serving_eval() -> void:
	var dish_name = "Kasuami Tradisional" if selected_dish == "kasuami" else "Sup Parende Kakaktua"
	eval_dish_title.text = dish_name
	
	# Compute stars rating (1 to 5)
	var stars = 1
	if final_accuracy >= 92.0:
		stars = 5
	elif final_accuracy >= 80.0:
		stars = 4
	elif final_accuracy >= 60.0:
		stars = 3
	elif final_accuracy >= 40.0:
		stars = 2
		
	# Star character symbols
	var star_chars = ""
	for i in range(5):
		if i < stars:
			star_chars += "★"
		else:
			star_chars += "☆"
	eval_stars.text = star_chars
	
	# Detail breakdown
	eval_breakdown.text = "Akurasi Persiapan (Prep): %d%%\nAkurasi Suhu Masak (Cook): %d%%\nRata-rata Kualitas Rasa: %d%%" % [
		int(prep_accuracy), int(cook_accuracy), int(final_accuracy)
	]
	
	# Assessment reviews
	var review_text = ""
	if selected_dish == "kasuami":
		if stars == 5:
			review_text = "\"Luar biasa! Tekstur kasuami sangat gembur, kelembaban diperas pas, matang merata di kerucut kaloli. Rasa kelapa alami gurih tercium harum!\""
		elif stars == 4:
			review_text = "\"Kasuami lezat! Tekstur tepung gembur, sedikit terlalu kering/lembab tetapi tingkat kematangannya pas.\""
		elif stars == 3:
			review_text = "\"Kasuami lumayan. Sayang adonannya terlalu basah (pemerasan kurang) atau cetakan agak padat.\""
		else:
			review_text = "\"Kasuami gagal. Singkong basah berair dan adonan mentah di bagian tengah.\""
	else: # parende
		if stars == 5:
			review_text = "\"Sempurna! Kaldu Sup Parende asam pedas menyegarkan. Bumbu serai dan cabai meresap sempurna. Daging Ikan Kakaktua lembut dan tidak hancur!\""
		elif stars == 4:
			review_text = "\"Kuah sup gurih, daging ikan lembut. Hanya saja takaran bumbunya kurang pas sedikit.\""
		elif stars == 3:
			review_text = "\"Ikannya agak keras/hancur karena tidak dimasukkan saat air optimal, rasa sup lumayan pedas.\""
		else:
			review_text = "\"Sup hancur. Daging ikan pecah berkeping-keping karena direbus terlalu mendidih, atau bumbunya hambar.\""
			
	eval_review.text = review_text

func _on_serve_dish() -> void:
	var dish_name = "Kasuami Tradisional" if selected_dish == "kasuami" else "Sup Parende Kakaktua"
	dish_cooked.emit(dish_name, final_accuracy)
	
	# Try updating global story stats if it exists
	var story_state = get_node_or_null("/root/StoryState")
	if story_state:
		# Award reputation points based on cooking score
		var current_rep = story_state.get_variable("reputation_points", 0.0)
		var added_rep = final_accuracy * 0.15
		story_state.set_variable("reputation_points", min(100.0, current_rep + added_rep))
		
	print("Dish served: %s | Score: %d%%" % [dish_name, int(final_accuracy)])
	
	# Restart the minigame index
	_reset_minigame()

# Visual Feedback Flashes
func _flash_screen(color: Color) -> void:
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)

func _flash_pot(color: Color) -> void:
	var pot_rect = $MainContainer/CookingStation/CookingControls/PotVisual
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = color
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pot_rect.add_child(overlay)
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(overlay.queue_free)
