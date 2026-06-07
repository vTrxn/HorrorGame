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
