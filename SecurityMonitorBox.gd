extends StaticBody3D

@export var connected_cameras: Array[String] = ["Cam1", "Cam2", "Cam3", "Cam4"]

func _ready():
	add_to_group("security_monitors")

@rpc("any_peer", "call_local")
func start_hack(_is_beast):
	pass
