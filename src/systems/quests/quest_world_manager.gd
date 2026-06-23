extends Node2D
class_name QuestWorldManager

# ==============================================================================
# quest_world_manager.gd — Quest & Environmental Coordinator
# Scene-level script managing global states like Walillah Dimension shifts.
# ==============================================================================

@export_group("Cinematic Cameras")
## Sibling virtual camera (PhantomCamera2D) that frames the sky/sea
@export var sky_pcam: Node2D

@export_group("Realm Shifting Effects")
## CanvasModulate node used to tint the world scene to dark/hologram theme
@export var walillah_filter: CanvasModulate
## Loop AudioStreamPlayer for dark ambient wind/mystical sounds
@export var dark_ambient_audio: AudioStreamPlayer
## Sibling AudioStreamPlayer containing normal background music to fade
@export var normal_music_player: AudioStreamPlayer

@export_group("UI & Navigation")
## CanvasLayer node representing the player HUD/maps to hide during shift
@export var player_hud: CanvasLayer

var is_realm_shifted: bool = false

func _ready() -> void:
	# Register this manager instance to the global coordinator
	var gameplay_manager = get_node_or_null("/root/GameplayManager")
	if gameplay_manager:
		gameplay_manager.quest_world_manager = self
		print("[QuestWorldManager] Registered successfully to GameplayManager.")
	else:
		push_warning("[QuestWorldManager] GameplayManager autoload not found!")
		
	# Setup initial default states
	if walillah_filter:
		walillah_filter.color = Color.WHITE
	if dark_ambient_audio:
		dark_ambient_audio.stop()

## Coordinates snapping camera, fading ambient tracks, modifying tints, and hiding HUDs
func trigger_realm_shift(active: bool) -> void:
	if is_realm_shifted == active:
		return
		
	is_realm_shifted = active
	print("[QuestWorldManager] Executing Realm Shift -> Active: ", active)
	
	# 1. Snap Camera focus to sky/sea virtual camera
	if sky_pcam and sky_pcam.has_method("set_priority"):
		# Set camera priority higher than normal player camera (10)
		sky_pcam.call("set_priority", 30 if active else 0)
		
	# 2. Interpolate audio transitions smoothly
	if active:
		if normal_music_player:
			_fade_audio_volume(normal_music_player, -60.0, 1.2, true)
		if dark_ambient_audio:
			dark_ambient_audio.volume_db = -60.0
			dark_ambient_audio.play()
			_fade_audio_volume(dark_ambient_audio, 0.0, 1.2)
	else:
		if dark_ambient_audio:
			_fade_audio_volume(dark_ambient_audio, -60.0, 1.2, true)
		if normal_music_player:
			normal_music_player.volume_db = -60.0
			normal_music_player.play()
			_fade_audio_volume(normal_music_player, 0.0, 1.2)
			
	# 3. Animate CanvasModulate color filtering to dark hologram/mystical theme
	if walillah_filter:
		# Deep dark purple/blue shade when shifted, normal white color when recovered
		var target_color = Color(0.08, 0.12, 0.28, 1.0) if active else Color.WHITE
		var tween = create_tween()
		tween.tween_property(walillah_filter, "color", target_color, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# 4. Enforce blind navigation by hiding standard HUD overlays
	if player_hud:
		player_hud.visible = not active
		print("[QuestWorldManager] Player HUD visibility: ", player_hud.visible)

## Helper function to smoothly fade AudioStreamPlayer volume
func _fade_audio_volume(audio_node: AudioStreamPlayer, target_db: float, duration: float, stop_on_finish: bool = false) -> void:
	if audio_node == null:
		return
		
	var tween = create_tween()
	tween.tween_property(audio_node, "volume_db", target_db, duration).set_trans(Tween.TRANS_LINEAR)
	if stop_on_finish:
		tween.chain().tween_callback(audio_node.stop)
