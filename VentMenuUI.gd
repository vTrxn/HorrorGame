extends Control

signal vent_selected(destination_id)
signal menu_closed

var current_vent_node = null

func setup(vent_node):
	current_vent_node = vent_node
	
func _ready():
	var center = get_viewport_rect().size / 2.0
	
	var label = Label.new()
	label.text = "ELIGE DESTINO"
	label.add_theme_font_size_override("font_size", 30)
	label.position = Vector2(center.x - 100, center.y - 100)
	add_child(label)
	
	var y_offset = -40
	if current_vent_node and current_vent_node.get("connected_vents"):
		for dest in current_vent_node.connected_vents:
			var btn = Button.new()
			btn.text = "Tubería " + dest
			btn.add_theme_font_size_override("font_size", 24)
			btn.custom_minimum_size = Vector2(200, 50)
			btn.position = Vector2(center.x - 100, center.y + y_offset)
			btn.connect("pressed", Callable(self, "_on_dest_pressed").bind(dest))
			add_child(btn)
			y_offset += 60

func _on_dest_pressed(dest_id):
	emit_signal("vent_selected", dest_id)
	queue_free()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		emit_signal("menu_closed")
		queue_free()
		get_viewport().set_input_as_handled()
