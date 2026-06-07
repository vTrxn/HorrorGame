extends StaticBody3D

@export var task_id: int = 0
var is_completed = false

func _ready():
	add_to_group("upload_tasks")

@rpc("any_peer", "call_local")
func start_hack(_is_beast):
	if _is_beast: return
	if not is_completed:
		is_completed = true
		if get_tree().current_scene.has_method("box_fixed"):
			get_tree().current_scene.box_fixed()
