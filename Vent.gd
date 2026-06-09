extends StaticBody3D

@export var vent_id: String = "A"
@export var connected_vents: Array[String] = []

func _ready():
	add_to_group("vents")
