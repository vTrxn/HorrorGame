extends Control

signal vent_selected(destination_id)
signal menu_closed

var current_vent_node = null

func setup(vent_node):
	current_vent_node = vent_node
	
func _ready():
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.set_corner_radius_all(15)
	style.set_border_width_all(3)
	style.border_color = Color(0.2, 0.6, 0.8, 0.6)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "SISTEMA DE VENTILACIÓN"
	label.add_theme_font_size_override("font_size", 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.15, 0.2)
	btn_style.set_corner_radius_all(8)
	btn_style.set_border_width_all(1)
	btn_style.border_color = Color(0.4, 0.4, 0.5)
	
	var h_style = btn_style.duplicate()
	h_style.bg_color = Color(0.2, 0.4, 0.5)
	
	if current_vent_node and current_vent_node.get("connected_vents"):
		for dest in current_vent_node.connected_vents:
			var btn = Button.new()
			btn.text = "Ir a Tubería " + dest
			btn.add_theme_font_size_override("font_size", 24)
			btn.custom_minimum_size = Vector2(250, 50)
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", h_style)
			btn.connect("pressed", Callable(self, "_on_dest_pressed").bind(dest))
			vbox.add_child(btn)
			
	add_child(panel)
	call_deferred("_center_panel", panel)

func _center_panel(panel):
	panel.position = get_viewport_rect().size / 2.0 - panel.size / 2.0

func _on_dest_pressed(dest_id):
	emit_signal("vent_selected", dest_id)
	queue_free()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		emit_signal("menu_closed")
		queue_free()
		get_viewport().set_input_as_handled()
