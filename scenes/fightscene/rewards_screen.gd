extends Node2D


func _on_exit_pressed() -> void:
	var gold_amount: int = int(get_child(3).text)
	GameState.add_gold(gold_amount)
	print(get_child(3).text)
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")
	pass # Replace with function body.
