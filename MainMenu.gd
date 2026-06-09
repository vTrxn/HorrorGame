extends Control

@onready var role_option = $VBoxContainer/RoleOption
@onready var color_option = $VBoxContainer/ColorOption
@onready var ip_line_edit = $VBoxContainer/IPLineEdit

func _ready():
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.set_corner_radius_all(15)
	style.set_border_width_all(2)
	style.border_color = Color(0.2, 0.6, 0.8, 0.5)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var vbox = $VBoxContainer
	remove_child(vbox)
	panel.add_child(vbox)
	center_container.add_child(panel)
	
	var title = vbox.get_node("Label")
	if title:
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	
	vbox.add_theme_constant_override("separation", 15)
	
	for child in vbox.get_children():
		if child is Button and child.name != "RoleOption" and child.name != "ColorOption":
			child.custom_minimum_size = Vector2(250, 45)
			var b_style = StyleBoxFlat.new()
			b_style.bg_color = Color(0.15, 0.15, 0.2)
			b_style.set_corner_radius_all(8)
			b_style.set_border_width_all(1)
			b_style.border_color = Color(0.4, 0.4, 0.5)
			child.add_theme_stylebox_override("normal", b_style)
			
			var h_style = b_style.duplicate()
			h_style.bg_color = Color(0.2, 0.4, 0.5)
			child.add_theme_stylebox_override("hover", h_style)
			child.add_theme_font_size_override("font_size", 20)
		elif child is OptionButton or child is LineEdit:
			child.custom_minimum_size = Vector2(250, 40)
			child.add_theme_font_size_override("font_size", 18)

func _on_host_pressed():
	MultiplayerManager.host_game(role_option.selected, color_option.selected)

func _on_join_pressed():
	var ip = ip_line_edit.text
	if ip == "":
		ip = "127.0.0.1"
	MultiplayerManager.join_game(role_option.selected, color_option.selected, ip)
