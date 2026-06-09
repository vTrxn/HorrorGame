extends SceneTree
func _init():
	var ui = load("res://VentMenuUI.tscn").instantiate()
	print("Instantiated successfully")
	quit()
