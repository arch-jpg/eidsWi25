class_name Card
extends Resource

## A card resource that represents a single card in the game
## Can be created from JSON data and used throughout the game

@export var id: String
@export var name: String
@export var description: String
@export var type: String  # attack, defense, cantrip
@export var rarity: String  # common, uncommon, rare, legendary
@export var energy_cost: int #hidden in Game
@export var target: String  # self, enemy_single, all_enemies, etc.
@export var effects: Array
@export var keywords: Array
@export var card_arts: Array  # Array of card art paths
@export var upgrade_path: String
@export var is_upgraded: bool = false
@export var base_card: String

func _init(card_data: Dictionary = {}):
	if card_data.is_empty():
		return
		
	id = card_data.get("id", "")
	name = card_data.get("name", "")
	description = card_data.get("description", "")
	type = card_data.get("type", "")
	rarity = card_data.get("rarity", "")
	energy_cost = card_data.get("energy_cost", 0)
	target = card_data.get("target", "")
	keywords = card_data.get("keywords", [])
	upgrade_path = card_data.get("upgrade_path", "")
	is_upgraded = card_data.get("is_upgraded", false)
	base_card = card_data.get("base_card", "")
	
	# Parse effects
	effects = []
	var effects_data = card_data.get("effects", [])
	for effect_data in effects_data:
		var effect = CardEffect.new(effect_data)
		effects.append(effect)
	
	# Generate card_arts array based on effect types
	card_arts = []
	if card_data.has("card_arts") and card_data.card_arts is Array:
		# Use provided card_arts if specified
		card_arts = card_data.card_arts
	elif effects.size() > 0:
		# Auto-generate card_arts from effect types (max 2)
		var seen_types = {}
		for effect in effects:
			if not seen_types.has(effect.type) and card_arts.size() < 2:
				seen_types[effect.type] = true
				var art_path = "res://data/assets/cards/effect_type_" + effect.type + ".png"
				card_arts.append(art_path)

func get_display_name() -> String:
	return name

func get_display_description() -> String:
	return description

func get_energy_cost() -> int:
	return energy_cost

func can_target(target_type: String) -> bool:
	return target == target_type

func get_keywords() -> Array:
	return keywords

func has_keyword(keyword: String) -> bool:
	return keyword in keywords

func is_attack_card() -> bool:
	return type == "attack"

func is_def_card() -> bool:
	return type == "defense"

func is_cantrip_card() -> bool:
	return type == "cantrip"

func get_rarity_color() -> Color:
	match rarity:
		"common":
			return Color.GRAY
		"uncommon":
			return Color.BLUE
		"rare":
			return Color.VIOLET
		"legendary":
			return Color.GOLD
		_:
			return Color.WHITE

func duplicate_card() -> Card:
	var new_card = Card.new()
	new_card.id = id
	new_card.name = name
	new_card.description = description
	new_card.type = type
	new_card.rarity = rarity
	new_card.energy_cost = energy_cost
	new_card.target = target
	new_card.keywords = keywords.duplicate()
	new_card.card_arts = card_arts.duplicate()
	new_card.upgrade_path = upgrade_path
	new_card.is_upgraded = is_upgraded
	new_card.base_card = base_card
	
	# Duplicate effects
	new_card.effects = []
	for effect in effects:
		new_card.effects.append(effect.duplicate_effect())
	
	return new_card

func get_upgrade() -> Card:
	if upgrade_path.is_empty():
		return null
	return CardDatabase.get_card(upgrade_path)