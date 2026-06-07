extends CharacterBody3D

@export var is_beast: bool = false
@export var base_speed: float = 5.0
@export var beast_boost_speed: float = 9.0
var speed: float = 5.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_sensitivity = 0.002
var power_up_active = false
var power_up_timer = 0.0

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
var is_carried = false
var carrier_id = ""
var carried_player_id = ""
var is_dead = false
var is_attacking = false
var attack_anim_time = 0.0
var attack_penalty_timer = 0.0
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

var generic_progress_bar: ProgressBar
var controls_label: Label
var interact_label: Label

var footstep_timer = 0.0
var footstep_player: AudioStreamPlayer3D

var xray_timer = 0.0
var xray_cooldown = 15.0
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

	if is_beast:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0, 0)
		torso.material_override = mat
		head.material_override = mat
		
		has_flashlight = true
		flashlight = SpotLight3D.new()
		flashlight.name = "Flashlight"
		flashlight.light_color = Color(1.0, 0.0, 0.0, 1)
		flashlight.light_energy = 5.0
		flashlight.spot_range = 15.0
		flashlight.spot_angle = 30.0
		flashlight.shadow_enabled = true
		add_child(flashlight)

	if is_local_player():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		head.visible = false
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
		
		if is_beast:
			speed = 5.5
		else:
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
		
		var hud = CanvasLayer.new()
		hud.layer = 2
		hud.add_child(controls_label)
		hud.add_child(interact_label)
		hud.add_child(generic_progress_bar)
		hud.add_child(center_container)
		add_child(hud)
		
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
		var stream = ResourceLoader.load("res://footstep.wav")
		if stream:
			footstep_player.stream = stream
		footstep_player.bus = bus_name
		add_child(footstep_player)
	else:
		camera.current = false

func _input(event):
	if not is_local_player() or is_dead or is_knocked_out: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if event.is_action_pressed("power_up") and is_beast and not power_up_active:
		activate_power_up.rpc()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel") and is_local_player():
		var world = get_tree().root.get_node_or_null("World")
		if world:
			var pm = world.get_node_or_null("PauseMenu")
			if pm:
				pm.toggle()

	if not is_multiplayer_authority():
		# Animación remota
		if is_knocked_out:
			rotation.z = lerp(rotation.z, PI/2, delta * 5)
		else:
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

	if is_dead: return

	if is_knocked_out:
		if is_carried:
			var world = get_tree().root.get_node_or_null("World")
			if world:
				var carrier = world.get_node_or_null("Players/" + carrier_id)
				if carrier:
					global_position = carrier.global_position + Vector3(0, 2.5, 0)
		else:
			if not is_on_floor():
				velocity.y -= gravity * delta
			velocity.x = 0
			velocity.z = 0
			move_and_slide()
			
			if is_multiplayer_authority() and not is_trapped:
				if knocked_out_timer > 0:
					knocked_out_timer -= delta
					if knocked_out_timer <= 0:
						get_freed.rpc()
			
		rotation.z = lerp(rotation.z, PI/2, delta * 5)
		return

	rotation.z = lerp(rotation.z, 0.0, delta * 5)

	# Penalización de movimiento por atacar
	var current_speed = speed
	if attack_penalty_timer > 0:
		attack_penalty_timer -= delta
		current_speed *= 0.3
		
	if is_beast:
		if power_up_active and power_up_timer > 0:
			power_up_timer -= delta
			current_speed = beast_boost_speed
			if generic_progress_bar:
				generic_progress_bar.visible = true
				generic_progress_bar.max_value = 4.0
				generic_progress_bar.value = power_up_timer
				generic_progress_bar.modulate = Color(1, 0, 0) # Rojo para boost
			if power_up_timer <= 0:
				power_up_active = false
				if generic_progress_bar: generic_progress_bar.visible = false
				if is_multiplayer_authority(): camera.fov = 75.0
		elif not power_up_active:
			if generic_progress_bar and not is_hacking: generic_progress_bar.visible = false

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_y = 0
	var input_x = 0
	if is_local_player():
		if Input.is_key_pressed(KEY_W): input_y -= 1
		if Input.is_key_pressed(KEY_S): input_y += 1
		if Input.is_key_pressed(KEY_A): input_x -= 1
		if Input.is_key_pressed(KEY_D): input_x += 1
	var input_dir = Vector2(input_x, input_y).normalized()
	
	if is_local_player() and Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	if has_flashlight and flashlight:
		var target_transform = camera.global_transform * Transform3D().translated(Vector3(0, -0.2, -0.5))
		flashlight.global_transform = flashlight.global_transform.interpolate_with(target_transform, delta * 15.0)
	
	var h_vel = Vector2(velocity.x, velocity.z)
	
	var interacting = false
	if is_local_player():
		interacting = Input.is_key_pressed(KEY_E)
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
	else:
		hand_l.position = hand_l.position.lerp(Vector3(-0.4, -0.4, -0.6), delta * 5)
		hand_r.position = hand_r.position.lerp(Vector3(0.4, -0.4, -0.6), delta * 5)

	if xray_timer > 0:
		xray_timer -= delta

	# Interacciones y ataques
	if is_beast and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_attacking and attack_penalty_timer <= 0:
		do_attack.rpc()
	
	if is_local_player():
		var controls_text = "WASD: Moverse\nMouse: Mirar"
		if is_beast: controls_text += "\nQ: Sprint\nClick Izquierdo: Atacar"
		var e_action = ""
		
		if is_hacking:
			e_action = "E: Detener Acción"
		elif raycast.is_colliding():
			var target = raycast.get_collider()
			if is_beast:
				if target.is_in_group("survivor") and target.is_knocked_out and carried_player_id == "":
					e_action = "E: Capturar Jugador"
					if interact_just_pressed and not is_hacking:
						pick_up_player.rpc(target.name)
						beast_handled_interact = true
				elif target.is_in_group("trash_can") and carried_player_id != "":
					e_action = "E: Atrapar en Basurero"
					if interact_just_pressed and not is_hacking:
						target.put_player_in.rpc_id(1, name, carried_player_id)
						beast_handled_interact = true
				elif target.has_method("start_hack"):
					var is_door_open = "is_open" in target and target.is_open
					if is_door_open:
						e_action = "E para cerrar"
						if interact_just_pressed and not is_hacking:
							target.start_hack.rpc_id(1, is_beast)
							beast_handled_interact = true
					else:
						e_action = "E para destruir"
						if interact_just_pressed and not is_hacking:
							target.start_hack.rpc_id(1, is_beast)
							beast_handled_interact = true
				else:
					if xray_timer <= 0: e_action = "E: Revelar (X-Ray)"
			else:
				if target.has_method("start_hack") and "FlashlightPickup" in target.name:
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
		else:
			if is_beast and xray_timer <= 0:
				e_action = "E: Revelar (X-Ray)"
				
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
			
	if is_beast and interact_just_pressed and not beast_handled_interact and xray_timer <= 0:
		activate_xray()
	if is_hacking and h_vel.length() > 0.1:
		if current_hack_target:
			current_hack_target.stop_hack.rpc_id(1, is_beast)
		current_hack_target = null
		is_hacking = false
		if sc_active:
			sc_active = false
			if skill_check_ui: skill_check_ui.visible = false
		if generic_progress_bar and not (is_beast and power_up_active):
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
				if generic_progress_bar and not (is_beast and power_up_active):
					generic_progress_bar.visible = false

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
	attack_penalty_timer = 1.0
	if is_multiplayer_authority():
		if raycast.is_colliding():
			var target = raycast.get_collider()
			if target and target.is_in_group("survivor") and not target.is_knocked_out:
				target.get_knocked_out.rpc()

@rpc("any_peer", "call_local")
func get_knocked_out():
	is_knocked_out = true
	if is_multiplayer_authority():
		knocked_out_timer = 6.0
		if sc_active:
			fail_skill_check()
		if is_hacking and current_hack_target:
			current_hack_target.stop_hack.rpc_id(1, is_beast)
			current_hack_target = null
			is_hacking = false

@rpc("any_peer", "call_local")
func pick_up_player(p_id: String):
	carried_player_id = p_id
	var world = get_tree().root.get_node_or_null("World")
	if world:
		var p = world.get_node_or_null("Players/" + p_id)
		if p:
			p.is_carried = true
			p.carrier_id = str(name)
			if p.has_node("CollisionShape3D"):
				p.get_node("CollisionShape3D").disabled = true

@rpc("any_peer", "call_local")
func drop_player():
	carried_player_id = ""

@rpc("any_peer", "call_local")
func get_trapped_in_can(can_path: NodePath):
	is_carried = false
	is_trapped = true
	carrier_id = ""
	visible = false
	if has_node("CollisionShape3D"):
		get_node("CollisionShape3D").disabled = true
	var can = get_node_or_null(can_path)
	if can:
		global_position = can.global_position + Vector3(0, 1.5, 0)

@rpc("any_peer", "call_local")
func get_freed():
	is_knocked_out = false
	is_carried = false
	is_trapped = false
	visible = true
	carrier_id = ""
	rotation.z = 0
	if has_node("CollisionShape3D"):
		get_node("CollisionShape3D").disabled = false

@rpc("any_peer", "call_local")
func die():
	is_dead = true
	visible = false
	if is_multiplayer_authority():
		print("You died in the trash can!")

@rpc("any_peer", "call_local")
func get_trapped():
	if not is_multiplayer_authority() or is_beast: return
	speed = 1.0
	await get_tree().create_timer(3.0).timeout
	speed = base_speed

func activate_xray():
	if not is_multiplayer_authority() or not is_beast: return
	xray_timer = xray_cooldown
	var survivors = get_tree().get_nodes_in_group("survivor")
	var world = get_tree().root.get_node_or_null("World")
	if not world: return
	
	for s in survivors:
		if s == self or s.is_dead: continue
		var mesh = MeshInstance3D.new()
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0)
		mat.emission_enabled = true
		mat.emission = Color(1, 0, 0)
		mat.emission_energy_multiplier = 5.0
		mat.no_depth_test = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.mesh = CapsuleMesh.new()
		mesh.material_override = mat
		mesh.scale = Vector3(1.1, 1.1, 1.1)
		
		world.add_child(mesh)
		mesh.global_position = s.global_position
		mesh.global_rotation = s.global_rotation
		
		var tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_callback(mesh.queue_free)

@rpc("any_peer", "call_local")
func activate_power_up():
	power_up_active = true
	power_up_timer = 4.0
	if is_multiplayer_authority():
		camera.fov = 90.0

@rpc("any_peer", "call_local")
func deactivate_power_up():
	power_up_active = false
	if is_multiplayer_authority():
		camera.fov = 75.0

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
