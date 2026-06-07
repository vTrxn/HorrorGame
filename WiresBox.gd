extends StaticBody3D

@export var max_progress: float = 100.0
@export var current_progress: float = 0.0
var is_completed: bool = false

@rpc("any_peer", "call_local")
func start_hack(is_beast: bool):
	pass

@rpc("any_peer", "call_local")
func stop_hack(is_beast: bool):
	pass

@rpc("any_peer", "call_local")
func boost_hack(amount: float):
	if not is_completed:
		current_progress += amount
		if current_progress >= max_progress:
			current_progress = max_progress
			is_completed = true
