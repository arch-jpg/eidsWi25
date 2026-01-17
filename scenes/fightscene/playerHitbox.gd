extends Area2D
# Reference to the label you want to update
@onready var output_label: Label = get_parent().get_node("Label")
@export var hp: int = GameState.get_player_health()
var basehp = GameState.player_health
func _ready() -> void:
	output_label.text = str(hp)

func _apply_damage(effect):
	var damage = effect
	if effect.conditional != null:
		pass
	take_damage(damage)

func _apply_block(effect):
	var block = effect.value
	if effect.conditional != null:
		pass
	get_block(block)

func dropped_on(card_data) -> bool:
	if card_data["type"] != "defense" :
		return false
	get_parent().get_child(0).play("attack_block")
	
	resolve_effects(card_data.effects)
	return true
	
func resolve_effects(effects: Array):
	for effect in effects:
		match effect.type:
			"block":
				_apply_block(effect)
func take_damage(amount):
	GameState.damage_player(amount)
	hp=GameState.get_player_health()
	var hpbar = get_parent().get_node_or_null("Label")
	if hpbar:
		hpbar.text = str(hp)
	if hp <= 0:
		# Player died - clear map and reset game
		get_parent().get_child(0).play("death")
		GameState.clear_map_state()
		print("Player died - map cleared")
		# TODO: Show game over screen
		get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")

func get_block(amount):
	hp += amount
	var hpbar = get_parent().get_node_or_null("Label")
	if hpbar:
		hpbar.text = str(hp)
