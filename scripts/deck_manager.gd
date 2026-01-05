extends Node

## DeckManager Singleton
## Manages the player's current deck
## Deck must contain at least 10 cards

const MIN_DECK_SIZE = 10
const MAX_DECK_SIZE = 999

var current_deck: Array = []
var deck_save_path = "user://player.save"

signal deck_changed()
signal deck_size_changed(size: int)

func _ready():
	# Ensure GameState is initialized first
	if not GameState.is_node_ready():
		await GameState.ready
	
	load_deck()
	
	# If no deck exists, create a default starter deck
	if current_deck.is_empty():
		create_default_deck()

func create_default_deck():
	"""Create a default starter deck from player's card collection"""
	current_deck.clear()
	
	# Get player's card collection
	var collection = GameState.get_card_collection()
	
	if collection.is_empty():
		print("No cards in collection. Cannot create deck.")
		return
	
	# Add all cards from collection to deck
	for card_id in collection.keys():
		var quantity = collection[card_id]
		for i in range(quantity):
			current_deck.append(card_id)
	
	print("Created default deck with %d cards from collection" % current_deck.size())
	save_deck()
	deck_changed.emit()
	deck_size_changed.emit(current_deck.size())

func add_card_to_deck(card_id: String) -> bool:
	"""Add a card to the deck if there's space and player owns it"""
	if current_deck.size() >= MAX_DECK_SIZE:
		push_warning("Deck is full! Maximum size is %d cards." % MAX_DECK_SIZE)
		return false
	
	if not CardDatabase.card_exists(card_id):
		push_error("Card does not exist: " + card_id)
		return false
	
	# Check if player owns enough copies of this card
	var cards_in_deck = current_deck.count(card_id)
	var cards_owned = GameState.get_card_quantity(card_id)
	
	if cards_in_deck >= cards_owned:
		push_warning("You don't own enough copies of this card! (Owned: %d, In deck: %d)" % [cards_owned, cards_in_deck])
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
	"""Save the current deck and card collection to disk"""
	var file = FileAccess.open(deck_save_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"deck": current_deck,
			"card_collection": GameState.get_card_collection()
		}
		file.store_line(JSON.stringify(save_data))
		file.close()
		print("Deck and collection saved: %d cards in deck, %d unique cards owned" % [current_deck.size(), GameState.get_card_collection().size()])
	else:
		push_error("Could not save deck to " + deck_save_path)

func load_deck():
	"""Load the deck and card collection from disk"""
	if not FileAccess.file_exists(deck_save_path):
		print("No saved deck found")
		# Enable auto-save even if no save file exists
		GameState._is_initializing = false
		print("Auto-save enabled (no save file)")
		return
	
	var file = FileAccess.open(deck_save_path, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			
			# Load deck
			if save_data.has("deck"):
				current_deck = save_data.deck
				print("Deck loaded: %d cards" % current_deck.size())
				deck_changed.emit()
				deck_size_changed.emit(current_deck.size())
			
			# Load card collection
			if save_data.has("card_collection"):
				var collection = save_data.card_collection
				# Clear current collection and load saved one
				GameState.card_collection.clear()
				for card_id in collection.keys():
					GameState.card_collection[card_id] = collection[card_id]
				print("Card collection loaded: %d unique cards" % GameState.card_collection.size())
				
				# Add any missing starter cards (for updates)
				GameState.add_missing_starter_cards()
				
				# Initialization complete, enable auto-save
				GameState._is_initializing = false
				print("Auto-save enabled (after loading)")
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
