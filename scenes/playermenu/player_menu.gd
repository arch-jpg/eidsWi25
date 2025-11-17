extends Control

func _ready() -> void:
	$fadeout.show()
	$fadeout/AnimationPlayer.play("fade_in")
	



func _on_b_deck_pressed() -> void:
	$darkener.show()
	$back_button.show()
	$deck_scroller.show()
	pass # Replace with function body.


func _on_b_shop_pressed() -> void:
	pass # Replace with function body.


func _on_b_start_pressed() -> void:
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	$darkener.hide()
	$deck_scroller.hide()
	$back_button.hide()
