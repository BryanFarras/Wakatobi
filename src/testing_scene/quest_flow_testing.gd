extends "res://src/systems/quests/quest_world_manager.gd"

# ==============================================================================
# quest_flow_testing.gd — Interactive Sandbox for Wakatobi Quest Flow Testing
# ==============================================================================

var debug_canvas: CanvasLayer
var label_quest1_active: Label
var label_quest1_complete: Label
var label_quest2_active: Label
var label_quest2_complete: Label
var label_inventory: Label
var label_realm_state: Label

var btn_q1_act: CheckButton
var btn_q1_comp: CheckButton
var btn_q2_act: CheckButton
var btn_q2_comp: CheckButton

func _ready() -> void:
	# Call parent ready to register with GameplayManager
	super._ready()
	
	# Listen to state changes to update the UI
	StoryState.state_changed.connect(_on_story_state_changed)
	
	if DisplayServer.get_name() == "headless" or "--test" in OS.get_cmdline_args():
		_run_automated_tests()
	else:
		# Create debug overlay UI
		_create_debug_ui()
		# Update initially
		_update_debug_ui_display()

func _run_automated_tests() -> void:
	# 1 frame delay to let setup complete
	await get_tree().process_frame
	
	print("[Integration Test] Running assertions...")
	
	# Test 1: Autoload registry
	assert(GameplayManager != null, "GameplayManager autoload should be active")
	assert(GameplayManager.quest_world_manager == self, "QuestWorldManager should register itself to GameplayManager")
	print("[Integration Test] Test 1: Autoload & Registry check PASSED")

	# Test 2: Realm Shift ON
	GameplayManager.trigger_realm_shift(true)
	assert(is_realm_shifted == true, "Realm shift state should be active")
	await get_tree().create_timer(1.6).timeout
	assert(walillah_filter.color == Color(0.08, 0.12, 0.28, 1.0), "CanvasModulate color should transition to dark tint")
	assert(player_hud.visible == false, "Player HUD should be hidden in Walillah dimension")
	print("[Integration Test] Test 2: Realm Shift ON check PASSED")
	
	# Test 3: Realm Shift OFF
	GameplayManager.trigger_realm_shift(false)
	assert(is_realm_shifted == false, "Realm shift state should be inactive")
	await get_tree().create_timer(1.6).timeout
	assert(walillah_filter.color == Color.WHITE, "CanvasModulate color should transition back to white")
	assert(player_hud.visible == true, "Player HUD should be visible in Normal dimension")
	print("[Integration Test] Test 3: Realm Shift OFF check PASSED")


	# Test 4: Interactable Component & Quest Conditions
	var elder_interactable = get_node("VillageElder/ElderInteractable") as InteractableComponent
	assert(elder_interactable != null, "ElderInteractable node should exist")
	assert(elder_interactable.interactable_name == "Village Elder", "Interactable name should be correct")
	assert(elder_interactable.dialogue_start_node == "start_elder", "Initial start node should be correct")
	
	# Test required quest state check
	StoryState.set_flag("quest1_active", false)
	assert(elder_interactable.is_quest_state_valid() == false, "Quest state should be invalid when required flag is false")
	
	StoryState.set_flag("quest1_active", true)
	assert(elder_interactable.is_quest_state_valid() == true, "Quest state should be valid when required flag is true")
	print("[Integration Test] Test 4: Interactable Component validation check PASSED")
	
	# Test 5: Minigame Completion callback & Dialogue state transition
	# Trigger fishing success callback
	GameplayManager.fishing_completed.emit(true, "ikan_kakaktua")
	# Yield a frame to let signal process
	await get_tree().process_frame
	
	assert(StoryState.get_flag("quest1_complete") == true, "Quest 1 complete flag should be set automatically upon success")
	assert(elder_interactable.dialogue_start_node == "start_cooking", "Dialogue start node should transition to post_quest_start_node")
	print("[Integration Test] Test 5: Minigame completion transition check PASSED")
	
	# Test 6: Cooking Minigame Completion callback
	elder_interactable.required_quest_state = "quest2_active"
	StoryState.set_flag("quest2_active", true)
	GameplayManager.cooking_completed.emit(true, "Sup Parende")
	await get_tree().process_frame
	
	assert(StoryState.get_flag("quest2_complete") == true, "Quest 2 complete flag should be set automatically upon success")
	print("[Integration Test] Test 6: Cooking completion transition check PASSED")

	print("[Integration Test] ALL TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)


func _process(delta: float) -> void:
	# Keep updating inventory display dynamically
	_update_inventory_display()

func _create_debug_ui() -> void:
	debug_canvas = CanvasLayer.new()
	debug_canvas.layer = 99
	add_child(debug_canvas)
	
	# Panel background
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 480)
	panel.position = Vector2(20, 20)
	debug_canvas.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(330, 460)
	margin.position = Vector2(10, 10)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.theme_type_variation = "VBoxContainer"
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "WAKATOBI QUEST FLOW TESTBED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Walk around: Arrow keys / WASD\nInteract: Press 'E' near NPC or Rock\n\nCheat & Toggle values below:"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)
	
	vbox.add_child(HSeparator.new())
	
	# Quest state checks
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	var l1 = Label.new()
	l1.text = "Quest 1 Active:"
	grid.add_child(l1)
	btn_q1_act = CheckButton.new()
	btn_q1_act.toggled.connect(func(val): StoryState.set_flag("quest1_active", val))
	grid.add_child(btn_q1_act)
	
	var l2 = Label.new()
	l2.text = "Quest 1 Complete:"
	grid.add_child(l2)
	btn_q1_comp = CheckButton.new()
	btn_q1_comp.toggled.connect(func(val): StoryState.set_flag("quest1_complete", val))
	grid.add_child(btn_q1_comp)
	
	var l3 = Label.new()
	l3.text = "Quest 2 Active:"
	grid.add_child(l3)
	btn_q2_act = CheckButton.new()
	btn_q2_act.toggled.connect(func(val): StoryState.set_flag("quest2_active", val))
	grid.add_child(btn_q2_act)
	
	var l4 = Label.new()
	l4.text = "Quest 2 Complete:"
	grid.add_child(l4)
	btn_q2_comp = CheckButton.new()
	btn_q2_comp.toggled.connect(func(val): StoryState.set_flag("quest2_complete", val))
	grid.add_child(btn_q2_comp)
	
	vbox.add_child(HSeparator.new())
	
	# Realm State display
	label_realm_state = Label.new()
	label_realm_state.text = "Realm State: NORMAL"
	vbox.add_child(label_realm_state)
	
	# Manual realm shift button
	var btn_realm = Button.new()
	btn_realm.text = "Manual Realm Shift (Toggle)"
	btn_realm.pressed.connect(func():
		var target = not is_realm_shifted
		GameplayManager.trigger_realm_shift(target)
	)
	vbox.add_child(btn_realm)
	
	vbox.add_child(HSeparator.new())
	
	# Inventory actions
	label_inventory = Label.new()
	label_inventory.text = "Inventory: []"
	label_inventory.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(label_inventory)
	
	var hbox_inv = HBoxContainer.new()
	vbox.add_child(hbox_inv)
	
	var btn_add_fish = Button.new()
	btn_add_fish.text = "+ Kakaktua Fish"
	btn_add_fish.pressed.connect(func():
		GameplayManager.InventorySystem.add_item("ikan_kakaktua")
		_update_inventory_display()
	)
	hbox_inv.add_child(btn_add_fish)
	
	var btn_add_ing = Button.new()
	btn_add_ing.text = "+ Ingredients"
	btn_add_ing.pressed.connect(func():
		GameplayManager.InventorySystem.add_item("bawang")
		GameplayManager.InventorySystem.add_item("serai")
		GameplayManager.InventorySystem.add_item("cabai")
		_update_inventory_display()
	)
	hbox_inv.add_child(btn_add_ing)
	
	var btn_clear_inv = Button.new()
	btn_clear_inv.text = "Clear Inv"
	btn_clear_inv.pressed.connect(func():
		# Clear inventory items
		var inv = get_node_or_null("/root/Inventory")
		if inv:
			inv.slots.clear()
			# Re-fill with empty slots if inventory layout requires it
			for i in range(16):
				inv.slots.append(null)
			inv.emit_signal("inventory_changed")
		_update_inventory_display()
	)
	hbox_inv.add_child(btn_clear_inv)
	
	var btn_reset_all = Button.new()
	btn_reset_all.text = "Reset Quest Flags"
	btn_reset_all.pressed.connect(func():
		StoryState.reset()
		if btn_q1_act: btn_q1_act.button_pressed = false
		if btn_q1_comp: btn_q1_comp.button_pressed = false
		if btn_q2_act: btn_q2_act.button_pressed = false
		if btn_q2_comp: btn_q2_comp.button_pressed = false
		_update_debug_ui_display()
	)
	vbox.add_child(btn_reset_all)

func _on_story_state_changed(key: StringName, value: Variant) -> void:
	_update_debug_ui_display()

func _update_debug_ui_display() -> void:
	if debug_canvas == null or label_realm_state == null:
		return
		
	if btn_q1_act:
		btn_q1_act.button_pressed = StoryState.get_flag("quest1_active")
	if btn_q1_comp:
		btn_q1_comp.button_pressed = StoryState.get_flag("quest1_complete")
	if btn_q2_act:
		btn_q2_act.button_pressed = StoryState.get_flag("quest2_active")
	if btn_q2_comp:
		btn_q2_comp.button_pressed = StoryState.get_flag("quest2_complete")
	
	label_realm_state.text = "Realm State: WALILLAH" if is_realm_shifted else "Realm State: NORMAL"

func _update_inventory_display() -> void:
	if label_inventory == null:
		return
	var items = []
	var inv = get_node_or_null("/root/Inventory")
	if inv:
		for slot in inv.slots:
			if slot != null:
				items.append(slot.id)
	label_inventory.text = "Inventory: " + str(items)
