extends AnimatedSprite2D


func _on_animation_finished() -> void:
	if self.animation == "death":
		return
	else:
		play("idle")
