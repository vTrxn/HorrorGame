extends SceneTree

func _init():
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	var err = gltf.append_from_file("res://sci-fi_male_character.glb", state)
	if err == OK:
		var root = gltf.generate_scene(state)
		if root:
			print("=== NODES ===")
			_print_tree(root, "")
			
			var ap = _find_animation_player(root)
			if ap:
				print("=== ANIMATIONS ===")
				var list = ap.get_animation_list()
				for a in list:
					print("- " + a)
	else:
		print("Failed to load GLB")
	quit()

func _print_tree(node: Node, indent: String):
	print(indent + node.name + " (" + node.get_class() + ")")
	if node is Skeleton3D:
		print(indent + "  [Skeleton Bones]:")
		for i in range(node.get_bone_count()):
			print(indent + "   - " + node.get_bone_name(i))
	for c in node.get_children():
		_print_tree(c, indent + "  ")

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var ap = _find_animation_player(c)
		if ap: return ap
	return null
