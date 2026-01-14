extends AnimatedSprite2D

var previous_animation: String = ""

func _on_animation_finished() -> void:
	if self.animation == "attack_begin":
		play("attack_wait")
	else:
		play("idle")

func _on_animation_changed() -> void:
	if previous_animation == "attack_wait" and self.animation != "attack_wait":
		play("attack_wait_end")
	
	previous_animation = self.animation
