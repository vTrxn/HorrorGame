extends CharacterBody3D

@export var is_beast: bool = false
@export var base_speed: float = 6.75
var speed: float = 6.75
const JUMP_VELOCITY = 4.5

var stamina: float = 100.0
var max_stamina: float = 100.0
var stamina_bar: ColorRect
var is_crouching: bool = false
var is_jumping_slow: bool = false
var in_minigame: bool = false
var map_ui = null

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_sensitivity = 0.002


@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var body = $Body
@onready var head = $Body/Head
@onready var torso = $Body/Torso
@onready var hand_l = $Body/HandL
@onready var hand_r = $Body/HandR

var is_hacking = false
var current_hack_target = null
var hack_anim_time = 0.0
var walk_anim_time = 0.0

# Nuevas variables
var is_knocked_out = false
var is_dead = false
var is_ghost = false
var in_meeting_zone = null
var is_attacking = false
var attack_anim_time = 0.0

var knocked_out_timer = 0.0
var is_trapped = false

var has_flashlight = false
var flashlight: SpotLight3D = null

var skill_check_ui: CanvasLayer
var sc_target: ColorRect
var sc_cursor: ColorRect
var sc_active = false
var sc_progress = 0.0
var sc_target_pos = 0.0
var sc_target_width = 30.0
var sc_time_to_next = 3.0

var downloaded_task_id = -1

var generic_progress_bar: ProgressBar
var global_task_bar: ProgressBar
var hud_canvas: CanvasLayer
var controls_label: Label
var interact_label: Label

var footstep_timer = 0.0
var footstep_player: AudioStreamPlayer3D

var sabotage_cooldown = 0.0
var kill_cooldown = 0.0


var was_interacting = false

func _enter_tree():
	var auth_id = name.to_int()
	if auth_id == 0:
		auth_id = 1
	set_multiplayer_authority(auth_id)
	if not is_beast:
		add_to_group("survivor")

func is_local_player() -> bool:
	return str(name) == str(multiplayer.get_unique_id())

func create_face_part(pos: Vector3, size: Vector3, rot_z: float, black_mat: StandardMaterial3D):
	var mesh = BoxMesh.new()
	mesh.size = size
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = black_mat
	mi.position = pos
	mi.rotation.z = rot_z
	head.add_child(mi)

func _ready():
	# Crear carita feliz
	var black_mat = StandardMaterial3D.new()
	black_mat.albedo_color = Color(0, 0, 0)
	
	var z = -0.51 if is_beast else -0.41
	
	create_face_part(Vector3(-0.15, 0.1, z + 0.04), Vector3(0.08, 0.08, 0.05), 0.0, black_mat)
	create_face_part(Vector3(0.15, 0.1, z + 0.04), Vector3(0.08, 0.08, 0.05), 0.0, black_mat)
	create_face_part(Vector3(0, -0.1, z + 0.02), Vector3(0.15, 0.04, 0.05), 0.0, black_mat)
	create_face_part(Vector3(-0.09, -0.06, z + 0.03), Vector3(0.08, 0.04, 0.05), deg_to_rad(-30.0), black_mat)
	create_face_part(Vector3(0.09, -0.06, z + 0.03), Vector3(0.08, 0.04, 0.05), deg_to_rad(30.0), black_mat)
	if camera.has_node("Flashlight"):
		flashlight = camera.get_node("Flashlight")
		has_flashlight = true
		flashlight.light_energy = 8.0
		flashlight.spot_range = 25.0
		flashlight.spot_angle = 45.0

	if is_beast:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0, 0)
		torso.material_override = mat
		head.material_override = mat
		
		if not has_flashlight:
			has_flashlight = true
			flashlight = SpotLight3D.new()
			flashlight.name = "Flashlight"
			flashlight.light_color = Color(1.0, 1.0, 1.0, 1)
			flashlight.light_energy = 8.0
			flashlight.spot_range = 25.0
			flashlight.spot_angle = 45.0
			flashlight.shadow_enabled = true
			add_child(flashlight)
	
	if is_local_player():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		head.visible = false
		
		if is_beast:
			var canvas = CanvasLayer.new()
			canvas.layer = 100
			map_ui = Panel.new()
			map_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
			map_ui.self_modulate = Color(0, 0, 0, 0.5)
			map_ui.visible = false
			var sab_btn = Button.new()
			sab_btn.text = "Sabotear Luces"
			sab_btn.set_anchors_preset(Control.PRESET_CENTER)
			sab_btn.position = Vector2(-75, -20)
			sab_btn.size = Vector2(150, 40)
			sab_btn.button_down.connect(_on_sabotage_pressed)
			map_ui.add_child(sab_btn)
			canvas.add_child(map_ui)
			add_child(canvas)
		else:
			map_ui = load("res://MapOverlayUI.tscn").instantiate()
			add_child(map_ui)
		
		torso.visible = false
		hand_l.get_parent().remove_child(hand_l)
		camera.add_child(hand_l)
		hand_l.position = Vector3(-0.4, -0.4, -0.6)
		
		hand_r.get_parent().remove_child(hand_r)
		camera.add_child(hand_r)
		hand_r.position = Vector3(0.4, -0.4, -0.6)
		
		var env = Environment.new()
		
		# Misma vista para bestia y jugador
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.1, 0.12, 0.15)
		env.ambient_light_energy = 0.3
		env.fog_enabled = true
		env.fog_density = 0.03
		env.fog_light_color = Color(0.05, 0.05, 0.06)
		
		speed = base_speed
			
		skill_check_ui = CanvasLayer.new()
		skill_check_ui.visible = false
		var bg = ColorRect.new()
		bg.color = Color(0, 0, 0, 0.5)
		bg.set_anchors_preset(Control.PRESET_CENTER)
		bg.anchor_left = 0.5
		bg.anchor_top = 0.5
		bg.anchor_right = 0.5
		bg.anchor_bottom = 0.5
		bg.offset_left = -100
		bg.offset_right = 100
		bg.offset_top = 50
		bg.offset_bottom = 70
		
		sc_target = ColorRect.new()
		sc_target.color = Color(1, 1, 1, 0.5)
		sc_target.size = Vector2(sc_target_width, 20)
		
		sc_cursor = ColorRect.new()
		sc_cursor.color = Color(1, 0, 0, 1)
		sc_cursor.size = Vector2(5, 20)
		
		bg.add_child(sc_target)
		bg.add_child(sc_cursor)
		skill_check_ui.add_child(bg)
		add_child(skill_check_ui)
			
		generic_progress_bar = ProgressBar.new()
		generic_progress_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		generic_progress_bar.anchor_left = 0.5
		generic_progress_bar.anchor_top = 1.0
		generic_progress_bar.anchor_right = 0.5
		generic_progress_bar.anchor_bottom = 1.0
		generic_progress_bar.offset_left = -150
		generic_progress_bar.offset_top = -60
		generic_progress_bar.offset_right = 150
		generic_progress_bar.offset_bottom = -30
		generic_progress_bar.show_percentage = false
		generic_progress_bar.visible = false
		
		controls_label = Label.new()
		controls_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		controls_label.anchor_left = 0.0
		controls_label.anchor_right = 0.0
		controls_label.anchor_top = 1.0
		controls_label.anchor_bottom = 1.0
		controls_label.offset_left = 20
		controls_label.offset_top = -200
		controls_label.offset_right = 400
		controls_label.offset_bottom = -20
		controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		controls_label.add_theme_font_size_override("font_size", 22)
		controls_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		controls_label.add_theme_constant_override("outline_size", 4)
		controls_label.visible = true
		
		interact_label = Label.new()
		interact_label.set_anchors_preset(Control.PRESET_CENTER)
		interact_label.anchor_left = 0.5
		interact_label.anchor_right = 0.5
		interact_label.anchor_top = 0.5
		interact_label.anchor_bottom = 0.5
		interact_label.offset_left = -150
		interact_label.offset_top = 20
		interact_label.offset_right = 150
		interact_label.offset_bottom = 50
		interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interact_label.add_theme_font_size_override("font_size", 24)
		interact_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		interact_label.add_theme_constant_override("outline_size", 4)
		interact_label.visible = false
		
		var crosshair = ColorRect.new()
		crosshair.color = Color(1, 1, 1, 0.8)
		crosshair.custom_minimum_size = Vector2(4, 4)
		crosshair.set_anchors_preset(Control.PRESET_CENTER)
		var center_container = CenterContainer.new()
		center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		center_container.add_child(crosshair)
		
		hud_canvas = CanvasLayer.new()
		hud_canvas.layer = 2
		
		var vignette = ColorRect.new()
		vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float blur_amount = smoothstep(0.4, 0.8, dist) * 2.5;
	vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
	float darken = smoothstep(0.4, 1.0, dist);
	color.rgb = mix(color.rgb, vec3(0.0), darken * 0.7);
	COLOR = color;
}
"""
		mat.shader = shader
		vignette.material = mat
		hud_canvas.add_child(vignette)
		
		hud_canvas.add_child(controls_label)
		hud_canvas.add_child(interact_label)
		hud_canvas.add_child(generic_progress_bar)
		hud_canvas.add_child(center_container)
		
		var stamina_bg = ColorRect.new()
		stamina_bg.set_anchors_preset(Control.PRESET_CENTER)
		stamina_bg.custom_minimum_size = Vector2(60, 2)
		stamina_bg.size = Vector2(60, 2)
		stamina_bg.position = Vector2(-30, 15)
		stamina_bg.color = Color(0, 0, 0, 0.5)
		
		stamina_bar = ColorRect.new()
		stamina_bar.color = Color(1, 1, 1)
		stamina_bar.size = Vector2((stamina / max_stamina) * 60.0, 2)
		stamina_bg.add_child(stamina_bar)
		
		hud_canvas.add_child(stamina_bg)
		
		global_task_bar = ProgressBar.new()
		global_task_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
		global_task_bar.position = Vector2(20, 20)
		global_task_bar.size = Vector2(300, 30)
		global_task_bar.show_percentage = true
		global_task_bar.value = 0
		var sb_bg_t = StyleBoxFlat.new()
		sb_bg_t.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		global_task_bar.add_theme_stylebox_override("background", sb_bg_t)
		var sb_fill_t = StyleBoxFlat.new()
		sb_fill_t.bg_color = Color(0, 0.8, 0, 1)
		global_task_bar.add_theme_stylebox_override("fill", sb_fill_t)
		hud_canvas.add_child(global_task_bar)
		
		add_child(hud_canvas)
		
		camera.environment = env
		
		var bus_name = "ReverbBus"
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			bus_idx = AudioServer.get_bus_count()
			AudioServer.add_bus(bus_idx)
			AudioServer.set_bus_name(bus_idx, bus_name)
			var reverb = AudioEffectReverb.new()
			reverb.room_size = 0.8
			reverb.damping = 0.5
			reverb.spread = 1.0
			reverb.wet = 0.5
			AudioServer.add_bus_effect(bus_idx, reverb)
		
		footstep_player = AudioStreamPlayer3D.new()
		var stream = ResourceLoader.load("res://amongus_footstep.mp3")
		if stream:
			footstep_player.stream = stream
		footstep_player.bus = bus_name
		add_child(footstep_player)
	else:
		camera.current = false

func _input(event):
	if not is_local_player() or (is_dead and not is_ghost) or is_knocked_out or in_minigame: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M and not event.echo:
		if map_ui:
			if map_ui.has_method("toggle_map"):
				map_ui.toggle_map()
			else:
				map_ui.visible = not map_ui.visible
			
			if map_ui.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if not is_local_player() or (is_dead and not is_ghost) or is_knocked_out or in_minigame: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_beast and not is_attacking and kill_cooldown <= 0:
			if not (map_ui and map_ui.visible):
				do_attack.rpc()

func _on_sabotage_pressed():
	if sabotage_cooldown <= 0:
		sabotage_cooldown = 30.0
		if map_ui:
			map_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		var world = get_tree().root.get_node_or_null("World")
		if world and world.has_method("sabotage_lights"):
			world.sabotage_lights.rpc()
		elif get_tree().current_scene and get_tree().current_scene.has_method("sabotage_lights"):
			get_tree().current_scene.sabotage_lights.rpc()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel") and is_local_player() and not in_minigame:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var world = get_tree().root.get_node_or_null("World")
			if world:
				var pm = world.get_node_or_null("PauseMenu")
				if pm:
					pm.toggle()

	if not is_multiplayer_authority():
		# Animación remota
		if not is_knocked_out:
			rotation.z = lerp(rotation.z, 0.0, delta * 5)
		
		var h_vel = Vector2(velocity.x, velocity.z)
		if is_attacking:
			attack_anim_time += delta * 15.0
			hand_l.position.z = -0.6 - sin(attack_anim_time) * 0.5
			hand_r.position.z = -0.6 - sin(attack_anim_time) * 0.5
			if attack_anim_time > PI:
				is_attacking = false
		elif h_vel.length() > 0.1:
			walk_anim_time += delta * 10.0
			hand_l.position.y = 1.0 + sin(walk_anim_time) * 0.2
			hand_l.position.z = sin(walk_anim_time) * 0.4
			hand_r.position.y = 1.0 + sin(walk_anim_time + PI) * 0.2
			hand_r.position.z = sin(walk_anim_time + PI) * 0.4
		else:
			hand_l.position = hand_l.position.lerp(Vector3(-0.6, 1.0, 0), delta * 5)
			hand_r.position = hand_r.position.lerp(Vector3(0.6, 1.0, 0), delta * 5)
		return

	if hud_canvas:
		hud_canvas.visible = not in_minigame

	if is_dead and not is_ghost: return

	if is_knocked_out:
		if not is_on_floor():
			velocity.y -= gravity * delta
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	rotation.z = lerp(rotation.z, 0.0, delta * 5)

	var current_speed = speed
	if is_jumping_slow:
		current_speed *= 0.5
		
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Fallback si se caen del mapa
	if global_position.y < -50:
		var world = get_tree().root.get_node_or_null("World")
		if world and world.has_node("SpawnLocation"):
			global_position = world.get_node("SpawnLocation").global_position
		else:
			global_position = Vector3(0, 10, 0)
		velocity = Vector3.ZERO

	var input_y = 0
	var input_x = 0
	
	if is_local_player() and not in_minigame:
		if Input.is_key_pressed(KEY_W): input_y -= 1
		if Input.is_key_pressed(KEY_S): input_y += 1
		if Input.is_key_pressed(KEY_A): input_x -= 1
		if Input.is_key_pressed(KEY_D): input_x += 1
	var input_dir = Vector2(input_x, input_y).normalized()
	
	if is_on_floor():
		is_jumping_slow = false

	if is_local_player() and Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not is_crouching and not in_minigame:
		velocity.y = JUMP_VELOCITY
		is_jumping_slow = true
	
	is_crouching = false
	if is_local_player() and not in_minigame:
		if Input.is_key_pressed(KEY_CTRL):
			is_crouching = true
			current_speed *= 0.5
		else:
			if input_dir.length() > 0:
				if Input.is_key_pressed(KEY_SHIFT) and stamina > 0:
					current_speed *= 1.5
					stamina -= delta * 25.0
				else:
					stamina += delta * 7.5
			else:
				stamina += delta * 15.0
				
		stamina = clamp(stamina, 0, max_stamina)
		if stamina_bar:
			stamina_bar.size.x = (stamina / max_stamina) * 60.0
			
		var target_cam_y = 1.0 if is_crouching else 1.7
		camera.position.y = lerp(camera.position.y, target_cam_y, delta * 10.0)

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	if is_on_wall() and is_on_floor() and direction.length() > 0.1:
		var step_height = 2.0
		var test_trans = global_transform
		test_trans.origin.y += step_height
		if not test_move(test_trans, direction * 0.2):
			global_position.y += 20.0 * delta
	
	if is_local_player():
		var players = get_tree().root.get_node_or_null("World/Players")
		if players:
			for p in players.get_children():
				if p == self: continue
				if "is_ghost" in p and p.is_ghost:
					p.visible = self.is_ghost
				else:
					p.visible = true
	
	if has_flashlight and flashlight:
		var target_transform = camera.global_transform * Transform3D().translated(Vector3(0, -0.2, -0.5))
		flashlight.global_transform = flashlight.global_transform.interpolate_with(target_transform, delta * 15.0)
	
	var h_vel = Vector2(velocity.x, velocity.z)
	
	var interacting = false
	if is_local_player():
		interacting = Input.is_key_pressed(KEY_E)
	if is_ghost: interacting = false
	var interact_just_pressed = interacting and not was_interacting
	was_interacting = interacting
	var beast_handled_interact = false
	

	if is_hacking and current_hack_target:
		if generic_progress_bar and "max_progress" in current_hack_target and "current_progress" in current_hack_target:
			generic_progress_bar.visible = true
			generic_progress_bar.max_value = current_hack_target.max_progress
			generic_progress_bar.value = current_hack_target.current_progress
			generic_progress_bar.modulate = Color(0, 1, 0) # Verde para reparación
			
		if not is_beast and current_hack_target.has_method("boost_hack"):
			sc_time_to_next -= delta
			if sc_time_to_next <= 0 and not sc_active:
				sc_active = true
				sc_progress = 0.0
				sc_target_pos = randf_range(20.0, 160.0)
				sc_target.position.x = sc_target_pos
				skill_check_ui.visible = true
			
			if sc_active:
				sc_progress += delta * 180.0
				sc_cursor.position.x = sc_progress
				if sc_progress > 200.0:
					fail_skill_check()
				elif interact_just_pressed:
					if sc_progress >= sc_target_pos and sc_progress <= sc_target_pos + sc_target_width:
						pass_skill_check()
					else:
						fail_skill_check()
	elif not is_beast and sc_active:
		fail_skill_check()

	if is_attacking:
		attack_anim_time += delta * 15.0
		hand_l.position = Vector3(-0.4, -0.4, -0.6 - sin(attack_anim_time)*0.5)
		hand_r.position = Vector3(0.4, -0.4, -0.6 - sin(attack_anim_time)*0.5)
		if attack_anim_time > PI:
			is_attacking = false
	elif is_hacking:
		hack_anim_time += delta * 15.0
		hand_l.position = Vector3(-0.2 + sin(hack_anim_time)*0.1, -0.2, -0.6)
		hand_r.position = Vector3(0.2 + cos(hack_anim_time)*0.1, -0.2, -0.6)
		if not raycast.is_colliding() or raycast.get_collider() != current_hack_target:
			if current_hack_target:
				current_hack_target.stop_hack.rpc_id(1, is_beast)
			current_hack_target = null
			is_hacking = false
	elif h_vel.length() > 0.1:
		walk_anim_time += delta * 10.0
		hand_l.position.y = -0.4 + sin(walk_anim_time) * 0.1
		hand_r.position.y = -0.4 + sin(walk_anim_time + PI) * 0.1
		
		if h_vel.length() > 5.0 and is_on_floor():
			if footstep_player:
				if h_vel.length() > 10.0:
					footstep_player.pitch_scale = 1.0
				else:
					footstep_player.pitch_scale = 0.7
				
				if not footstep_player.playing:
					footstep_player.play()
		else:
			if footstep_player and footstep_player.playing:
				footstep_player.stop()
	else:
		hand_l.position = hand_l.position.lerp(Vector3(-0.4, -0.4, -0.6), delta * 5)
		hand_r.position = hand_r.position.lerp(Vector3(0.4, -0.4, -0.6), delta * 5)
		if footstep_player and footstep_player.playing:
			footstep_player.stop()

	
	if is_local_player():
		var controls_text = "WASD: Moverse\nMouse: Mirar"
		if is_beast: controls_text += "\nQ: Sprint\nClick Izquierdo: Atacar"
		var e_action = ""
		
		if in_minigame:
			pass
		elif is_hacking:
			e_action = "E: Detener Acción"
		elif raycast.is_colliding():
			var target = raycast.get_collider()
			if is_beast:
				if target.is_in_group("fix_lights"):
					e_action = "E para arreglar luces"
					if interact_just_pressed and not is_hacking:
						target.start_hack.rpc_id(1, is_beast)
						beast_handled_interact = true
			else:
				if target.is_in_group("download_tasks") or ("Download" in target.name):
					var tid = target.get("task_id") if target.get("task_id") != null else 0
					if downloaded_task_id == tid:
						e_action = "Datos ya descargados"
					else:
						e_action = "E: Descargar Datos"
						if interact_just_pressed and not is_hacking and not in_minigame:
							start_data_minigame(target, false)
				elif target.is_in_group("upload_tasks") or ("Upload" in target.name):
					var tid = target.get("task_id") if target.get("task_id") != null else 0
					var comp = target.get("is_completed") if target.get("is_completed") != null else false
					if downloaded_task_id != tid:
						e_action = "Requiere datos de terminal " + str(tid)
					elif comp:
						e_action = "Subida ya completada"
					else:
						e_action = "E: Subir Datos"
						if interact_just_pressed and not is_hacking and not in_minigame:
							start_data_minigame(target, true)
				elif "WiresBox" in target.name:
					if "is_completed" in target and target.is_completed:
						e_action = "Completado"
					else:
						e_action = "E: Conectar Cables"
						if interact_just_pressed and not is_hacking and not in_minigame:
							start_wires_minigame(target)
				elif target.has_method("start_hack") and "FixLightsBox" in target.name:
					e_action = "E: Arreglar Luces"
					if interact_just_pressed and not is_hacking and not in_minigame:
						start_lights_minigame(target)
				elif target.has_method("start_hack") and "FlashlightPickup" in target.name:
					e_action = "E: Recoger Linterna"
					if interact_just_pressed and not is_hacking:
						target.start_hack.rpc_id(1, is_beast)
				elif target.has_method("start_hack"):
					var is_door_open = "is_open" in target and target.is_open
					if is_door_open:
						e_action = "E para cerrar"
						if interact_just_pressed and not is_hacking:
							target.start_hack.rpc_id(1, is_beast)
					else:
						var can_hack = true
						if "is_fixed" in target and target.is_fixed: can_hack = false
						if can_hack:
							if "is_open" in target:
								e_action = "E para abrir"
							else:
								e_action = "E para hackear"
							if interact_just_pressed and not is_hacking:
								current_hack_target = target
								is_hacking = true
								target.start_hack.rpc_id(1, is_beast)
				elif target.is_in_group("trash_can"):
					e_action = "E: Rescatar"
					if interact_just_pressed and not is_hacking:
						target.free_player.rpc_id(1)
		if e_action == "" and in_meeting_zone != null and not is_ghost:
			e_action = "Presiona E para llamar a reunión"
			if interact_just_pressed:
				get_tree().current_scene.call_meeting.rpc_id(1, str(multiplayer.get_unique_id()))
				beast_handled_interact = true
			
		if is_beast and sabotage_cooldown > 0:
			e_action += "\nLuces (F): " + str(int(sabotage_cooldown)) + "s"
			
		if e_action != "":
			controls_text += "\n" + e_action
			if interact_label:
				interact_label.text = e_action
				interact_label.visible = true
		else:
			if interact_label:
				interact_label.visible = false
		
		if controls_label:
			controls_label.text = controls_text
			

	if is_beast and sabotage_cooldown > 0:
		sabotage_cooldown -= delta
		
	if is_hacking and h_vel.length() > 0.1:
		if current_hack_target:
			current_hack_target.stop_hack.rpc_id(1, is_beast)
		current_hack_target = null
		is_hacking = false
		if sc_active:
			sc_active = false
			if skill_check_ui: skill_check_ui.visible = false
		if generic_progress_bar:
			generic_progress_bar.visible = false
			
	if is_hacking and current_hack_target:
		if "current_progress" in current_hack_target and "max_progress" in current_hack_target:
			if current_hack_target.current_progress >= current_hack_target.max_progress:
				if current_hack_target:
					current_hack_target.stop_hack.rpc_id(1, is_beast)
				current_hack_target = null
				is_hacking = false
				if sc_active:
					sc_active = false
					if skill_check_ui: skill_check_ui.visible = false
				if generic_progress_bar:
					generic_progress_bar.visible = false

func set_lights_sabotaged(is_sabotaged: bool):
	if is_local_player():
		if is_sabotaged:
			if has_flashlight and flashlight:
				flashlight.light_energy = 5.0
				flashlight.spot_range = 20.0
				flashlight.spot_angle = 45.0
			camera.environment = Environment.new()
			camera.environment.fog_enabled = true
			camera.environment.fog_light_color = Color(0, 0, 0)
			camera.environment.fog_density = 0.25 # Menos denso para poder ver hitboxes
		else:
			if has_flashlight and flashlight:
				flashlight.light_energy = 8.0
				flashlight.spot_range = 25.0
				flashlight.spot_angle = 45.0
			camera.environment = null

func pass_skill_check():
	sc_active = false
	if skill_check_ui: skill_check_ui.visible = false
	sc_time_to_next = randf_range(2.0, 6.0)
	if current_hack_target and current_hack_target.has_method("boost_hack"):
		current_hack_target.boost_hack.rpc_id(1)

func fail_skill_check():
	sc_active = false
	if skill_check_ui: skill_check_ui.visible = false
	sc_time_to_next = randf_range(2.0, 6.0)
	if current_hack_target and current_hack_target.has_method("fail_hack"):
		current_hack_target.fail_hack.rpc_id(1)

@rpc("any_peer", "call_local")
func do_attack():
	is_attacking = true
	attack_anim_time = 0.0
	if is_multiplayer_authority():
		if raycast.is_colliding():
			var target = raycast.get_collider()
			if target and target.is_in_group("survivor") and not target.is_knocked_out:
				target.get_knocked_out.rpc()
				kill_cooldown = 30.0

@rpc("any_peer", "call_local")
func get_knocked_out():
	is_knocked_out = true
	rotation_degrees.z = 90
	var kill_audio = AudioStreamPlayer3D.new()
	var stream = load("res://kill_sound.mp3")
	if stream:
		kill_audio.stream = stream
		kill_audio.bus = "Master"
		add_child(kill_audio)
		kill_audio.play()
	if is_multiplayer_authority():
		if sc_active:
			fail_skill_check()
		if is_hacking and current_hack_target:
			current_hack_target.stop_hack.rpc_id(1, is_beast)
			current_hack_target = null
			is_hacking = false

			is_hacking = false

@rpc("any_peer", "call_local")
func die():
	make_ghost()
	if is_multiplayer_authority():
		print("You died!")

@rpc("any_peer", "call_local")
func get_trapped():
	if not is_multiplayer_authority() or is_beast: return
	speed = 1.0
	await get_tree().create_timer(3.0).timeout
	speed = base_speed

@rpc("any_peer", "call_local")
func grab_flashlight():
	if has_flashlight: return
	has_flashlight = true
	flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.light_color = Color(1.0, 1.0, 1.0, 1)
	flashlight.light_energy = 3.0
	flashlight.spot_range = 15.0
	flashlight.spot_angle = 30.0
	flashlight.shadow_enabled = true
	flashlight.global_transform = camera.global_transform
	add_child(flashlight)

func start_wires_minigame(target_box):
	in_minigame = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ui = load("res://WiresMinigameUI.tscn").instantiate()
	ui.connect("minigame_completed", Callable(self, "_on_wires_completed").bind(target_box))
	ui.connect("minigame_closed", Callable(self, "_on_wires_closed"))
	get_tree().root.add_child(ui)

func _on_wires_completed(target_box):
	in_minigame = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if target_box:
		target_box.boost_hack.rpc_id(1, 100.0)

func _on_wires_closed():
	in_minigame = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func start_lights_minigame(target_box):
	in_minigame = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ui = load("res://LightsMinigameUI.tscn").instantiate()
	ui.connect("minigame_completed", Callable(self, "_on_lights_completed").bind(target_box))
	ui.connect("minigame_closed", Callable(self, "_on_lights_closed"))
	get_tree().root.add_child(ui)

func _on_lights_completed(target_box):
	in_minigame = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	target_box.start_hack.rpc_id(1, is_beast)

func _on_lights_closed():
	in_minigame = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func start_data_minigame(target_box, is_upload):
	in_minigame = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ui = load("res://DataMinigameUI.tscn").instantiate()
	ui.set_mode(is_upload)
	ui.connect("minigame_completed", Callable(self, "_on_data_completed").bind(target_box, is_upload))
	ui.connect("minigame_closed", Callable(self, "_on_data_closed"))
	get_tree().root.add_child(ui)

func _on_data_completed(target_box, is_upload):
	in_minigame = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_upload:
		downloaded_task_id = -1
		if target_box and target_box.has_method("start_hack"):
			target_box.start_hack.rpc_id(1, is_beast)
	else:
		if target_box:
			downloaded_task_id = target_box.get("task_id") if target_box.get("task_id") != null else 0

func _on_data_closed():
	in_minigame = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_task_ui(fixed: int, total: int):
	if global_task_bar:
		if total > 0:
			global_task_bar.value = (float(fixed) / total) * 100.0
		else:
			global_task_bar.value = 0.0

@rpc("call_local", "reliable")
func make_ghost():
	is_ghost = true
	is_dead = true
	collision_layer = 0
	collision_mask = 1
	if is_local_player():
		print("I am now a ghost!")
		if hand_l and "transparency" in hand_l:
			hand_l.transparency = 0.7
		if hand_r and "transparency" in hand_r:
			hand_r.transparency = 0.7
