extends SceneTree
func _init():
	var box = preload("res://DownloadBox.tscn").instantiate()
	if "task_id" in box:
		print("YES_TASK_ID")
	else:
		print("NO_TASK_ID")
	if box.has_method("start_hack"):
		print("YES_START_HACK")
	else:
		print("NO_START_HACK")
	quit()
