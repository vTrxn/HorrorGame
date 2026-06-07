extends SceneTree
func _init():
	print("LOADING DATA MINIGAME UI")
	var ui = preload("res://DataMinigameUI.tscn").instantiate()
	print("UI OK")
	quit()
