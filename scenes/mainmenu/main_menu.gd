extends Control

@onready var cheat_label = $Label

func _process(_delta):
	if Input.is_action_just_pressed("ui_focus_next"):  
		toggle_cheat_label()


func toggle_cheat_label():
	if cheat_label:
		cheat_label.visible = not cheat_label.visible


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			GameState.reset_game_state()
			print("Game progress has been reset!")
		if event.keycode == KEY_G:
			GameState.player_gold += 10000
			print("Added 10000 gold! Current gold: %d" % GameState.player_gold)
		

	


func _on_PLAY_pressed() -> void:
	print("start pressed") 
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")


func _on_OPTIONS_pressed() -> void:
	print("options pressed") 


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits/credits.tscn")


func _on_EXIT_pressed() -> void:
	get_tree().quit()


func _on_button_4_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/cards/card_demo.tscn")
