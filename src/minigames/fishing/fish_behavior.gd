extends Area2D
class_name FishBehavior

@export_group("Fish Attributes")
## User-facing display name of the fish
@export var fish_name: String = ""
## String ID matching inventory and almanac entries
@export var item_id: String = ""
## True if this is Ikan Kakaktua (triggers the reel minigame), false for bonus fish
@export var is_major: bool = false
## Horizontal swimming speed (pixels/second)
@export var speed: float = 80.0
## Fallback visual color in case textures fail to load
@export var color: Color = Color.WHITE

# Movement state
var direction: float = 1.0 # 1.0 = Right, -1.0 = Left
var boundary_left: float = 50.0
var boundary_right: float = 1100.0

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# Add to "fish" group for easy collision checks
	add_to_group("fish")
	
	# Dynamically load the fish texture based on item_id if texture is not set
	if sprite:
		# Map custom items to their texture filenames
		if item_id == "ikan_kakaktua" or item_id == "ikan_kakatua":
			sprite.play("kakatua")
			sprite.flip_h = true
		elif item_id == "glofish":
			sprite.play("tetra")
		elif item_id == "yellow_tang":
			sprite.play("yellow_tang")
		elif item_id == "ikan_kakap":
			sprite.play("kakap")

	# Randomize initial direction and speed slightly to make movement natural
	direction = 1.0 if randf() > 0.5 else -1.0
	speed = randf_range(speed * 0.85, speed * 1.15)
	
	_update_visual_direction()

func _physics_process(delta: float) -> void:
	# Horizontal movement logic
	global_position.x += direction * speed * delta
	
	# Check boundary collisions and turn around
	if global_position.x <= boundary_left:
		global_position.x = boundary_left
		direction = 1.0
		_update_visual_direction()
	elif global_position.x >= boundary_right:
		global_position.x = boundary_right
		direction = -1.0
		_update_visual_direction()

func _update_visual_direction() -> void:
	# Assume the source texture faces left by default.
	# Moving right (direction = 1) -> flip texture horizontally to face right.
	# Moving left (direction = -1) -> normal texture facing left.
	if sprite and sprite.visible:
		if item_id != "ikan_kakaktua": 
			sprite.flip_h = (direction > 0)
		else :
			sprite.flip_h = (direction < 0)
	elif color_rect and color_rect.visible:
		# Modulate or shift pivot just in case, but ColorRect doesn't need scaling usually.
		pass
