extends Control

var texture_rect: TextureRect

func _ready():
	texture_rect = TextureRect.new()
	texture_rect.set_anchors_preset(PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(texture_rect)
	
	# Godot will import MapImage.webp and we load it directly
	var tex = load("res://MapImage.webp")
	if tex:
		texture_rect.texture = tex
	
	visible = false

func toggle_map():
	visible = not visible
