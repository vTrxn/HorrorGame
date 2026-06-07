extends Node3D

var survivor_scene = preload("res://Survivor.tscn")
var beast_scene = preload("res://Beast.tscn")
var total_boxes = 0
var fixed_boxes = 0

@export var ceiling_height: float = 12.0

func _ready():
	var ceiling = CSGBox3D.new()
	ceiling.name = "Ceiling"
	ceiling.use_collision = true
	ceiling.size = Vector3(500, 1.0, 500)
	ceiling.position = Vector3(-135, ceiling_height, 109)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.15)
	mat.metallic = 0.6
	mat.roughness = 0.5
	ceiling.material = mat
	if has_node("Environment"):
		$Environment.add_child(ceiling)

	var map = $Environment.get_node_or_null("Map")
	if map:
		_create_collision(map)
		
	var test_dummy = $Players.get_node_or_null("TestDummy")
	if test_dummy:
		test_dummy.global_position = $SpawnLocation.global_position
		
	for node in $Boxes.get_children():
		total_boxes += 1
	print("Total boxes to fix: ", total_boxes)
	
	var cg = Node3D.new()
	cg.set_script(load("res://CeilingGenerator.gd"))
	add_child(cg)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.03, 0.05)
	env.fog_density = 0.12 # Niebla espesa para limitar la vista
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.05
	env.volumetric_fog_albedo = Color(0.1, 0.1, 0.1)
	env_node.environment = env
	add_child(env_node)





func _create_collision(node: Node):
	if node is MeshInstance3D:
		node.create_trimesh_collision()
	for child in node.get_children():
		_create_collision(child)


func spawn_player(peer_id: int, role: int):
	var player
	if role == 0:
		player = survivor_scene.instantiate()
	else:
		player = beast_scene.instantiate()
	player.name = str(peer_id)
	$Players.add_child(player)
	var spawn_pos = $SpawnLocation.global_position
	player.global_position = Vector3(spawn_pos.x + randf_range(-2, 2), spawn_pos.y, spawn_pos.z + randf_range(-2, 2))

func remove_player(peer_id: int):
	var node = $Players.get_node_or_null(str(peer_id))
	if node:
		node.queue_free()

func box_fixed():
	fixed_boxes += 1
	print("Box fixed! ", fixed_boxes, "/", total_boxes)
	update_task_progress.rpc(fixed_boxes, total_boxes)
	if fixed_boxes >= total_boxes:
		open_doors.rpc()

func box_broken():
	fixed_boxes -= 1
	print("Box broken! ", fixed_boxes, "/", total_boxes)
	update_task_progress.rpc(fixed_boxes, total_boxes)

@rpc("call_local", "reliable")
func update_task_progress(fixed: int, total: int):
	fixed_boxes = fixed
	total_boxes = total
	for p in $Players.get_children():
		if p.has_method("is_local_player") and p.is_local_player() and p.has_method("update_task_ui"):
			p.update_task_ui(fixed, total)

@rpc("call_local", "reliable")
func open_doors():
	print("Doors opened!")
	var exit_door = $ExitDoor
	if exit_door:
		exit_door.open()

var meeting_ui_instance = null

@rpc("any_peer", "call_local", "reliable")
func call_meeting(caller_id: String):
	if not multiplayer.is_server(): return
	open_meeting.rpc()

@rpc("call_local", "reliable")
func open_meeting():
	var spawn_pos = $SpawnLocation.global_position
	for p in $Players.get_children():
		if p.has_method("is_local_player") and p.is_local_player():
			p.in_minigame = true
		if not ("is_ghost" in p and p.is_ghost):
			p.global_position = Vector3(spawn_pos.x + randf_range(-2, 2), spawn_pos.y + 1, spawn_pos.z + randf_range(-2, 2))
	
	if meeting_ui_instance == null:
		var MeetingUI = load("res://MeetingUI.gd")
		meeting_ui_instance = MeetingUI.new()
		add_child(meeting_ui_instance)

@rpc("any_peer", "call_local", "reliable")
func eject_player(player_id: String):
	print("Player ejected: ", player_id)
	var p = $Players.get_node_or_null(player_id)
	if p and p.has_method("make_ghost"):
		p.make_ghost()
	if multiplayer.is_server():
		close_meeting.rpc()

@rpc("any_peer", "call_local", "reliable")
func close_meeting():
	if meeting_ui_instance:
		meeting_ui_instance.queue_free()
		meeting_ui_instance = null
	for p in $Players.get_children():
		if p.has_method("is_local_player") and p.is_local_player():
			p.in_minigame = false

@rpc("any_peer", "call_local", "reliable")
func sabotage_lights():
	for box in get_tree().get_nodes_in_group("fix_lights"):
		if box.has_method("set_visual"):
			box.set_visual(true)
	for p in $Players.get_children():
		if p.has_method("set_lights_sabotaged"):
			p.set_lights_sabotaged(true)

@rpc("any_peer", "call_local", "reliable")
func fix_lights():
	for box in get_tree().get_nodes_in_group("fix_lights"):
		if box.has_method("set_visual"):
			box.set_visual(false)
	for p in $Players.get_children():
		if p.has_method("set_lights_sabotaged"):
			p.set_lights_sabotaged(false)
