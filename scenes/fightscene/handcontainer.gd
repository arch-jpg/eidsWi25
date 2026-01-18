extends Node2D

var hand_cards: Array = []
var discard: Array = []
var spacing := 180
var base_lift := -20
var fan_lift := 10
var max_rotation := deg_to_rad(6)
var stagger_delay := 0.03
var dragging

func _on_card_played(card: Node2D):
	if hand_cards.has(card):
		discard.append(card)
		hand_cards.erase(card)

	if is_instance_valid(card):
		card.global_position = Vector2(0,0)
		card.hide()
	# Relayout remaining cards
	_relayout_hand()

	# Safely remove the played card from the scene
	#if is_instance_valid(card):
		#card.global_position = Vector2(0,0)
		#card.hide()

func add_card_to_hand(card: Node2D):
	hand_cards.append(card)
	#add_child(card)
	_relayout_hand()

func end_turn():
	for i in hand_cards.duplicate():
		discard.append(i)
		hand_cards.erase(i)
		i.hide()

func _relayout_hand():
	var hand_size := hand_cards.size()
	if hand_size == 0:
		return

	for i in range(hand_size):
		var card = hand_cards[i]

		# Skip invalid cards or currently dragged cards
		if not is_instance_valid(card):
			continue
		if card.dragging:
			continue

		# Kill any previous tween on this card
		if card.has_meta("hand_tween"):
			var old_tween: Tween = card.get_meta("hand_tween")
			if old_tween and old_tween.is_running():
				old_tween.kill()

		var center := (hand_size - 1) * 0.5
		var offset := i - center

		# Compute target position
		var target_pos = global_position
		target_pos.x += offset * spacing + 160
		target_pos.y += base_lift + abs(offset) * fan_lift + 140

		if card.has_meta("hand_tween"):
			var old_tween: Tween = card.get_meta("hand_tween")
			if old_tween and old_tween.is_running():
				old_tween.kill()

		# Create tween
		var tween := create_tween()
		var card_rotation: float
		card.set_meta("hand_tween", tween)

		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		if center == 0:
			card_rotation = 0.0 
		else: 
			card_rotation = offset / center * max_rotation
		tween.tween_property(card, "global_position", target_pos, 0.35)
		tween.tween_property(card, "rotation", card_rotation, 0.4)
		tween.tween_property(card, "scale", Vector2.ONE, 0.35)

		# Ensure proper z-index for overlapping visuals
		card.z_index = i
