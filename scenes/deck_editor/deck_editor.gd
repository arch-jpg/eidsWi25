extends Control

## Deck Editor Scene
## Allows the player to build a deck with 10-15 cards

@onready var available_cards_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/AvailablePanel/MarginContainer/VBoxContainer/ScrollContainer/AvailableCardsGrid
@onready var deck_cards_container: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/DeckPanel/MarginContainer/VBoxContainer/ScrollContainer/DeckCardsGrid
@onready var deck_info_label: Label = $MarginContainer/VBoxContainer/TopBar/DeckInfoLabel
@onready var save_button: Button = $MarginContainer/VBoxContainer/BottomBar/SaveButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomBar/BackButton
@onready var clear_button: Button = $MarginContainer/VBoxContainer/BottomBar/ClearButton
@onready var filter_all: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/AllButton
@onready var filter_damage: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/DamageButton
@onready var filter_block: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/BlockButton
@onready var filter_heal: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/HealButton
@onready var filter_draw: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/DrawButton
@onready var filter_discard: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/DiscardButton
@onready var filter_energy: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/EnergyButton
@onready var filter_status: Button = $MarginContainer/VBoxContainer/TopBar/FilterHBox/StatusButton
@onready var search_input: LineEdit = $MarginContainer/VBoxContainer/TopBar/SearchHBox/SearchInput

const CARD_UI_SCENE = preload("res://scenes/cards/card_ui.tscn")

var current_filter: String = "all"
var search_query: String = ""
var deck_card_uis: Array = []

func _ready():
	# Connect buttons
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	filter_all.pressed.connect(_on_filter_changed.bind("all"))
	filter_damage.pressed.connect(_on_filter_changed.bind("damage"))
	filter_block.pressed.connect(_on_filter_changed.bind("block"))
	filter_heal.pressed.connect(_on_filter_changed.bind("heal"))
	filter_draw.pressed.connect(_on_filter_changed.bind("draw_cards"))
	filter_discard.pressed.connect(_on_filter_changed.bind("discard_cards"))
	filter_energy.pressed.connect(_on_filter_changed.bind("energy"))
	filter_status.pressed.connect(_on_filter_changed.bind("status_effect"))
	
	# Connect search input
	search_input.text_changed.connect(_on_search_changed)
	
	# Connect to DeckManager signals
	DeckManager.deck_changed.connect(_on_deck_changed)
	DeckManager.deck_size_changed.connect(_on_deck_size_changed)
	
	# Load cards
	populate_available_cards()
	populate_deck_cards()
	update_deck_info()

func populate_available_cards(filter: String = "all"):
	# Clear existing cards - remove AND queue_free to ensure immediate cleanup
	for child in available_cards_container.get_children():
		available_cards_container.remove_child(child)
		child.queue_free()
	
	# Get all cards based on filter
	var cards = []
	if filter == "all":
		cards = CardDatabase.get_all_cards()
	else:
		# Filter by effect type
		cards = CardDatabase.get_cards_by_effect_type(filter)
	
	# Filter by search query
	if search_query != "":
		var query_lower = search_query.to_lower()
		cards = cards.filter(func(card): 
			return card.name.to_lower().contains(query_lower) or card.description.to_lower().contains(query_lower)
		)
	
	# Sort cards by rarity: common -> uncommon -> rare -> legendary
	var rarity_order = {"common": 0, "uncommon": 1, "rare": 2, "legendary": 3}
	cards.sort_custom(func(a, b): 
		var a_order = rarity_order.get(a.rarity, 999)
		var b_order = rarity_order.get(b.rarity, 999)
		if a_order != b_order:
			return a_order < b_order
		# If same rarity, sort by name
		return a.name < b.name
	)
	
	# Create UI for each card
	for card in cards:
		var card_ui = CARD_UI_SCENE.instantiate()
		available_cards_container.add_child(card_ui)
		card_ui.setup_card(card)
		card_ui.card_clicked.connect(_on_available_card_clicked.bind(card))
		
		# Scale down cards in the browser
		card_ui.scale = Vector2(0.8, 0.8)

func populate_deck_cards():
	# Clear existing cards - remove AND queue_free to ensure immediate cleanup
	for child in deck_cards_container.get_children():
		deck_cards_container.remove_child(child)
		child.queue_free()
	
	deck_card_uis.clear()
	
	# Get current deck
	var deck = DeckManager.get_deck()
	
	# Create UI for each card in deck
	for i in range(deck.size()):
		var card = deck[i]
		var card_ui = CARD_UI_SCENE.instantiate()
		deck_cards_container.add_child(card_ui)
		card_ui.setup_card(card)
		card_ui.card_clicked.connect(_on_deck_card_clicked.bind(i))
		
		# Scale down cards in the deck - match the available cards size
		card_ui.scale = Vector2(0.5, 0.5)
		
		deck_card_uis.append(card_ui)

func _on_available_card_clicked(card_ui: CardUI, card: Card):
	# Try to add card to deck
	if DeckManager.can_add_card():
		DeckManager.add_card_to_deck(card.id)
		print("Added card to deck: " + card.name)
	else:
		print("Deck is full!")

func _on_deck_card_clicked(card_ui: CardUI, index: int):
	# Remove card from deck
	DeckManager.remove_card_from_deck(index)
	print("Removed card from deck at index: " + str(index))

func _on_deck_changed():
	populate_deck_cards()

func _on_deck_size_changed(size: int):
	update_deck_info()

func update_deck_info():
	deck_info_label.text = DeckManager.get_deck_info()
	
	# Update save button state
	if DeckManager.is_deck_valid():
		save_button.disabled = false
		save_button.text = "Save Deck ✓"
	else:
		save_button.disabled = true
		if DeckManager.get_deck_size() < DeckManager.MIN_DECK_SIZE:
			save_button.text = "Need " + str(DeckManager.MIN_DECK_SIZE - DeckManager.get_deck_size()) + " more cards"
		else:
			save_button.text = "Too many cards!"

func _on_filter_changed(filter: String):
	current_filter = filter
	populate_available_cards(filter)
	
	# Update button states
	filter_all.button_pressed = (filter == "all")
	filter_damage.button_pressed = (filter == "damage")
	filter_block.button_pressed = (filter == "block")
	filter_heal.button_pressed = (filter == "heal")
	filter_draw.button_pressed = (filter == "draw_cards")
	filter_discard.button_pressed = (filter == "discard_cards")
	filter_energy.button_pressed = (filter == "energy")
	filter_status.button_pressed = (filter == "status_effect")

func _on_search_changed(new_text: String):
	search_query = new_text
	populate_available_cards(current_filter)

func _on_save_pressed():
	if DeckManager.is_deck_valid():
		DeckManager.save_deck()
		print("Deck saved successfully!")
		# Could add a visual confirmation here

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/playermenu/player_menu.tscn")

func _on_clear_pressed():
	DeckManager.clear_deck()
	print("Deck cleared!")
