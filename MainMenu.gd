extends Control

@onready var role_option = $VBoxContainer/RoleOption
@onready var color_option = $VBoxContainer/ColorOption
@onready var ip_line_edit = $VBoxContainer/IPLineEdit

func _on_host_pressed():
	MultiplayerManager.host_game(role_option.selected, color_option.selected)

func _on_join_pressed():
	var ip = ip_line_edit.text
	if ip == "":
		ip = "127.0.0.1"
	MultiplayerManager.join_game(role_option.selected, color_option.selected, ip)
