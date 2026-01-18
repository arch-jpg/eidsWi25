extends Node2D


func _on_exit_pressed() -> void:
	var gold_label = $CenterContainer/MainPanel/VBoxContainer/GoldPanel/GoldContainer.get_node("gold amount")
	var gold_amount: int = int(gold_label.text)
	GameState.add_gold(gold_amount)
	print("Gold earned: ", gold_amount)
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")
