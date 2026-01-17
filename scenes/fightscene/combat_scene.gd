extends Node2D

var deck: Array = []
var discard_pile: Array = []
const HAND_SIZE := 5
var frontpointer = 0
@export var energy_count: int = 4

var allEnemies: Array = []
var double_combat: bool=false
var enemy
var fightEnemies: Array =[]

const CARD_UI_SCENE := preload("res://scenes/cards/card_ui.tscn")
const drag_script = preload("res://scenes/fightscene/draggablearea2d.gd")
var enemyHitbox = preload("res://scenes/fightscene/enemyHitbox.gd")
const enemyscene = preload("res://scenes/character/milk_boy.tscn")
const enemyv2scene = preload("res://scenes/character/Bernd_Brotmann.tscn")

func _ready() -> void:
	$Label.text=str(energy_count)
	build_deck()
	draw_hand(frontpointer)
	get_enemies()
	draw_enemies(enemy)
	pass

func get_enemies():
	allEnemies=EnemiesDatabase.get_all_enemies()
	var randfenemies = randf()
	if randfenemies<=0.4:
		enemy=allEnemies[0]
		fightEnemies.append(enemy)
		return
	elif randfenemies <=0.9:
		enemy=allEnemies[1]
		fightEnemies.append(enemy)
		return
	else:
		double_combat=true
		enemy=allEnemies[0]
		fightEnemies.append(enemy)
		print("double combat")


func draw_enemies(id: String):
	#enemyscene
	if id=="Bernd_Brotmann":
		enemy= enemyv2scene.instantiate()
	else:
		enemy= enemyscene.instantiate()	
	add_child(enemy)
	enemy.apply_scale(Vector2(2,2))
	
	#hitbox
	var enemyhitbox = Area2D.new()
	
	enemy.add_child(enemyhitbox)
	var shapebox = CollisionShape2D.new()
	shapebox.shape = RectangleShape2D.new()
	shapebox.shape.size = Vector2(40,140)
	enemyhitbox.global_position+=Vector2(0,-140)
	enemyhitbox.add_child(shapebox)
	enemyhitbox.set_script(enemyHitbox)
	enemyhitbox.enemyid=id
	enemyhitbox.hp = EnemiesDatabase.get_enemy_health(id)
	print(enemyhitbox.hp)
	var enemyhp = Label.new()
	enemy.add_child(enemyhp)
	enemyhp.text=str(int(EnemiesDatabase.get_enemy_by_id(id)["health"]))
	enemyhp.global_position+=Vector2(-20,0)
	
	#enemyname (for test reasons)
	var enemyname = Label.new()
	enemy.add_child(enemyname)
	if id=="Mc_Milky_Man":
		enemyname.text="Milk Boy"
		enemyname.global_position+=Vector2(-40,-300)
	elif id=="Bernd_Brotmann":
		enemyname.text="Bernd Brotman"
		enemyname.global_position+=Vector2(-70,-300)
	enemyname.scale=Vector2(0.6,0.6)
	
	#skin
	#if id=="Bernd_Brotmann":
		#var animatedsprite = enemy.get_child(1) as AnimatedSprite2D
	
	enemy.global_position=Vector2(1351,470)
	enemyhitbox.add_to_group("enemies")
	enemy.get_child(1).sg_dropped_attack.connect(_dropped_attack)
	
func build_deck():
	deck.clear()
	deck=DeckManager.current_deck.duplicate()
	deck.shuffle()

func add_to_discard(card):
	discard_pile.append(card)

func draw_hand(start):
	# Start deck animation for all cards at once

	$DeckAnimations.draw_cards(HAND_SIZE)
	var draw_delay = $DeckAnimations.card_delay_between_draws + 0.1
	
	await get_tree().create_timer(draw_delay).timeout

	for i in HAND_SIZE:

		# Wait for the delay between card draws to sync with animation
		if i > 0:
			await get_tree().create_timer(draw_delay).timeout
		
		var card = CardDatabase.get_card_by_id(deck[i])
		var ca = Area2D.new()
		var colCa = CollisionShape2D.new()
		
		ca.add_child(colCa)
		colCa.shape = RectangleShape2D.new()
		colCa.shape.size = Vector2(254, 384)
		
		ca.set_script(drag_script)
		
		var card_ui = CARD_UI_SCENE.instantiate()
		
		$handcontainer.add_child(ca)
		ca.add_child(card_ui)
		
		card_ui.global_position=ca.global_position + Vector2(-130, -190)
		card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		frontpointer+=1
		
		if(frontpointer+i>DeckManager.get_deck_size() or frontpointer>DeckManager.get_deck_size()):
			frontpointer = 0
			build_deck()
			
		card_ui.scale = Vector2.ZERO
		card_ui.setup_card(card)
		ca.card_data = card_ui.card_data
		
		print(card_ui.card_data)
		print(ca.card_data)
		
		ca.card_used.connect(_on_card_dropped)
		ca.is_dragging.connect(_on_dragging)
		$handcontainer.add_card_to_hand(ca)
		card_ui.scale = Vector2(1,1)
		#_animate_card_to_hand(colCa,i)
		
func _animate_card_to_hand(card, index: int):
	var spacing := 180

	var base_lift := -20        # lifts ALL cards slightly
	var fan_lift := +10
	var max_rotation := deg_to_rad(6)  # very subtle rotation

	var center = ($handcontainer.hand_cards.size() - 1) * 0.5
	var offset = index - center

	var target_pos = $handcontainer.global_position
	target_pos.x += offset * spacing + 160
	target_pos.y += base_lift + abs(offset) * fan_lift + 140

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(card, "global_position", target_pos, 0.4)
	tween.tween_property(card, "rotation", offset / center * max_rotation, 0.4)
	tween.tween_property(card, "scale", Vector2.ONE, 0.4)
	
func get_hand_position(index: int) -> Vector2:
	var spacing := 140
	var curve := 30
	var center := (HAND_SIZE - 1) * 0.5
	var offset := index - center
	
	return Vector2(offset * spacing, abs(offset) * curve)
	
func _on_card_dropped(area2D):
	$handcontainer._on_card_played(area2D)
	
func _on_dragging(b):
	if b:
		$main_char/AnimatedSprite2D.play("attack_begin")
	else:
		$main_char/AnimatedSprite2D.play("idle")
	
func _take_enemy_turn(id: String):
	var currenemy = EnemiesDatabase.get_enemy_by_id(id)
	var attacks = EnemiesDatabase.get_enemy_attacks(id)
	var randf = randf()
	if currenemy["aggro"] >= randf:
		var attackrandf = randf()
		var cumulative = 0
		for i in currenemy["attacks"]:
			cumulative += i["probability"]
			if attackrandf <= cumulative:
				animate_enemy_attack()
				$main_char/Area2D.take_damage(i["value"])
				print(i)
				return
	else:
		var defenserandf = randf()
		var cumulative = 0
		for i in currenemy["defenses"]:
			cumulative += i["probability"]
			if defenserandf <= cumulative:
				print(i)
				return
		print("defended")
	pass

func _on_end_turn_btn_pressed() -> void:
	energy_count=4
	$Label.text=str(energy_count)
	$handcontainer.end_turn()
	draw_hand(frontpointer)
	for i in fightEnemies:
		print(i)
		_take_enemy_turn(i)

	pass # Replace with function body.
	
func _dropped_attack(b):
	if b:
		print("attacked")
		$main_char/AnimatedSprite2D.play("attack_attack")
	else:
		$main_char/AnimatedSprite2D.play("idle")

# Call this function when the player wins the battle
func _on_battle_won():
	pass

# Call this function when the player loses
func _on_battle_lost():
	pass
func animate_enemy_attack():
	enemy.get_child(0).play("attack")
	pass
