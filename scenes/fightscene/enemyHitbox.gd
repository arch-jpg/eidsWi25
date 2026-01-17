extends Area2D

@export var enemyid: String
var hp = EnemiesDatabase.get_enemy_health(enemyid)
signal sg_dropped_attack(bool)

func _ready() -> void:
	get_parent().get_child(2).text = str(hp)
	hp=EnemiesDatabase.get_enemy_health(enemyid)
	print(hp)
	
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
		var hpbar = get_parent().get_child(2)
		if hpbar:
			hpbar.text = "0"
		get_parent().get_child(0).play("death")
		await get_tree().create_timer(3.0).timeout
		
		# Check if this was a boss fight
		if GameState.is_boss_fight:
			print("Boss defeated! Clearing map for new one...")
			GameState.clear_map_state()
			GameState.is_boss_fight = false
		
		get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")
	var hpbar = get_parent().get_child(2)
	print(hpbar)
	if hpbar:
		hpbar.text = str(hp)
