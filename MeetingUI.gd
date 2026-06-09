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
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
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
	var reason = "button"
	if has_meta("reason"):
		reason = get_meta("reason")
		
	if reason == "report":
		lbl.text = "¡CUERPO REPORTADO!\nVota por un jugador:"
	else:
		lbl.text = "¡REUNIÓN DE EMERGENCIA!\nVota por un jugador:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	vbox.add_child(lbl)
	
	var dead_list = []
	
	var players_node = get_tree().root.get_node_or_null("World/Players")
	if players_node:
		for p in players_node.get_children():
			if "is_ghost" in p and not p.is_ghost:
				alive_players.append(p.name)
				var btn = Button.new()
				btn.text = "Votar por: " + str(p.name)
				btn.add_theme_font_size_override("font_size", 24)
				
				var btn_style = StyleBoxFlat.new()
				btn_style.bg_color = Color(0.15, 0.15, 0.2)
				btn_style.set_corner_radius_all(8)
				btn_style.set_border_width_all(1)
				btn_style.border_color = Color(0.4, 0.4, 0.5)
				btn_style.content_margin_left = 15
				btn_style.content_margin_right = 15
				btn_style.content_margin_top = 10
				btn_style.content_margin_bottom = 10
				btn.add_theme_stylebox_override("normal", btn_style)
				
				var h_style = btn_style.duplicate()
				h_style.bg_color = Color(0.2, 0.4, 0.5)
				btn.add_theme_stylebox_override("hover", h_style)
				
				btn.pressed.connect(self._on_vote_btn.bind(str(p.name)))
				vbox.add_child(btn)
			elif "is_ghost" in p and p.is_ghost:
				dead_list.append(str(p.name))
				
	if dead_list.size() > 0:
		var dead_lbl = Label.new()
		dead_lbl.text = "Muertos: " + ", ".join(dead_list)
		dead_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dead_lbl.add_theme_font_size_override("font_size", 20)
		dead_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(dead_lbl)
		vbox.move_child(dead_lbl, 1)
			
	var skip_btn = Button.new()
	skip_btn.text = "Saltar voto"
	skip_btn.add_theme_font_size_override("font_size", 24)
	
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(0.15, 0.15, 0.15)
	skip_style.set_corner_radius_all(8)
	skip_style.set_border_width_all(1)
	skip_style.border_color = Color(0.3, 0.3, 0.3)
	skip_style.content_margin_left = 15
	skip_style.content_margin_right = 15
	skip_style.content_margin_top = 10
	skip_style.content_margin_bottom = 10
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	
	var skip_h_style = skip_style.duplicate()
	skip_h_style.bg_color = Color(0.3, 0.3, 0.3)
	skip_btn.add_theme_stylebox_override("hover", skip_h_style)
	
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
