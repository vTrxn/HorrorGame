extends CanvasLayer

signal minigame_completed
signal minigame_closed

var progress = 0.0
var is_upload = false
var downloading = false

func set_mode(upload: bool):
	is_upload = upload
	if is_upload:
		$Panel/VBoxContainer/Title.text = "Subiendo Datos..."
		$Panel/VBoxContainer/StartButton.text = "Subir"
	else:
		$Panel/VBoxContainer/Title.text = "Descargando Datos..."
		$Panel/VBoxContainer/StartButton.text = "Descargar"

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Panel/VBoxContainer/ProgressBar.value = 0
	$Panel/VBoxContainer/StartButton.pressed.connect(Callable(self, "_on_start_pressed"))
	$Panel/VBoxContainer/CloseButton.pressed.connect(Callable(self, "_on_close_pressed"))
	
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	p_style.set_corner_radius_all(15)
	p_style.set_border_width_all(3)
	p_style.border_color = Color(0.2, 0.6, 0.8, 0.6)
	$Panel.add_theme_stylebox_override("panel", p_style)
	
	var title = $Panel/VBoxContainer/Title
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.15, 0.2)
	btn_style.set_corner_radius_all(8)
	btn_style.set_border_width_all(1)
	btn_style.border_color = Color(0.4, 0.4, 0.5)
	
	var h_style = btn_style.duplicate()
	h_style.bg_color = Color(0.2, 0.4, 0.5)
	
	for btn in [$Panel/VBoxContainer/StartButton, $Panel/VBoxContainer/CloseButton]:
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", h_style)
		btn.add_theme_font_size_override("font_size", 18)

func _process(delta):
	if downloading:
		progress += delta * 20.0 # 5 seconds to reach 100
		$Panel/VBoxContainer/ProgressBar.value = progress
		if progress >= 100.0:
			downloading = false
			$Panel/VBoxContainer/Title.text = "Completado!"
			$Panel/VBoxContainer/StartButton.disabled = true
			await get_tree().create_timer(1.0).timeout
			emit_signal("minigame_completed")
			close()

func _on_start_pressed():
	if not downloading and progress < 100.0:
		downloading = true
		$Panel/VBoxContainer/StartButton.disabled = true

func _on_close_pressed():
	emit_signal("minigame_closed")
	close()

func close():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
