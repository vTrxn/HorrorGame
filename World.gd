extends Node3D

var survivor_scene = preload("res://Survivor.tscn")
var beast_scene = preload("res://Beast.tscn")
var total_boxes = 0
var fixed_boxes = 0

func _ready():
	for node in $Boxes.get_children():
		total_boxes += 1
	print("Total boxes to fix: ", total_boxes)

func spawn_player(peer_id: int, role: int):
	var player
	if role == 0:
		player = survivor_scene.instantiate()
	else:
		player = beast_scene.instantiate()
	player.name = str(peer_id)
	$Players.add_child(player)
	player.global_position = Vector3(randf_range(-5, 5), 5, randf_range(-5, 5))

func remove_player(peer_id: int):
	var node = $Players.get_node_or_null(str(peer_id))
	if node:
		node.queue_free()

func box_fixed():
	fixed_boxes += 1
	print("Box fixed! ", fixed_boxes, "/", total_boxes)
	if fixed_boxes >= total_boxes:
		open_doors.rpc()

func box_broken():
	fixed_boxes -= 1
	print("Box broken! ", fixed_boxes, "/", total_boxes)

@rpc("call_local", "reliable")
func open_doors():
	print("Doors opened!")
	var exit_door = $ExitDoor
	if exit_door:
		exit_door.open()
