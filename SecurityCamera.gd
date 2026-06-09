extends Node3D

@export var camera_id: String = "Cam1"
@onready var viewport = $SubViewport
@onready var cam = $SubViewport/Camera3D

func _ready():
	add_to_group("security_cameras")
	call_deferred("setup_world")

func setup_world():
	# Comparte el mundo 3D principal para que la cámara pueda ver el nivel real
	viewport.world_3d = get_viewport().world_3d

func _process(_delta):
	# Hacer que la cámara interna siga exactamente la posición y rotación de este nodo
	cam.global_transform = global_transform

func get_camera_texture():
	return viewport.get_texture()

@rpc("any_peer", "call_local")
func set_active(active: bool):
	if has_node("SpotLight3D"):
		$SpotLight3D.visible = active
