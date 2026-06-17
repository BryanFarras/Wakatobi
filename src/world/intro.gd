extends Control

@export_multiline var Text:PackedStringArray
@export var Images:Array[Texture2D]

@onready var anim = $Animation
@onready var label = $Blackscreen/Lower/CenterContainer/VBoxContainer/Narasi
@onready var image = $Blackscreen/Upper/Centering/MarginContainer/Images
@onready var audio = $AudioStreamPlayer

var progress:int = 0
var characters:int = 0

func _ready() -> void:
	buat_animasi_dinamis(Text, Images)
	if anim.get_animation_library_list().size() > 0 :
		anim.play(anim.get_animation_list()[0])

func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_SPACE) && anim.is_playing() != true :
		if progress < anim.get_animation_list().size():
			anim.play(anim.get_animation_list()[progress])
		else : get_tree().change_scene_to_packed(load("res://Resource/gameplay.tscn"))

func buat_animasi_dinamis(daftar_teks: PackedStringArray, daftar_gambar: Array[Texture2D]):
	var lib = anim.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		anim.add_animation_library("", lib)
	for i in range(daftar_teks.size()):
		var nama_anim = str(i)
		var anim = Animation.new()
		anim.length = 2
	
		var track_label_text = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_label_text, str(get_path_to(label)) + ":text")
		anim.track_insert_key(track_label_text, 0.0, daftar_teks[i])
		var track_label_characters = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_label_characters, str(get_path_to(label)) + ":visible_characters")
		anim.track_insert_key(track_label_characters, 0.0, 0)
		anim.track_set_path(track_label_characters, str(get_path_to(label)) + ":visible_characters")
		anim.track_insert_key(track_label_characters, 2.0, daftar_teks[i].length())
		
		if i < daftar_gambar.size():
			var track_sprite = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(track_sprite, str(get_path_to(image)) + ":texture")
			var tex = daftar_gambar[i]
			anim.track_insert_key(track_sprite, 0.0, tex)
		
		if lib.has_animation(nama_anim):
			lib.remove_animation(nama_anim)
		lib.add_animation(nama_anim, anim)

func _process(delta: float) -> void:
	if label.visible_characters > characters :
		var sound = randi_range(0,2)
		if sound == 0 : 
			audio.set_stream(load("res://Resource/SFX/Typing/keypress-001.wav"))
		elif sound == 0 : 
			audio.set_stream(load("res://Resource/SFX/Typing/keypress-002.wav"))
		elif sound == 0 : 
			audio.set_stream(load("res://Resource/SFX/Typing/keypress-003.wav"))
		audio.play()
		characters = label.visible_characters

func _on_animation_animation_finished(anim_name: StringName) -> void:
	progress += 1

func _on_animation_current_animation_changed(name: String) -> void:
	characters = 0
