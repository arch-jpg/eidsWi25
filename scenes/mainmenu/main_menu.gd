extends Control


func _on_PLAY_pressed() -> void:
	print("start pressed") 
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")


func _on_OPTIONS_pressed() -> void:
	print("options pressed") 


func _on_EXIT_pressed() -> void:
	get_tree().quit()


func _on_button_4_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/cards/card_demo.tscn")
