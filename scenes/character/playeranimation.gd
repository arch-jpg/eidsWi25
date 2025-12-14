extends AnimatedSprite2D

func _on_animation_finished() -> void:
	if self.animation == "attack_begin":
		play("attack_wait")
	else:
		play("idle")
