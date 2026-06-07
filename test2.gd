extends SceneTree
func _init():
	var box = preload("res://DownloadBox.tscn").instantiate()
	var player = preload("res://Player.gd").new()
	var target = box
	if target.has_method("start_hack"):
		print("START_HACK OK")
	if "task_id" in target:
		print("TASK_ID OK")
	if "is_completed" in target:
		print("IS_COMPLETED OK")
	else:
		print("NOT_COMPLETED OK")
	quit()
