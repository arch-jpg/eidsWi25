extends Node2D
var deck: Array[Card] = []
var discard_pile: Array[Card] = []

func _ready() -> void:
	build_deck(20)
	pass

func build_deck(amount: int):
	deck.clear()
	for i in amount:
		deck.append(CardDatabase.get_random_card())

func add_to_discard(card):
	discard_pile.append(card)

func show_deck_list():
	$deck.clear()
	var text := ""
	for card in deck:
		text+= card["name"] + "\n"
	$deck.text = text

func _on_deck_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		show_deck_list()
