extends Control

signal minigame_completed
signal minigame_closed

var colors = [Color.RED, Color.BLUE, Color.YELLOW, Color.GREEN]
var left_colors = []
var right_colors = []

var connections = {}
var dragging_from = -1

func _ready():
	left_colors = colors.duplicate()
	right_colors = colors.duplicate()
	left_colors.shuffle()
	right_colors.shuffle()

func get_left_pos(idx: int) -> Vector2:
	var center = size / 2.0
	return Vector2(center.x - 200, center.y - 120 + idx * 80)

func get_right_pos(idx: int) -> Vector2:
	var center = size / 2.0
	return Vector2(center.x + 200, center.y - 120 + idx * 80)

func _process(delta):
	queue_redraw()

func _draw():
	var center = size / 2.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.set_corner_radius_all(15)
	style.set_border_width_all(3)
	style.border_color = Color(0.2, 0.6, 0.8, 0.6)
	draw_style_box(style, Rect2(center.x - 300, center.y - 200, 600, 400))
	
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(center.x - 280, center.y - 160), "REPARACIÓN DE CABLES", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.8, 0.8, 0.8))
	
	for i in 4:
		var lp = get_left_pos(i)
		var rp = get_right_pos(i)
		
		draw_circle(lp, 20, left_colors[i])
		draw_circle(rp, 20, right_colors[i])
		draw_circle(lp, 10, Color(0,0,0))
		draw_circle(rp, 10, Color(0,0,0))
		
		if connections.has(i):
			draw_line(lp, get_right_pos(connections[i]), left_colors[i], 15, true)
			
	if dragging_from != -1:
		draw_line(get_left_pos(dragging_from), get_local_mouse_position(), left_colors[dragging_from], 15, true)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mpos = get_local_mouse_position()
				for i in 4:
					if mpos.distance_to(get_left_pos(i)) < 30:
						dragging_from = i
						connections.erase(i)
						break
			else:
				if dragging_from != -1:
					var mpos = get_local_mouse_position()
					for i in 4:
						if mpos.distance_to(get_right_pos(i)) < 30:
							if left_colors[dragging_from] == right_colors[i]:
								connections[dragging_from] = i
								check_win()
					dragging_from = -1
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		emit_signal("minigame_closed")
		queue_free()
		get_viewport().set_input_as_handled()

func check_win():
	if connections.size() == 4:
		emit_signal("minigame_completed")
		queue_free()
