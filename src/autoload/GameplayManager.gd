extends Node

# ==============================================================================
# GameplayManager.gd — Centralized Global Gameplay Coordinator (Autoload Singleton)
# Bridge controller to unify Fishing, Diving, Cooking, Vehicles, Almanac, Quest, 
# and Inventory systems without rewriting them.
# ==============================================================================

# References to existing global systems / autoloads
@onready var InventorySystem = get_node_or_null("/root/Inventory")
@onready var QuestSystem = get_node_or_null("/root/QuestData")
@onready var AlmanacSystem = null # Bridged via local wrapper to StoryState

# ==============================================================================
# Local Bridges & Mocks
# These classes act as adapters. If the autoloads are renamed or configured differently,
# this coordinator remains decoupled and robust.
# ==============================================================================

class LocalInventorySystem:
	var parent: Node
	
	func _init(p: Node) -> void:
		parent = p
		
	## Exposes the raw inventory slots array (useful for quest/ingredient checks)
	var slots: Array:
		get:
			var inv = parent.get_node_or_null("/root/Inventory")
			if inv:
				return inv.slots
			return []
			
	## Adds an item to the player's inventory by its String ID.
	## If the corresponding .tres resource file does not exist, it dynamically
	## instantiates a placeholder ItemData to prevent compile/runtime crashes.
	func add_item(item_id: String) -> bool:
		var inv = parent.get_node_or_null("/root/Inventory")
		if inv:
			var path = "res://src/resources/items/" + item_id + ".tres"
			var item_data = load(path) as ItemData
			if not item_data:
				# Fallback: dynamically create ItemData resource for robust execution
				item_data = ItemData.new()
				item_data.id = item_id
				item_data.item_name = item_id.replace("_", " ").capitalize()
				print("[InventorySystem Bridge] Created dynamic ItemData for ID: ", item_id)
			return inv.add_item(item_data)
		else:
			push_warning("[InventorySystem Bridge] Inventory autoload not found!")
			return false
			
	## Removes an item from the player's inventory by ID.
	func remove_item(item_id: String) -> void:
		var inv = parent.get_node_or_null("/root/Inventory")
		if inv:
			inv.erase(item_id)
			print("[InventorySystem Bridge] Erased item: ", item_id)
		else:
			push_warning("[InventorySystem Bridge] Inventory autoload not found!")

class LocalQuestSystem:
	var parent: Node
	
	func _init(p: Node) -> void:
		parent = p
		
	## Advances quest objectives and evaluates active quest completion criteria.
	func update_objective(type: String, item_id: String) -> void:
		var qd = parent.get_node_or_null("/root/QuestData")
		if qd:
			print("[QuestSystem Bridge] Objective advanced: type='%s', target='%s'" % [type, item_id])
			# In the Wakatobi quest system, quests complete when needed items exist in Inventory.
			# Let's iterate through active quests and check if any can now be finished.
			for quest_id in qd.active_quests.keys():
				if qd.try_complete_quest(quest_id):
					print("[QuestSystem Bridge] Quest completed: ", quest_id)
		else:
			push_warning("[QuestSystem Bridge] QuestData autoload not found!")

class LocalAlmanacSystem:
	var parent: Node
	
	func _init(p: Node) -> void:
		parent = p
		
	## Unlocks a fauna or culture entry in the Almanac book (via StoryState flags)
	func unlock_entry(entry_id: String) -> void:
		var story_state = parent.get_node_or_null("/root/StoryState")
		if story_state:
			var flag = "almanac_" + entry_id + "_unlocked"
			story_state.set_flag(flag, true)
			print("[AlmanacSystem Bridge] Unlocked Almanac Entry flag: ", flag)
		else:
			push_warning("[AlmanacSystem Bridge] StoryState autoload not found!")
			
	## Logs a narrative day entry into the Almanac travel diary
	func log_diary(diary_id: String) -> void:
		var story_state = parent.get_node_or_null("/root/StoryState")
		if story_state:
			# Maps "day2" to "diary_day2_unlocked" etc.
			var flag = "diary_" + diary_id + "_unlocked"
			if not diary_id.begins_with("diary_"):
				flag = "diary_" + diary_id + "_unlocked"
			story_state.set_flag(flag, true)
			print("[AlmanacSystem Bridge] Unlocked Almanac Diary flag: ", flag)
		else:
			push_warning("[AlmanacSystem Bridge] StoryState autoload not found!")

func _ready() -> void:
	# Instantiate and assign bridges so they can be called directly
	InventorySystem = LocalInventorySystem.new(self)
	QuestSystem = LocalQuestSystem.new(self)
	AlmanacSystem = LocalAlmanacSystem.new(self)
	print("[GameplayManager] Centralized Global Gameplay Coordinator Autoload Initialized.")

# ==============================================================================
# Core API Functions
# ==============================================================================

## Instantiates the Fishing Minigame overlay and registers completion callbacks.
## @param difficulty: Tweak multiplier for fish movement speeds
## @param reward_item_id: Item ID awarded upon catching the fish
func start_fishing(difficulty: float, reward_item_id: String) -> void:
	print("[GameplayManager] Invoking start_fishing (Difficulty: %.2f, Reward: '%s')" % [difficulty, reward_item_id])
	
	var scene_path = "res://src/minigames/fishing/fishing_minigame.tscn"
	var fishing_scene = load(scene_path)
	if not fishing_scene:
		push_error("[GameplayManager] Fishing minigame scene not found at path: " + scene_path)
		return
		
	# Instantiate inside a clean overlay layer to draw on top of the world
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	
	var fishing_instance = fishing_scene.instantiate()
	canvas.add_child(fishing_instance)
	get_tree().current_scene.add_child(canvas)
	
	# Apply difficulty settings dynamically
	if "FishProfile" in fishing_instance:
		if difficulty < 0.5:
			fishing_instance.selected_profile = 0 # EASY_LAZY
		elif difficulty < 1.0:
			fishing_instance.selected_profile = 1 # MEDIUM_SMOOTH
		elif difficulty < 1.5:
			fishing_instance.selected_profile = 2 # HARD_ERRATIC
		else:
			fishing_instance.selected_profile = 3 # LEGENDARY_CHAOTIC
			
	if "fish_speed_base" in fishing_instance:
		fishing_instance.fish_speed_base *= difficulty
		
	# Connect to success/failure signals
	if fishing_instance.has_signal("fishing_success"):
		fishing_instance.fishing_success.connect(func():
			print("[GameplayManager] Fishing Minigame SUCCESS! Rewarding player...")
			# 1. Add item to inventory
			InventorySystem.add_item(reward_item_id)
			# 2. Unlock entry in Almanac
			AlmanacSystem.unlock_entry(reward_item_id)
			# 3. Update Quest objective
			QuestSystem.update_objective("fish_caught", reward_item_id)
			# Clean up UI overlay
			canvas.queue_free()
		)
		
	if fishing_instance.has_signal("fishing_failed"):
		fishing_instance.fishing_failed.connect(func():
			print("[GameplayManager] Fishing Minigame FAILED.")
			canvas.queue_free()
		)

## Initiates the Cooking Simulation scene overlay after verifying ingredients.
## @param dish_name: Name of the dish target ("Kasuami" or "Sup Parende")
## @param ingredients: Array of ingredient item ID strings required to cook
func start_cooking(dish_name: String, ingredients: Array) -> void:
	print("[GameplayManager] Invoking start_cooking (Dish: '%s', Ingredients: %s)" % [dish_name, str(ingredients)])
	
	# Validate ingredients count in inventory
	var temp_inv = []
	for slot in InventorySystem.slots:
		if slot != null:
			temp_inv.append(slot.id)
			
	var missing = []
	for ing in ingredients:
		var idx = temp_inv.find(ing)
		if idx != -1:
			temp_inv.remove_at(idx)
		else:
			missing.append(ing)
			
	if missing.size() > 0:
		print("[GameplayManager] Cannot start cooking. Missing ingredients from Inventory: ", missing)
		return
		
	var scene_path = "res://src/minigames/cooking/cooking_system.tscn"
	var cooking_scene = load(scene_path)
	if not cooking_scene:
		push_error("[GameplayManager] Cooking simulation scene not found at path: " + scene_path)
		return
		
	# Instantiate inside overlay canvas
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	
	var cooking_instance = cooking_scene.instantiate()
	canvas.add_child(cooking_instance)
	get_tree().current_scene.add_child(canvas)
	
	# Pre-select the dish in cooking system
	if cooking_instance.has_method("_start_dish"):
		if dish_name.to_lower().contains("kasuami"):
			cooking_instance._start_dish("kasuami")
		elif dish_name.to_lower().contains("parende"):
			cooking_instance._start_dish("parende")
			
	# Connect to serving callback signal
	if cooking_instance.has_signal("dish_cooked"):
		cooking_instance.dish_cooked.connect(func(final_dish_name: String, score: float):
			if score > 70.0:
				print("[GameplayManager] Cooking SUCCESS (Score: %.1f%%)! Processing rewards..." % score)
				# 1. Remove ingredients
				for ing in ingredients:
					InventorySystem.remove_item(ing)
				
				# 2. Add finished dish to inventory
				var dish_id = "kasuami"
				if final_dish_name.to_lower().contains("parende") or dish_name.to_lower().contains("parende"):
					dish_id = "sup_parende"
				InventorySystem.add_item(dish_id)
				
				# 3. Increase Pesisir Reputation
				var story_state = get_node_or_null("/root/StoryState")
				if story_state:
					var current_rep = story_state.get_variable("reputation_points", 65.0)
					story_state.set_variable("reputation_points", min(100.0, current_rep + 10.0))
					
				# 4. Log diary entry into Almanac
				AlmanacSystem.log_diary("day2")
			else:
				print("[GameplayManager] Cooking FAILED due to low quality score (%.1f%%)." % score)
				
			canvas.queue_free()
		)

## Switches the player between foot and vehicle navigation, or launches the diving minigame.
## @param new_state: String ("ON_FOOT", "BICYCLE", "KAYAK", "DIVING")
func transition_player_state(new_state: String) -> void:
	print("[GameplayManager] Transitioning player state to: ", new_state)
	
	# Handle deep water diving (triggers a scene switch to the diving map)
	if new_state == "DIVING":
		var path = "res://src/minigames/diving/diving_game_level.tscn"
		var scene_manager = get_node_or_null("/root/SceneManager")
		if scene_manager:
			# Transition using the scene manager to support coordinates and fades
			scene_manager.go_to_scene_position(path, Vector2(960, 50))
		else:
			# Fallback direct change
			get_tree().change_scene_to_file(path)
		return
		
	# Handle vehicle state switches
	var player = PlayerManager.get_player()
	if player:
		if player.has_method("_transition_to_state"):
			var state_enum = -1
			if new_state == "ON_FOOT":
				state_enum = 0
			elif new_state == "BICYCLE":
				state_enum = 1
			elif new_state == "KAYAK":
				state_enum = 2
				
			if state_enum != -1:
				player._transition_to_state(state_enum)
				
				# Ensure that when entering KAYAK, the game UI updates to show the Wind Compass
				if new_state == "KAYAK":
					var compass = player.get_node_or_null("HUD/WindCompass")
					if compass:
						compass.show()
	else:
		push_warning("[GameplayManager] Active player node not registered in PlayerManager. State transition skipped: " + new_state)
