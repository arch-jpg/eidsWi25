extends Control


func _on_TEST_pressed() -> void:
	print("Test passed")
	get_tree().change_scene_to_file("res://scenes/cardsystem/card_ui.tscn")
