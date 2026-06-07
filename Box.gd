extends StaticBody3D

@export var is_fixed: bool = false
@export var max_progress: float = 25.0
var current_progress: float = 0.0

var active_hackers = 0

@onready var light = $OmniLight3D

func _ready():
	_update_visuals()

func _process(delta):
	if multiplayer.is_server():
		if active_hackers > 0 and not is_fixed:
			current_progress += active_hackers * delta
			update_progress.rpc(current_progress)
			if current_progress >= max_progress:
				is_fixed = true
				current_progress = max_progress
				active_hackers = 0
				update_status.rpc(true)
				var world = get_tree().root.get_node_or_null("World")
				if world and world.has_method("box_fixed"):
					world.box_fixed()

@rpc("any_peer", "call_local")
func start_hack(beast: bool):
	if not multiplayer.is_server(): return
	if beast:
		if is_fixed:
			is_fixed = false
			current_progress = 0.0
			update_status.rpc(false)
			update_progress.rpc(0.0)
			var world = get_tree().root.get_node_or_null("World")
			if world and world.has_method("box_broken"):
				world.box_broken()
	else:
		if not is_fixed:
			active_hackers += 1

@rpc("any_peer", "call_local")
func stop_hack(beast: bool):
	if not multiplayer.is_server(): return
	if not beast and not is_fixed:
		active_hackers = max(0, active_hackers - 1)

@rpc("any_peer", "call_local")
func fail_hack():
	if not multiplayer.is_server(): return
	current_progress = max(0.0, current_progress - 3.0)
	update_progress.rpc(current_progress)
	trigger_warning.rpc()

@rpc("any_peer", "call_local")
func boost_hack():
	if not multiplayer.is_server(): return
	current_progress = min(max_progress, current_progress + 1.0)
	update_progress.rpc(current_progress)

@rpc("call_local", "reliable")
func trigger_warning():
	var mesh = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 0, 0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.mesh = SphereMesh.new()
	mesh.material_override = mat
	add_child(mesh)
	var tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3(5, 5, 5), 0.5)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(mesh.queue_free)

@rpc("call_local", "unreliable")
func update_progress(prog: float):
	current_progress = prog
	if not is_fixed:
		var ratio = current_progress / max_progress
		light.light_color = Color(1.0, ratio, 0.0)

@rpc("call_local", "reliable")
func update_status(fixed: bool):
	is_fixed = fixed
	_update_visuals()

func _update_visuals():
	if is_fixed:
		light.light_color = Color(0, 1, 0)
	else:
		light.light_color = Color(1, 0, 0)
