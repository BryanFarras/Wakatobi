extends CharacterBody2D

@export_group("Settings")
@export var speed: float = 50.0
@export var quest_data: BaseQuest 
@export var is_static: bool = false
@export_enum("atas", "bawah", "kiri", "kanan") var default_direction: String = "bawah"

@export_group("Spritesheet Settings")
## RPGMaker VX Ace format spritesheet (.png) containing 8 character slots
@export var spritesheet: Texture2D
## Index (0 to 7) of the character to render from the sheet
@export var character_index: int = 0

@export_group("Spawn Settings")
## StoryState flag that controls NPC presence
@export var visibility_flag: String = ""
## The NPC will exist when this flag's boolean value matches this condition
@export var visible_when_flag_is: bool = true

@onready var sprite: AnimatedSprite2D = $animation
@onready var interact_label: Label = $Label
@onready var ray_cast: RayCast2D = $raycast

var player_in_range: bool = false
var is_talking: bool = false
var last_direction: String = "bawah"

var move_direction: Vector2 = Vector2.DOWN
var wander_timer: float = 0.0

var is_controlled_externally: bool = false
var external_direction: Vector2 = Vector2.ZERO
var external_move_timer: float = 0.0

func _ready() -> void:
	interact_label.hide()
	
	if not visibility_flag.strip_edges().is_empty():
		var flag_name = visibility_flag.strip_edges()
		var flag_value = StoryState.get_flag(flag_name)
		if flag_value != visible_when_flag_is:
			queue_free()
			return
		StoryState.state_changed.connect(_on_story_state_changed)
	
	if spritesheet:
		setup_dynamic_animations()
		sprite.scale = Vector2.ONE
		sprite.position = Vector2(0, -4)
		
	last_direction = default_direction
	sprite.play("idle_" + last_direction)
	if not is_static:
		pilih_arah_baru()

func setup_dynamic_animations() -> void:
	var sf = SpriteFrames.new()
	
	var texture_w = spritesheet.get_width()
	var texture_h = spritesheet.get_height()
	
	var is_single_char = false
	var filename = spritesheet.resource_path.get_file()
	if filename.begins_with("$"):
		is_single_char = true
		
	var frame_w = 0
	var frame_h = 0
	var char_x_offset = 0
	var char_y_offset = 0
	
	if is_single_char:
		frame_w = texture_w / 3
		frame_h = texture_h / 4
	else:
		frame_w = texture_w / 12
		frame_h = texture_h / 8
		
		var char_col = character_index % 4
		var char_row = int(character_index / 4)
		char_x_offset = char_col * (3 * frame_w)
		char_y_offset = char_row * (4 * frame_h)
		
	# RPGMaker VX Ace row mapping: 0=Down, 1=Left, 2=Right, 3=Up
	var row_animations = {
		0: "bawah",
		1: "kiri",
		2: "kanan",
		3: "atas"
	}
	
	for row in range(4):
		var anim_suffix = row_animations[row]
		var walk_anim = "jalan_" + anim_suffix
		var idle_anim = "idle_" + anim_suffix
		
		sf.add_animation(walk_anim)
		sf.add_animation(idle_anim)
		sf.set_animation_speed(walk_anim, 6.0)
		sf.set_animation_loop(walk_anim, true)
		sf.set_animation_speed(idle_anim, 5.0)
		sf.set_animation_loop(idle_anim, true)
		
		# 1. Setup Idle Animation: Only the middle frame (Col 1)
		var idle_atlas = AtlasTexture.new()
		idle_atlas.atlas = spritesheet
		idle_atlas.region = Rect2(
			char_x_offset + 1 * frame_w, 
			char_y_offset + row * frame_h, 
			frame_w, 
			frame_h
		)
		sf.add_frame(idle_anim, idle_atlas)
		
		# 2. Setup Walk Animation: Left (Col 0) -> Middle (Col 1) -> Right (Col 2) -> Middle (Col 1)
		var walk_indices = [0, 1, 2, 1]
		for col in walk_indices:
			var walk_atlas = AtlasTexture.new()
			walk_atlas.atlas = spritesheet
			walk_atlas.region = Rect2(
				char_x_offset + col * frame_w, 
				char_y_offset + row * frame_h, 
				frame_w, 
				frame_h
			)
			sf.add_frame(walk_anim, walk_atlas)
			
	sprite.sprite_frames = sf

func _on_story_state_changed(key: StringName, value: Variant) -> void:
	if str(key) == visibility_flag.strip_edges():
		if typeof(value) == TYPE_BOOL:
			if value != visible_when_flag_is:
				queue_free()

func _physics_process(_delta: float) -> void:
	# Hide interact label if an event is running or the NPC is talking
	if interact_label.visible and (EventManager.is_processing_event or is_talking):
		interact_label.hide()
	elif not interact_label.visible and player_in_range and not EventManager.is_processing_event and not is_talking:
		interact_label.show()

	if is_talking or EventManager.is_processing_event:
		velocity = Vector2.ZERO
		return
		
	if is_controlled_externally:
		external_move_timer -= _delta
		if external_move_timer <= 0:
			is_controlled_externally = false
			velocity = Vector2.ZERO
			if not is_static:
				pilih_arah_baru()
		else:
			move_direction = external_direction
			velocity = move_direction * speed
			update_raycast_rotation()
			play_movement_animation()
			move_and_slide()
		return
		
	if is_static:
		velocity = Vector2.ZERO
		update_raycast_rotation()
		play_movement_animation()
		return
		
	if ray_cast.is_colliding():
		pilih_arah_baru()
	wander_timer -= _delta
	if wander_timer <= 0:
		pilih_arah_baru()
	velocity = move_direction * speed
	update_raycast_rotation()
	play_movement_animation()
	move_and_slide()

func move_externally(dir: Vector2, time: float) -> void:
	external_direction = dir
	external_move_timer = time
	is_controlled_externally = true


func pilih_arah_baru():
	var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.ZERO]
	move_direction = directions.pick_random()
	wander_timer = randf_range(1.5, 4.0)

func update_raycast_rotation():
	if move_direction != Vector2.ZERO:
		ray_cast.target_position = move_direction * 20

func play_movement_animation():
	if velocity.length() == 0:
		sprite.play("idle_" + last_direction)
		return
		
	var direction = "bawah"
	if abs(velocity.x) > abs(velocity.y):
		direction = "kanan" if velocity.x > 0 else "kiri"
	else:
		direction = "bawah" if velocity.y > 0 else "atas"
	
	last_direction = direction
	sprite.play("jalan_" + direction)

func _input(event):
	if event.is_action_pressed("interact") and player_in_range and not is_talking:
		mulai_dialog()

func mulai_dialog():
	# If we have an EventInteractable child node with commands, run its event sequence!
	var event_interactable: EventInteractable = null
	for child in get_children():
		if child is EventInteractable and not child.is_queued_for_deletion():
			event_interactable = child
			break
			
	if event_interactable and event_interactable.event_sequence.size() > 0:
		is_talking = true
		velocity = Vector2.ZERO
		
		# Trigger the event sequence through EventManager
		EventManager.run_event_sequence(event_interactable.event_sequence, event_interactable)
		
		# Await until EventManager finishes processing the event
		while EventManager.is_processing_event:
			await get_tree().process_frame
			
		is_talking = false
		return

	# Fallback to legacy quest dialogue
	if quest_data and quest_data.dialogue:
		is_talking = true
		velocity = Vector2.ZERO
		DialogueManager.show_dialogue_balloon(quest_data.dialogue, "Awal")
		await DialogueManager.dialogue_ended
		is_talking = false

func _on_interaksi_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if body.name == "Player":
		player_in_range = true
		interact_label.show()

func _on_interaksi_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	if body.name == "Player":
		player_in_range = false
		interact_label.hide()
