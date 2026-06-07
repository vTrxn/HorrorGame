extends CanvasLayer

func _ready():
	visible = false

func toggle():
	visible = !visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	toggle()

func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_quit_pressed():
	# Podría regresar al MainMenu, pero desconectar el cliente/servidor es más complicado aquí.
	# Simplemente cerraremos el juego por ahora o se podría limpiar la escena
	get_tree().quit()
