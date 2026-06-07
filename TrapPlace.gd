extends StaticBody3D

var is_active = false
@onready var mesh = $MeshInstance3D

func _ready():
	_update_visuals()

@rpc("any_peer", "call_local")
func interact(beast: bool):
	if not multiplayer.is_server(): return
	if beast and not is_active:
		is_active = true
		update_status.rpc(true)

@rpc("call_local", "reliable")
func update_status(active: bool):
	is_active = active
	_update_visuals()

func _update_visuals():
	var mat = StandardMaterial3D.new()
	if is_active:
		mat.albedo_color = Color(0.5, 0, 0)
	else:
		mat.albedo_color = Color(0.3, 0.3, 0.3)
	mesh.material_override = mat

func _on_body_entered(body):
	if is_active and body.has_method("get_trapped") and not body.is_beast:
		if multiplayer.is_server():
			body.get_trapped.rpc()
			is_active = false
			update_status.rpc(false)
