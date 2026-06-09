extends CharacterBody2D

@export_group("Settings")
@export var speed: float = 50.0
@export var quest_data: BaseQuest 

@onready var sprite: AnimatedSprite2D = $animation
@onready var interact_label: Label = $Label
@onready var ray_cast: RayCast2D = $raycast

var player_in_range: bool = false
var is_talking: bool = false
var last_direction: String = "bawah"

var move_direction: Vector2 = Vector2.DOWN
var wander_timer: float = 0.0

func _ready() -> void:
	interact_label.hide()
	sprite.play("idle_bawah")
	pilih_arah_baru()

func _physics_process(_delta: float) -> void:
	if is_talking:
		velocity = Vector2.ZERO
		move_and_slide()
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
