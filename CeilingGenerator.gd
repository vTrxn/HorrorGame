extends Node3D

@export var map_size: Vector2 = Vector2(300, 300)

# ¡AQUÍ PUEDES EDITAR LA ALTURA DEL TECHO!
# Cambia este número si el techo está muy alto o muy bajo:
@export var ceiling_height: float = 5.5

func _ready():
	_generate_ceiling()

func _generate_ceiling():
	# Techo base principal (Plano)
	var base_ceiling = CSGBox3D.new()
	base_ceiling.size = Vector3(map_size.x, 0.5, map_size.y)
	base_ceiling.position = Vector3(0, ceiling_height + 0.25, 0)
	base_ceiling.use_collision = true
	
	# Material del techo
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18) # Gris azulado oscuro (estilo nave)
	base_mat.metallic = 0.4
	base_mat.roughness = 0.6
	
	# Textura procedural leve para que no sea un color 100% plano
	var noise = FastNoiseLite.new()
	noise.frequency = 0.03
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	base_mat.albedo_texture = noise_tex
	
	base_ceiling.material_override = base_mat
	add_child(base_ceiling)
