extends Node2D

var deck: Array = []
var discard_pile: Array = []
var hand_cards: Array = []
const HAND_SIZE := 5
var frontpointer = 0
const CARD_UI_SCENE := preload("res://scenes/cards/card_ui.tscn")

func _ready() -> void:
	build_deck()
	draw_hand()
	pass

func build_deck():
	deck.clear()
	deck=DeckManager.current_deck.duplicate()
	deck.shuffle()

func add_to_discard(card):
	discard_pile.append(card)

func draw_hand():
	hand_cards.clear()
	for i in HAND_SIZE:
		var card = CardDatabase.get_card_by_id(deck[i])
		var card_ui = CARD_UI_SCENE.instantiate()
		$handcontainer.add_child(card_ui)
		frontpointer+=1
		if(frontpointer+i or frontpointer>DeckManager.get_deck_size()):
			frontpointer = 0
			build_deck()
		card_ui.global_position = $deck.global_position
		card_ui.scale = Vector2.ZERO
		card_ui.setup_card(card)
		hand_cards.append(card)
		# Scale down cards in the browser
		card_ui.scale = Vector2(1,1)
		_animate_card_to_hand(card_ui,i)
		
func _animate_card_to_hand(card, index: int):
	var spacing := 180

	var base_lift := -20        # lifts ALL cards slightly
	var fan_lift := +10         # extra lift for edge cards
	var max_rotation := deg_to_rad(6)  # very subtle rotation

	var center := (HAND_SIZE - 1) * 0.5
	var offset := index - center

	var target_pos = $handcontainer.global_position
	target_pos.x += offset * spacing
	target_pos.y += base_lift + abs(offset) * fan_lift

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
