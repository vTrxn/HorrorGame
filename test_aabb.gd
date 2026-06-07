extends SceneTree

func _init():
	var map = load("res://Map.glb").instantiate()
	var aabb = get_aabb(map)
	print("AABB: position=", aabb.position, " size=", aabb.size)
	quit()

func get_aabb(node):
	var aabb = AABB()
	var first = true
	var meshes = []
	_find_meshes(node, meshes)
	for m in meshes:
		var m_aabb = m.get_aabb()
		var g_trans = m.global_transform
		var m_min = g_trans * m_aabb.position
		var m_max = g_trans * (m_aabb.position + m_aabb.size)
		var box = AABB(m_min, m_max - m_min)
		if first:
			aabb = box
			first = false
		else:
			aabb = aabb.merge(box)
	return aabb

func _find_meshes(node, arr):
	if node is MeshInstance3D:
		arr.append(node)
	for c in node.get_children():
		_find_meshes(c, arr)
