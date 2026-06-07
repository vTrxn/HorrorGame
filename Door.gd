extends StaticBody3D

var current_progress = 0.0
var max_progress = 2.0
var is_open = false
var hackers = 0

@onready var audio = $AudioStreamPlayer3D
@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

func _ready():
	var stream = ResourceLoader.load("res://door_open.wav")
	if stream:
		audio.stream = stream

@rpc("any_peer", "call_local")
func start_hack(is_beast):
	if is_open:
		if multiplayer.is_server():
			close_door.rpc()
		return
	hackers += 1

@rpc("any_peer", "call_local")
func stop_hack(is_beast):
	if is_open: return
	hackers = max(0, hackers - 1)
	if hackers == 0:
		current_progress = 0.0

func _process(delta):
	if multiplayer.is_server():
		if hackers > 0 and not is_open:
			current_progress += delta * hackers
			update_progress.rpc(current_progress)
			if current_progress >= max_progress:
				open_door.rpc()

@rpc("call_local", "unreliable")
func update_progress(prog: float):
	current_progress = prog

@rpc("call_local", "reliable")
func open_door():
	if is_open: return
	is_open = true
	current_progress = 0.0
	hackers = 0
	collision.disabled = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.2, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	if audio.stream:
		audio.play()

@rpc("call_local", "reliable")
func close_door():
	if not is_open: return
	is_open = false
	current_progress = 0.0
	hackers = 0
	collision.disabled = false
	mesh.material_override = null
	if audio.stream:
		audio.play()
