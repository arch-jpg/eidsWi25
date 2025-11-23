extends Node

## CardDatabase Singleton
## Loads and manages all card data from JSON
## Provides easy access to cards throughout the game

var _cards: Dictionary = {}
var _card_types: Array = []
var _rarities: Array = []
var _elements: Array = []
var _target_types: Array = []
var _effect_types: Array = []
var _status_effects: Dictionary = {}

const CARDS_DATA_PATH = "res://data/cards.json"

func _ready():
	load_cards_database()

func load_cards_database():
	var file = FileAccess.open(CARDS_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Could not open cards database file: " + CARDS_DATA_PATH)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parsing cards database JSON: " + str(parse_result))
		return
	
	var data = json.data
	
	# Load cards
	_cards.clear()
	var cards_data = data.get("cards", [])
	for card_data in cards_data:
		var card = Card.new(card_data)
		_cards[card.id] = card
	
	# Load metadata
	_card_types = data.get("card_types", [])
	_rarities = data.get("rarities", [])
	_elements = data.get("elements", [])
	_target_types = data.get("target_types", [])
	_effect_types = data.get("effect_types", [])
	
	# Load status effects
	_status_effects.clear()
	var status_effects_data = data.get("status_effects", [])
	for status_data in status_effects_data:
		var status_name = status_data.get("name", "")
		_status_effects[status_name] = status_data
	
	print("Loaded %d cards from database" % _cards.size())

func get_card(card_id: String) -> Card:
	if card_id in _cards:
		return _cards[card_id].duplicate_card()
	else:
		push_warning("Card not found: " + card_id)
		return null

func get_all_cards() -> Array:
	var result = []
	for card in _cards.values():
		result.append(card.duplicate_card())
	return result

func get_cards_by_type(card_type: String) -> Array:
	var result = []
	for card in _cards.values():
		if card.type == card_type:
			result.append(card.duplicate_card())
	return result

func get_cards_by_rarity(rarity: String) -> Array:
	var result = []
	for card in _cards.values():
		if card.rarity == rarity:
			result.append(card.duplicate_card())
	return result

func get_cards_by_keyword(keyword: String) -> Array:
	var result = []
	for card in _cards.values():
		if card.has_keyword(keyword):
			result.append(card.duplicate_card())
	return result

func get_cards_by_energy_cost(cost: int) -> Array:
	var result = []
	for card in _cards.values():
		if card.energy_cost == cost:
			result.append(card.duplicate_card())
	return result

func get_random_card() -> Card:
	if _cards.is_empty():
		return null
	var keys = _cards.keys()
	var random_key = keys[randi() % keys.size()]
	return get_card(random_key)

func get_random_cards_by_rarity(rarity: String, count: int) -> Array:
	var cards_of_rarity = get_cards_by_rarity(rarity)
	var result = []
	
	cards_of_rarity.shuffle()
	
	for i in range(min(count, cards_of_rarity.size())):
		result.append(cards_of_rarity[i])
	
	return result

func card_exists(card_id: String) -> bool:
	return card_id in _cards

func get_card_types() -> Array:
	return _card_types.duplicate()

func get_rarities() -> Array:
	return _rarities.duplicate()

func get_elements() -> Array:
	return _elements.duplicate()

func get_target_types() -> Array:
	return _target_types.duplicate()

func get_effect_types() -> Array:
	return _effect_types.duplicate()

func get_status_effect_data(status_name: String) -> Dictionary:
	return _status_effects.get(status_name, {})

func create_starter_deck() -> Array:
	"""Create a basic starter deck for new players"""
	var starter_cards = []
	
	# Add some basic cards (adjust based on your game balance)
	for i in range(3):
		starter_cards.append(get_card("fire_bolt"))
	for i in range(2):
		starter_cards.append(get_card("shield_bash"))
	for i in range(2):
		starter_cards.append(get_card("heal_potion"))
	
	return starter_cards

func create_random_pack(rarity_weights: Dictionary = {}) -> Array:
	"""Create a random pack of cards with rarity weights"""
	var default_weights = {
		"common": 60,
		"uncommon": 25,
		"rare": 12,
		"legendary": 3
	}
	
	var weights = default_weights
	if not rarity_weights.is_empty():
		weights = rarity_weights
	
	var pack = []
	var pack_size = 5
	
	for i in range(pack_size):
		var rarity = _get_random_rarity_by_weight(weights)
		var cards_of_rarity = get_cards_by_rarity(rarity)
		if not cards_of_rarity.is_empty():
			var random_card = cards_of_rarity[randi() % cards_of_rarity.size()]
			pack.append(random_card)
	
	return pack

func _get_random_rarity_by_weight(weights: Dictionary) -> String:
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for rarity in weights.keys():
		current_weight += weights[rarity]
		if random_value < current_weight:
			return rarity
	
	return "common"  # fallback

func reload_database():
	"""Reload the card database (useful for development)"""
	load_cards_database()