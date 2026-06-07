extends StaticBody3D

var current_progress = 0.0
var max_progress = 1.0

func _ready():
	set_visual(false)
	add_to_group("fix_lights")

func set_visual(is_visible: bool):
	if has_node("MeshInstance3D"):
		$"MeshInstance3D".visible = is_visible

@rpc("any_peer", "call_local")
func start_hack(_is_beast):
	get_tree().current_scene.fix_lights.rpc()

@rpc("any_peer", "call_local")
func stop_hack(is_beast):
	pass
