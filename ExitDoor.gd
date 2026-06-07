extends StaticBody3D

var is_open = false

func open():
	is_open = true
	$CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
	
	var light = OmniLight3D.new()
	light.light_color = Color(0, 1, 0)
	light.light_energy = 5.0
	light.omni_range = 10.0
	light.position = Vector3(0, 2, 0)
	add_child(light)

func _on_win_area_body_entered(body):
	if is_open and body.has_method("get_trapped") and not body.is_beast:
		if body.is_multiplayer_authority():
			print("You Escaped and Won!")
		body.global_position = Vector3(0, 100, 0)
