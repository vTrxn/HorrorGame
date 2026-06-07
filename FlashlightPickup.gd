extends Area3D

@rpc("any_peer", "call_local")
func start_hack(is_beast):
	if is_beast: return
	var player = get_tree().get_nodes_in_group("survivor").filter(func(p): return p.name == str(multiplayer.get_remote_sender_id()))
	if player.size() > 0:
		player[0].grab_flashlight.rpc_id(player[0].get_multiplayer_authority())
	queue_free()
