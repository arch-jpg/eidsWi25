extends Node2D

var deck: Array = []
var discard_pile: Array = []
const HAND_SIZE := 5
var frontpointer = 0
const CARD_UI_SCENE := preload("res://scenes/cards/card_ui.tscn")
const drag_script = preload("res://scenes/fightscene/draggablearea2d.gd")

func _ready() -> void:
	build_deck()
	draw_hand(frontpointer)
	$enemy_char.get_child(1).sg_dropped_attack.connect(_dropped_attack)
	pass

func build_deck():
	deck.clear()
	deck=DeckManager.current_deck.duplicate()
	deck.shuffle()

func add_to_discard(card):
	discard_pile.append(card)

func draw_hand(start):
	for i in HAND_SIZE:
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
	
func _take_enemy_turn():
	pass

func _on_end_turn_btn_pressed() -> void:
	_take_enemy_turn()
	$handcontainer.end_turn()
	draw_hand(frontpointer)
	pass # Replace with function body.
	
func _dropped_attack(b):
	if b:
		print("attacked")
		$main_char/AnimatedSprite2D.play("attack_attack")
	else:
		$main_char/AnimatedSprite2D.play("idle")
