extends StaticBody3D

@export var task_id: int = 0

func _ready():
	add_to_group("download_tasks")

@rpc("any_peer", "call_local")
func start_hack(_is_beast):
	pass
