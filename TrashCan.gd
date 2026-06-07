extends StaticBody3D

var trapped_player_id = ""
var trap_timer = 0.0
const MAX_TRAP_TIME = 120.0
var highlight_mesh: MeshInstance3D

func _ready():
	highlight_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 2.0, 1.5)
	highlight_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	highlight_mesh.material_override = mat
	highlight_mesh.visible = false
	add_child(highlight_mesh)

func _enter_tree():
	add_to_group("trash_can")

func _process(delta):
	if multiplayer.is_server():
		if trapped_player_id != "":
			trap_timer -= delta
			if trap_timer <= 0:
				kill_trapped_player.rpc()

@rpc("call_local")
func show_highlight():
	if highlight_mesh: highlight_mesh.visible = true

@rpc("call_local")
func hide_highlight():
	if highlight_mesh: highlight_mesh.visible = false

@rpc("any_peer", "call_local")
func put_player_in(beast_id: String, p_id: String):
	if not multiplayer.is_server(): return
	if trapped_player_id != "": return # already full
	var world = get_tree().root.get_node_or_null("World")
	if not world: return
	
	var beast = world.get_node_or_null("Players/" + beast_id)
	var player = world.get_node_or_null("Players/" + p_id)
	
	if beast and player:
		beast.drop_player.rpc()
		trapped_player_id = p_id
		trap_timer = MAX_TRAP_TIME
		player.get_trapped_in_can.rpc(get_path())
		show_highlight.rpc()

@rpc("any_peer", "call_local")
func free_player():
	if not multiplayer.is_server(): return
	if trapped_player_id != "":
		var world = get_tree().root.get_node_or_null("World")
		if world:
			var player = world.get_node_or_null("Players/" + trapped_player_id)
			if player:
				player.get_freed.rpc()
		trapped_player_id = ""
		hide_highlight.rpc()

@rpc("call_local")
func kill_trapped_player():
	if trapped_player_id != "":
		var world = get_tree().root.get_node_or_null("World")
		if world:
			var player = world.get_node_or_null("Players/" + trapped_player_id)
			if player:
				player.die.rpc()
		trapped_player_id = ""
		hide_highlight.rpc()
