extends Control

## Demo scene to test the card database and UI system

@onready var card_container: GridContainer = $VBoxContainer/ScrollContainer/CardContainer
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var load_cards_button: Button = $VBoxContainer/ButtonsContainer/LoadCardsButton
@onready var load_by_type_button: Button = $VBoxContainer/ButtonsContainer/LoadByTypeButton
@onready var load_by_rarity_button: Button = $VBoxContainer/ButtonsContainer/LoadByRarityButton
@onready var random_card_button: Button = $VBoxContainer/ButtonsContainer/RandomCardButton
@onready var starter_deck_button: Button = $VBoxContainer/ButtonsContainer/StarterDeckButton
@onready var clear_button: Button = $VBoxContainer/ButtonsContainer/ClearButton

var card_ui_scene = preload("res://scenes/cards/card_ui.tscn")

func _ready():
	# Connect buttons
	load_cards_button.pressed.connect(_on_load_all_cards)
	load_by_type_button.pressed.connect(_on_load_attack_cards)
	load_by_rarity_button.pressed.connect(_on_load_common_cards)
	random_card_button.pressed.connect(_on_load_random_card)
	starter_deck_button.pressed.connect(_on_load_starter_deck)
	clear_button.pressed.connect(_on_clear_cards)
	
	# Wait for CardDatabase to load
	if CardDatabase:
		_update_info()
	else:
		info_label.text = "Waiting for CardDatabase to load..."

func _update_info():
	var card_count = CardDatabase._cards.size()
	info_label.text = "Database loaded with %d cards" % card_count

func _on_clear_cards():
	for child in card_container.get_children():
		child.queue_free()
	info_label.text = "Cards cleared"

func _display_cards(cards: Array, description: String = ""):
	_on_clear_cards()
	
	if cards.is_empty():
		info_label.text = "No cards found"
		return
	
	for card in cards:
		var card_ui = card_ui_scene.instantiate()
		card_container.add_child(card_ui)
		card_ui.setup_card(card)
		card_ui.card_clicked.connect(_on_card_clicked)
	
	var display_text = "Displaying %d cards" % cards.size()
	if not description.is_empty():
		display_text += " (%s)" % description
	info_label.text = display_text

func _on_load_all_cards():
	var cards = CardDatabase.get_all_cards()
	_display_cards(cards, "all cards")

func _on_load_attack_cards():
	var cards = CardDatabase.get_cards_by_type("attack")
	_display_cards(cards, "attack cards")

func _on_load_common_cards():
	var cards = CardDatabase.get_cards_by_rarity("common")
	_display_cards(cards, "common cards")

func _on_load_random_card():
	var card = CardDatabase.get_random_card()
	if card:
		_display_cards([card], "random card")
	else:
		info_label.text = "No random card available"

func _on_load_starter_deck():
	var cards = CardDatabase.create_starter_deck()
	_display_cards(cards, "starter deck")

func _on_card_clicked(card_ui):
	var card = card_ui.get_card()
	print("Card clicked: ", card.name)
	print("Description: ", card.description)
	print("Energy Cost: ", card.energy_cost)
	print("Type: ", card.type)
	print("Rarity: ", card.rarity)
	print("Keywords: ", card.keywords)
	print("---")
	
	# Update info to show selected card details
	info_label.text = "Selected: %s (%s, %d energy)" % [card.name, card.type, card.energy_cost]
