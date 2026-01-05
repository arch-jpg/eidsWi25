extends Node

## GameState Singleton
## Manages global game state and data transfer between scenes
## Register as Autoload in Project Settings

# Combat-related state
var current_encounter: Array[String] = []  # Enemy IDs for current combat
var current_level_id: String = ""  # Which level the player is fighting in
#var combat_modifiers: Dictionary = {}  # Special combat modifiers (e.g., {"hp_boost": 20})

# Player state
var player_health: int = 100
var player_max_health: int = 100
var player_gold: int = 0

# Progression state
var current_map: String = "map_01"
#var completed_levels: Array[String] = []
var card_collection: Dictionary = {}  # {card_id: quantity} - player's card collection with quantities

# Internal flags
var _is_initializing: bool = true  # Prevent auto-save during startup

# Combat results
var last_combat_won: bool = false
var combat_rewards: Dictionary = {}

func _ready():
	print("GameState initialized")
	
	# Initialize starter cards if collection is empty (will be called by DeckManager)
	if card_collection.is_empty():
		unlock_starter_cards()

# Combat Setup
func setup_combat(level_id: String, enemy_ids: Array[String]):
	"""Prepare combat encounter with given enemies and modifiers."""
	current_level_id = level_id
	current_encounter = enemy_ids.filter(func(e): return e != "")  # Remove empty strings
	#combat_modifiers = modifiers
	print("Combat setup: Level %s with %d enemies" % [level_id, current_encounter.size()])

func clear_combat_state():
	"""Clear combat-related state after battle ends."""
	current_encounter.clear()
	current_level_id = ""
	#combat_modifiers.clear()
	combat_rewards.clear()

# Level Progression
# func complete_level(level_id: String):
#     """Mark a level as completed."""
#     if not level_id in completed_levels:
#         completed_levels.append(level_id)
#         print("Level completed: " + level_id)

# func is_level_completed(level_id: String) -> bool:
#     """Check if a level has been completed."""
#     return level_id in completed_levels

# func get_last_completed_level() -> String:
#     """Get the most recently completed level."""
#     if completed_levels.is_empty():
#         return ""
#     return completed_levels[-1]

#Player Stats
func set_player_health(health: int):
	"""Set player health, clamped to max."""
	player_health = clampi(health, 0, player_max_health)

func heal_player(amount: int):
	"""Heal player by amount."""
	set_player_health(player_health + amount)

func damage_player(amount: int):
	"""Damage player by amount."""
	set_player_health(player_health - amount)

func is_player_alive() -> bool:
	"""Check if player is still alive."""
	return player_health > 0
# Card Collection Management
func add_card_to_collection(card_id: String, quantity: int = 1):
	"""Add cards to the player's collection."""
	if card_id in card_collection:
		card_collection[card_id] += quantity
	else:
		card_collection[card_id] = quantity
	print("✅ Added %d x %s to collection. Total: %d" % [quantity, card_id, card_collection[card_id]])
	
	# Auto-save to persist changes (only after initialization)
	if _is_initializing:
		print(" Skipping auto-save: still initializing")
	elif not DeckManager:
		print(" Skipping auto-save: DeckManager not ready")
	else:
		print(" Auto-saving collection...")
		DeckManager.save_deck()
		print(" Collection saved!")

func remove_card_from_collection(card_id: String, quantity: int = 1) -> bool:
	"""Remove cards from collection. Returns true if successful."""
	if not card_id in card_collection:
		return false
	
	if card_collection[card_id] < quantity:
		return false
	
	card_collection[card_id] -= quantity
	if card_collection[card_id] <= 0:
		card_collection.erase(card_id)
	
	print("Removed %d x %s from collection" % [quantity, card_id])
	
	# Auto-save to persist changes (only after initialization)
	if not _is_initializing and DeckManager:
		DeckManager.save_deck()
	
	return true

func get_card_quantity(card_id: String) -> int:
	"""Get how many of a specific card the player owns."""
	return card_collection.get(card_id, 0)

func has_card_in_collection(card_id: String) -> bool:
	"""Check if player owns at least one of this card."""
	return card_id in card_collection and card_collection[card_id] > 0

func get_unlocked_cards() -> Array[String]:
	"""Get all card IDs that the player owns."""
	var result: Array[String] = []
	for card_id in card_collection.keys():
		if card_collection[card_id] > 0:
			result.append(card_id)
	return result

func get_card_collection() -> Dictionary:
	"""Get the entire card collection with quantities."""
	return card_collection.duplicate()

func reward_random_card(rarity_weights: Dictionary = {}) -> String:
	"""Reward player with a random card. Returns the card ID."""
	var default_weights = {
		"common": 60,
		"uncommon": 25,
		"rare": 12,
		"legendary": 3
	}
	
	var weights = default_weights if rarity_weights.is_empty() else rarity_weights
	
	# Get random card pack (1 card)
	var cards = CardDatabase.create_random_pack(weights)
	
	if cards.is_empty():
		push_warning("No cards available to reward!")
		return ""
	
	var card = cards[0]
	add_card_to_collection(card.id, 1)
	
	print("Reward: %s (%s)" % [card.name, card.rarity])
	return card.id

func reward_cards_by_rarity(rarity: String, count: int = 1):
	"""Reward player with specific rarity cards."""
	var cards = CardDatabase.get_random_cards_by_rarity(rarity, count)
	
	for card in cards:
		add_card_to_collection(card.id, 1)
		print("Reward: %s (%s)" % [card.name, card.rarity])

func unlock_starter_cards():
	"""Unlock basic starter cards for new players."""
	# Starter deck: 
	add_card_to_collection("weak_punch", 5)
	add_card_to_collection("heal_potion", 2)
	add_card_to_collection("meditation", 1)
	add_card_to_collection("iron_wall", 2)
	add_card_to_collection("slice", 2)

	
	print("Starter cards unlocked: %d unique cards" % card_collection.size())

func add_missing_starter_cards():
	"""Add any missing starter cards to existing collection (for updates)"""
	var starter_cards = {
		"weak_punch": 5,
		"heal_potion": 2,
		"meditation": 1,
		"iron_wall": 2,
		"slice": 2
	}
	
	for card_id in starter_cards.keys():
		var required_qty = starter_cards[card_id]
		var current_qty = get_card_quantity(card_id)
		
		if current_qty < required_qty:
			var to_add = required_qty - current_qty
			add_card_to_collection(card_id, to_add)
			print("Added missing starter card: %d x %s" % [to_add, card_id])
# Gold/Currency
func add_gold(amount: int):
	"""Add gold to player."""
	player_gold += amount
	print("Gold added: %d (Total: %d)" % [amount, player_gold])

func spend_gold(amount: int) -> bool:
	"""Try to spend gold. Returns true if successful."""
	if player_gold >= amount:
		player_gold -= amount
		return true
	return false

# Save/Load Integration
func get_save_data() -> Dictionary:
	"""Get all persistent game state as dictionary for saving."""
	return {
		#"completed_levels": completed_levels,
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_gold": player_gold,
		"current_map": current_map,
		"card_collection": card_collection
	}

func load_save_data(data: Dictionary):
	"""Load game state from saved data."""
	#completed_levels = data.get("completed_levels", [])
	player_health = data.get("player_health", player_max_health)
	player_max_health = data.get("player_max_health", 100)
	player_gold = data.get("player_gold", 0)
	current_map = data.get("current_map", "map_01")
	card_collection = data.get("card_collection", {})
	print("Game state loaded")

func reset_game_state():
	"""Reset all game state to defaults (new game)."""
	current_encounter.clear()
	current_level_id = ""
	#combat_modifiers.clear()
	#completed_levels.clear()
	player_health = 100
	#player_max_health = 100
	#player_gold = 0
	current_map = "map_01"
	last_combat_won = false
	combat_rewards.clear()
	card_collection.clear()
	unlock_starter_cards()  # Unlock starter cards for new game
	print("Game state reset")
