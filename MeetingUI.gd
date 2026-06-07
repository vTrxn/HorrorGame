extends CanvasLayer

var votes = {} # voter_id -> target_id
var alive_players = []
var meeting_ended = false

@rpc("any_peer", "call_local", "reliable")
func receive_vote(voter_id: String, target_id: String):
	votes[voter_id] = target_id
	print("Vote received: ", voter_id, " voted for ", target_id)

func _ready():
	layer = 10
	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 15)
	center.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "¡REUNIÓN DE EMERGENCIA!\nVota por un jugador:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	vbox.add_child(lbl)
	
	var players_node = get_tree().root.get_node_or_null("World/Players")
	if players_node:
		for p in players_node.get_children():
			if "is_ghost" in p and not p.is_ghost:
				alive_players.append(p.name)
				var btn = Button.new()
				btn.text = "Votar por: " + str(p.name)
				btn.add_theme_font_size_override("font_size", 24)
				btn.pressed.connect(self._on_vote_btn.bind(str(p.name)))
				vbox.add_child(btn)
			
	var skip_btn = Button.new()
	skip_btn.text = "Saltar voto"
	skip_btn.add_theme_font_size_override("font_size", 24)
	skip_btn.pressed.connect(self._on_vote_btn.bind("skip"))
	vbox.add_child(skip_btn)
	
	var timer_lbl = Label.new()
	timer_lbl.name = "TimerLabel"
	timer_lbl.text = "30"
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(timer_lbl)
	
	var t = Timer.new()
	t.name = "MeetingTimer"
	t.wait_time = 30.0
	t.one_shot = true
	t.timeout.connect(_on_timeout)
	add_child(t)
	t.start()
	
	var bus_name = "MeetingEcho"
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		AudioServer.add_bus()
		bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_idx, bus_name)
		var echo = AudioEffectReverb.new()
		echo.room_size = 0.8
		echo.damping = 0.5
		echo.wet = 0.5
		AudioServer.add_bus_effect(bus_idx, echo)
		AudioServer.set_bus_send(bus_idx, "Master")
		
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://among-us-reunion-de-emergencia.mp3")
	audio.bus = bus_name
	add_child(audio)
	audio.play()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	var t = get_node_or_null("MeetingTimer")
	var l = get_node_or_null("Panel/CenterContainer/VBoxContainer/TimerLabel")
	if t and l:
		l.text = "Tiempo restante: " + str(int(t.time_left))
		
	if multiplayer.is_server() and not meeting_ended:
		if votes.size() >= alive_players.size() and alive_players.size() > 0:
			_on_timeout()

func _on_vote_btn(target_id: String):
	for btn in get_node("Panel/CenterContainer/VBoxContainer").get_children():
		if btn is Button:
			btn.disabled = true
	receive_vote.rpc(str(multiplayer.get_unique_id()), target_id)

func _on_timeout():
	if not multiplayer.is_server() or meeting_ended: return
	meeting_ended = true
	
	var t = get_node_or_null("MeetingTimer")
	if t: t.stop()
	
	var tally = {}
	for v in votes.values():
		if not tally.has(v): tally[v] = 0
		tally[v] += 1
		
	var max_votes = 0
	var ejected = ""
	var tie = false
	for k in tally.keys():
		if tally[k] > max_votes:
			max_votes = tally[k]
			ejected = k
			tie = false
		elif tally[k] == max_votes:
			tie = true
			
	var world = get_tree().current_scene
	if not tie and ejected != "skip" and ejected != "":
		world.eject_player.rpc(ejected)
	else:
		world.close_meeting.rpc()
