extends Control

signal minigame_completed
signal minigame_closed

var is_connected = false

func _ready():
	pass

func _process(delta):
	queue_redraw()

func _draw():
	var center = size / 2.0
	
	# Fondo
	draw_rect(Rect2(center.x - 300, center.y - 150, 600, 300), Color(0.15, 0.15, 0.15), true)
	
	# Cables base
	draw_line(Vector2(center.x - 300, center.y), Vector2(center.x - 50, center.y), Color.YELLOW, 15, true)
	
	var right_color = Color.YELLOW if is_connected else Color.DARK_GRAY
	draw_line(Vector2(center.x + 50, center.y), Vector2(center.x + 300, center.y), right_color, 15, true)
	
	# Botón Central (Cosita rotatoria o estática)
	var button_color = Color(0, 1, 0) if is_connected else Color(1, 0, 0)
	draw_circle(center, 40, button_color)
	draw_circle(center, 30, Color(0.2, 0.2, 0.2))
	
	# Dibujar la línea de la conexión dentro del botón
	if is_connected:
		# Línea horizontal
		draw_line(Vector2(center.x - 35, center.y), Vector2(center.x + 35, center.y), Color.YELLOW, 15, true)
	else:
		# Línea vertical (desconectado)
		draw_line(Vector2(center.x, center.y - 35), Vector2(center.x, center.y + 35), Color.DARK_GRAY, 15, true)
		
	# Texto de ayuda
	var font = ThemeDB.fallback_font
	var text = "ACTIVO" if is_connected else "CLICK PARA CONECTAR"
	draw_string(font, Vector2(center.x - 80, center.y - 80), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, button_color)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_connected:
				var mpos = get_local_mouse_position()
				var center = size / 2.0
				if mpos.distance_to(center) < 50:
					is_connected = true
					# Pequeña pausa antes de cerrar
					get_tree().create_timer(1.0).timeout.connect(check_win)
					
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		emit_signal("minigame_closed")
		queue_free()
		get_viewport().set_input_as_handled()

func check_win():
	emit_signal("minigame_completed")
	queue_free()
