extends Area2D
# Reference to the label you want to update
@onready var output_label: Label = get_parent().get_node("enemyhp")
@export var hp = 20
signal sg_dropped_attack(bool)

func _ready() -> void:
	output_label.text = str(hp)

func _apply_damage(effect):
	var damage = effect.value
	if effect.conditional != null:
		pass
	take_damage(damage)

func dropped_on(card_data) -> bool:
	if card_data["type"]!= "attack":
		return false
	emit_signal("sg_dropped_attack", true)
	resolve_effects(card_data.effects)
	return true
	
func resolve_effects(effects: Array):
	for effect in effects:
		match effect.type:
			"damage":
				_apply_damage(effect)
func take_damage(amount):
	get_parent().get_child(0).play("damage")
	hp -= amount
	if hp<=0:
		get_parent().get_child(0).play("death")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/maps/map_01.tscn")
	var hpbar = get_parent().get_node_or_null("enemyhp")
	if hpbar:
		hpbar.text = str(hp)
