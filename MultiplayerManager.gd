extends Node

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
var enet_peer = ENetMultiplayerPeer.new()
var local_role = 0
var local_color_index = 0

func _ready():
	_setup_input("move_forward", KEY_W)
	_setup_input("move_backward", KEY_S)
	_setup_input("move_left", KEY_A)
	_setup_input("move_right", KEY_D)
	_setup_input("interact", KEY_E)
	_setup_input("power_up", KEY_Q)
	_setup_input("jump", KEY_SPACE)
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _setup_input(action_name, keycode):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev = InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)

func host_game(role: int, color_index: int = 0):
	local_role = role
	local_color_index = color_index
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	load_world()
	await get_tree().create_timer(0.2).timeout
	var world = get_tree().root.get_node_or_null("World")
	if world:
		world.spawn_player(1, local_role, local_color_index)

func join_game(role: int, color_index: int = 0, ip: String = DEFAULT_SERVER_IP):
	local_role = role
	local_color_index = color_index
	enet_peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = enet_peer
	load_world()

func load_world():
	var world_scene = load("res://World.tscn").instantiate()
	get_tree().root.add_child(world_scene)
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	get_tree().current_scene = world_scene

func _on_connected_to_server():
	rpc_id(1, "request_spawn", local_role, local_color_index)

@rpc("any_peer", "call_local")
func request_spawn(role: int, color_idx: int):
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		var world = get_tree().root.get_node_or_null("World")
		if world:
			world.spawn_player(peer_id, role, color_idx)

func _on_peer_disconnected(peer_id):
	if multiplayer.is_server():
		var world = get_tree().root.get_node_or_null("World")
		if world:
			world.remove_player(peer_id)
