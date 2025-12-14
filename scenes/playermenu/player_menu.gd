extends Control


func _on_kampf_pressed() -> void:
	print("Kampf button pressed - Map for Path Figth")
	# TODO: get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	get_tree().change_scene_to_file("res://scenes/maps/map_01.tscn")


func _on_deck_editor_pressed() -> void:
	print("Opening deck editor")
	get_tree().change_scene_to_file("res://scenes/deck_editor/deck_editor.tscn")


func _on_back_pressed() -> void:
	print("Back to main menu")
	get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")
