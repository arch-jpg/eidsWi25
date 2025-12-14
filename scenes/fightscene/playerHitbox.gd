extends Area2D
@onready var animated_sprite = get_parent() as AnimatedSprite2D
@onready var output_label: Label = get_parent().get_node("Label")
@export var hp := 20
func _ready() -> void:
	output_label.text = str(hp)

func _on_area_entered(area):
	print("entered")
	var panel = area.get_parent()	# the Panel node
	if panel.has_method("try_drop"):
		panel.drop_target = self

func _on_area_exited(area):
	var panel = area.get_parent()
	if panel.drop_target == self:
		panel.drop_target = null

func apply_panel_value(value: int):
	output_label.text = str(value)
	
func apply_damage(amount):
	animated_sprite.play("damage")
	hp -= amount
	output_label.text = str(hp)
