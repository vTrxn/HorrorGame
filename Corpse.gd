extends RigidBody3D

@export var dead_player_name: String = ""
@export var corpse_color_index: int = 0

var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color(1, 0.5, 0), Color.PURPLE, Color.CYAN, Color.DEEP_PINK]

func _ready():
	add_to_group("corpses")
	var mat = StandardMaterial3D.new()
	mat.albedo_color = colors[corpse_color_index % colors.size()]
	$MeshInstance3D.set_surface_override_material(0, mat)

@rpc("any_peer", "call_local")
func start_hack(_is_beast):
	pass
