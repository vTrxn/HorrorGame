extends SceneTree
func _init():
	var test = load("res://DownloadBox.gd").new()
	if "task_id" in test:
		print("YES")
	else:
		print("NO")
	quit()
