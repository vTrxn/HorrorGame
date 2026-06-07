extends SceneTree
func _init():
	var ui = load("res://DataMinigameUI.tscn")
	if ui:
		print("SUCCESSFULLY LOADED")
	else:
		print("FAILED TO LOAD")
	quit()
