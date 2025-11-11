extends Control


func _on_PLAY_pressed() -> void:
	print("start pressed") 
	get_tree().change_scene_to_file("res://playermenu/player_menu.tscn")


func _on_OPTIONS_pressed() -> void:
	print("options pressed") 


func _on_EXIT_pressed() -> void:
	get_tree().quit()
