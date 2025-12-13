extends Node

## DeckManager Singleton
## Manages the player's current deck
## Deck must contain at least 10 cards

const MIN_DECK_SIZE = 10
const MAX_DECK_SIZE = 999

var current_deck: Array = []
var deck_save_path = "user://player_deck.save"

signal deck_changed()
signal deck_size_changed(size: int)

func _ready():
	load_deck()
	
	# If no deck exists, create a default starter deck
	if current_deck.is_empty():
		create_default_deck()

func create_default_deck():
	"""Create a default starter deck with 10 cards"""
	current_deck.clear()
	
	# Get all available cards
	var all_cards = CardDatabase.get_all_cards()
	
	# If we have cards, create a basic deck
	if all_cards.size() > 0:
		# Add some common cards to reach minimum deck size
		for i in range(MIN_DECK_SIZE):
			var card = all_cards[i % all_cards.size()]
			current_deck.append(card.id)
	
	save_deck()
	deck_changed.emit()
	deck_size_changed.emit(current_deck.size())

func add_card_to_deck(card_id: String) -> bool:
	"""Add a card to the deck if there's space"""
	if current_deck.size() >= MAX_DECK_SIZE:
		push_warning("Deck is full! Maximum size is %d cards." % MAX_DECK_SIZE)
		return false
	
	if not CardDatabase.card_exists(card_id):
		push_error("Card does not exist: " + card_id)
		return false
	
	current_deck.append(card_id)
	save_deck()
	deck_changed.emit()
	deck_size_changed.emit(current_deck.size())
	return true

func remove_card_from_deck(index: int) -> bool:
	"""Remove a card from the deck at the given index"""
	if index < 0 or index >= current_deck.size():
		push_error("Invalid deck index: " + str(index))
		return false
	
	current_deck.remove_at(index)
	save_deck()
	deck_changed.emit()
	deck_size_changed.emit(current_deck.size())
	return true

func remove_card_by_id(card_id: String) -> bool:
	"""Remove the first occurrence of a card with the given ID"""
	var index = current_deck.find(card_id)
	if index >= 0:
		return remove_card_from_deck(index)
	return false

func get_deck() -> Array:
	"""Get the current deck as an array of Card objects"""
	var cards = []
	for card_id in current_deck:
		var card = CardDatabase.get_card_by_id(card_id)
		if card:
			cards.append(card)
	return cards

func get_deck_card_ids() -> Array:
	"""Get the current deck as an array of card IDs"""
	return current_deck.duplicate()

func get_deck_size() -> int:
	return current_deck.size()

func is_deck_valid() -> bool:
	"""Check if the deck meets the minimum and maximum size requirements"""
	return current_deck.size() >= MIN_DECK_SIZE and current_deck.size() <= MAX_DECK_SIZE

func is_deck_full() -> bool:
	return current_deck.size() >= MAX_DECK_SIZE

func can_add_card() -> bool:
	return current_deck.size() < MAX_DECK_SIZE

func can_remove_card() -> bool:
	return current_deck.size() > 0

func clear_deck():
	"""Clear all cards from the deck"""
	current_deck.clear()
	save_deck()
	deck_changed.emit()
	deck_size_changed.emit(0)

func set_deck(card_ids: Array):
	"""Set the deck to a specific array of card IDs"""
	current_deck = card_ids.duplicate()
	save_deck()
	deck_changed.emit()
	deck_size_changed.emit(current_deck.size())

func save_deck():
	"""Save the current deck to disk"""
	var file = FileAccess.open(deck_save_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"deck": current_deck
		}
		file.store_line(JSON.stringify(save_data))
		file.close()
		print("Deck saved: %d cards" % current_deck.size())
	else:
		push_error("Could not save deck to " + deck_save_path)

func load_deck():
	"""Load the deck from disk"""
	if not FileAccess.file_exists(deck_save_path):
		print("No saved deck found")
		return
	
	var file = FileAccess.open(deck_save_path, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			if save_data.has("deck"):
				current_deck = save_data.deck
				print("Deck loaded: %d cards" % current_deck.size())
				deck_changed.emit()
				deck_size_changed.emit(current_deck.size())
		else:
			push_error("Error parsing deck save file")
	else:
		push_error("Could not load deck from " + deck_save_path)

func get_deck_info() -> String:
	"""Get a formatted string with deck information"""
	var info = "Deck Size: %d (Min: %d)\n" % [current_deck.size(), MIN_DECK_SIZE]
	
	if is_deck_valid():
		info += "Status: Valid ✓"
	elif current_deck.size() < MIN_DECK_SIZE:
		info += "Status: Need %d more cards" % (MIN_DECK_SIZE - current_deck.size())
	else:
		info += "Status: Valid ✓"
	
	return info
