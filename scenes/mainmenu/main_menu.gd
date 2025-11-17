extends Control

var button_type = null

func _on_PLAY_pressed() -> void:
	button_type="start"
	$fadeout.show()
	$fadeout/fade_timer.start()
	$fadeout/AnimationPlayer.play("fade_out")
	print("start pressed") 


func _on_OPTIONS_pressed() -> void:
	button_type="options"


func _on_EXIT_pressed() -> void:
	get_tree().quit()


func _on_fade_timer_timeout() -> void:
	if button_type == "start":
		get_tree().change_scene_to_file("res://scenes/playermenu/player_menu.tscn")
	elif button_type == "options":
		print("optiions pressed")
