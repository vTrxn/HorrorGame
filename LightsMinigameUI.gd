extends CanvasLayer

signal minigame_completed
signal minigame_closed

var switches = [false, false, false, false, false]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	for i in range(5):
		var btn = get_node("Panel/VBoxContainer/HBoxContainer/Switch" + str(i))
		btn.pressed.connect(Callable(self, "_on_switch_pressed").bind(i))
		
		# set some random starting states, but at least one must be false
		switches[i] = randf() > 0.5
	
	# ensure at least one is false so the game isn't auto-won
	switches[randi() % 5] = false
	
	update_switches()

func _on_switch_pressed(index: int):
	switches[index] = not switches[index]
	update_switches()
	check_win()

func update_switches():
	for i in range(5):
		var btn = get_node("Panel/VBoxContainer/HBoxContainer/Switch" + str(i))
		if switches[i]:
			btn.text = "ON"
			btn.modulate = Color(0, 1, 0)
		else:
			btn.text = "OFF"
			btn.modulate = Color(1, 0, 0)

func check_win():
	var all_on = true
	for s in switches:
		if not s:
			all_on = false
			break
	if all_on:
		emit_signal("minigame_completed")
		close()

func _on_close_button_pressed():
	emit_signal("minigame_closed")
	close()

func close():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
