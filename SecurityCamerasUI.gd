extends CanvasLayer

signal minigame_closed
var cam_ids = []

func setup(ids: Array[String]):
	cam_ids = ids

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CloseButton.pressed.connect(_on_close_button_pressed)
	
	var all_cams = get_tree().get_nodes_in_group("security_cameras")
	var textures = []
	var names = []
	for id in cam_ids:
		for c in all_cams:
			if c.camera_id == id:
				textures.append(c.get_camera_texture())
				names.append(id)
				break
	
	if textures.size() > 0: setup_screen($ColorRect/GridContainer/Cam1, textures[0], names[0])
	if textures.size() > 1: setup_screen($ColorRect/GridContainer/Cam2, textures[1], names[1])
	if textures.size() > 2: setup_screen($ColorRect/GridContainer/Cam3, textures[2], names[2])
	if textures.size() > 3: setup_screen($ColorRect/GridContainer/Cam4, textures[3], names[3])

func setup_screen(cam_rect: TextureRect, tex: Texture, cam_name: String):
	cam_rect.texture = tex
	
	var border_panel = Panel.new()
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 3
	border_style.border_width_top = 3
	border_style.border_width_right = 3
	border_style.border_width_bottom = 3
	border_style.border_color = Color(0.8, 0.8, 0.8, 0.8)
	border_panel.add_theme_stylebox_override("panel", border_style)
	cam_rect.add_child(border_panel)
	
	var text_panel = PanelContainer.new()
	text_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	text_panel.position = Vector2(10, 10)
	var text_style = StyleBoxFlat.new()
	text_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	text_style.border_width_left = 2
	text_style.border_width_top = 2
	text_style.border_width_right = 2
	text_style.border_width_bottom = 2
	text_style.border_color = Color(0.8, 0.8, 0.8, 0.5)
	text_style.corner_radius_top_left = 4
	text_style.corner_radius_top_right = 4
	text_style.corner_radius_bottom_right = 4
	text_style.corner_radius_bottom_left = 4
	text_panel.add_theme_stylebox_override("panel", text_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	
	var label = Label.new()
	label.text = cam_name
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	
	margin.add_child(label)
	text_panel.add_child(margin)
	cam_rect.add_child(text_panel)

func _on_close_button_pressed():
	emit_signal("minigame_closed")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
