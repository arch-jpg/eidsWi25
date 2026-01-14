# Card Database System for Godot

A comprehensive card database system for creating cards

## Features

- **JSON-based card database** for editing and management
- **Modular card effects system** supporting damage, healing, status effects, and more
- **Card rarity system** with indicators
- **Element/damage type system** ~~(Fire, Ice, Lightning, etc.)~~ Momentan nur Standard
- **Targeting system** (single enemy, all enemies, self, etc.)
- ~~**Card UI component** with animations and hover effects~~
- **Database singleton** access throughout your game

## File Structure

```
data/
  cards.json              # Main card database
scripts/
  card.gd                 # Card resource class
  card_effect.gd          # Card effect resource class
  card_database.gd        # Singleton database manager
scenes/cards/
  card_ui.tscn           # Card UI scene
  card_ui.gd             # Card UI script
  card_demo.tscn         # Demo scene
  card_demo.gd           # Demo script
```

## How to Use

### 1. Adding New Cards

Edit `data/cards.json` to add new cards:

```json
{
  "id": "card_id",
  "name": "Card Name",
  "description": "What your card does",
  "type": "attack",
  "rarity": "common",
  "energy_cost": 2,
  "target": "enemy_single",
  "effects": [
	{
	  "type": "damage",
	  "element": "standard",
	  "value": 8,
	  "target": "selected_enemy"
	}
  ],
  "keywords": ["fire", "damage"],
  "card_art": "res://assets/cards/your_card.png",
  "upgrade_path": "your_card_plus"
}
```

### 2. Accessing Cards in Code

```gdscript
# Get all Cards
var cards = CardDatabase.get_all_cards()

# Get a specific card
var fire_bolt = CardDatabase.get_card_by_id("fire_bolt")

# Get all cards of a type
var attack_cards = CardDatabase.get_cards_by_type("attack")

# Get cards by rarity
var rare_cards = CardDatabase.get_cards_by_rarity("rare")

#Get cards by keyword
var keyword_cards = CardDatabase.get_cards_by_keyword("damage")

#Get cards by Cost
var cost_cards = CardDatabase.get_cards_by_energy_cost("2")

# Create a starter deck
var starter_deck = CardDatabase.create_starter_deck()

# Get a random card
var random_card = CardDatabase.get_random_card()

# Get random cards by rarity
var random_cards = CardDatabase.get_random_cards_by_rarity("common", 3)
```

~~### 3. Displaying Cards~~
~~
```gdscript
# Create a card UI
var card_ui_scene = preload("res://scenes/cards/card_ui.tscn")
var card_ui = card_ui_scene.instantiate()
add_child(card_ui)

# Setup with card data
-
card_ui.setup_card(card)

# Connect to card interaction signals
card_ui.card_clicked.connect(_on_card_clicked)
card_ui.card_hovered.connect(_on_card_hovered)
```
~~

## Card Properties

### Basic Properties
- **id**: Unique identifier
- **name**: Display name
- **description**: Card description text
- **type**: attack, defend, cantrip
- **rarity**: common, uncommon, rare, legendary
- **energy_cost**: Energy required to play, hidden till sux
- **target**: Who/what the card targets

### Effects System

Cards can have multiple effects:

```json
"effects": [
  {
	"type": "damage",
	"element": "standard",
	"value": 6,
	"target": "selected_enemy"
  },
  {
	"type": "status_effect",
	"effect_name": "burn",
	"duration": 3,
	"target": "selected_enemy"
  }
]
```

### Available Effect Types
- `damage`: Deal damage
- `heal`: Restore health
- `block`: Gain defensive block
- `status_effect`: Apply status effects
- `draw_cards`: Draw cards
- ~~`energy`: Gain/lose energy~~
- ~~`extra_turn`: Take additional turns~~

### Elements
- Standard

### Target Types
- `self`: Player character
- `enemy_single`: One enemy
- `all_enemies`: All enemies
- `all_allies`: All allies
- `all_characters`: Everyone
- `random_enemy`: Random enemy
- `weakest_enemy`: Enemy with lowest health
- `strongest_enemy`: Enemy with highest health

## Testing

Run the `card_demo.tscn` scene to test the card database system:
- Load different card types
- View card rarities
- Test card UI interactions
- Generate random cards and starter decks

## Extending the System

### Adding New Effect Types

1. Add the effect type to `data/cards.json` in the `effect_types` array
2. Update `CardEffect.get_description()` to handle the new effect
3. Implement the effect logic in combat system

### Adding New Status Effects

Add status effects to the `status_effects` array in `cards.json`:

```json
{
  "name": "poison",
  "description": "Take poison damage at end of turn",
  "type": "debuff",
  "stackable": true
}
```

### Conditional Effects

Cards can have conditional effects:

```json
{
  "type": "damage",
  "value": 8,
  "conditional": {
	"condition": "target_has_status",
	"status": "vunerable",
	"effect_modifier": "double_damage"
  }
}
```

## Card Collection & Unlock System

The game uses a card collection system where players must unlock cards before they can use them in their deck.

### Card Collection Management

```gdscript
# Add cards to player's collection (e.g., as rewards)
GameState.add_card_to_collection("weak_punch", 3)  # Add 3 copies

# Remove cards from collection
GameState.remove_card_from_collection("weak_punch", 1)  # Remove 1 copy

# Check how many copies the player owns
var quantity = GameState.get_card_quantity("weak_punch")

# Check if player owns at least one copy
if GameState.has_card_in_collection("fire_bolt"):
    print("Player owns Fire Bolt!")

# Get all owned card IDs
var owned_cards = GameState.get_unlocked_cards()

# Get full collection with quantities
var collection = GameState.get_card_collection()  # Returns: {"weak_punch": 5, "heal_potion": 2}
```

### Starter Cards

When a new game starts, these cards are automatically unlocked:
- **5x** Weak Punch
- **2x** Heal Potion
- **1x** Meditation
- **2x** Iron Wall

To customize starter cards, edit `unlock_starter_cards()` in `scripts/game_state.gd`:

```gdscript
func unlock_starter_cards():
    add_card_to_collection("weak_punch", 5)
    add_card_to_collection("heal_potion", 2)
    add_card_to_collection("meditation", 1)
    add_card_to_collection("iron_wall", 2)
```

### Unlocking Cards During Gameplay

```gdscript
# After winning a battle - reward the player with new cards
func _on_battle_won():
    # Give player 1 copy of a new card
    GameState.add_card_to_collection("fire_bolt", 1)
    
    # Or give multiple copies
    GameState.add_card_to_collection("shield_bash", 2)

# Shop system - let player buy cards
func buy_card(card_id: String, cost: int):
    if GameState.spend_gold(cost):
        GameState.add_card_to_collection(card_id, 1)
        print("Card purchased!")
    else:
        print("Not enough gold!")
```

### Deck Editor Integration

The deck editor automatically:
- Shows only cards from the player's collection
- Displays quantity as "available/total" (e.g., "3/5")
- Grays out cards when all copies are in the deck
- Prevents adding more copies than owned

```gdscript
# The deck manager validates card ownership
DeckManager.add_card_to_deck("weak_punch")  # Only works if player owns it
```

### CardDatabase with Unlocks

```gdscript
# Get only unlocked cards
var unlocked_cards = CardDatabase.get_unlocked_cards()

# Get unlocked cards by effect type
var unlocked_damage_cards = CardDatabase.get_cards_by_effect_type("damage", true)
```

### Save/Load System

Card collection is automatically saved/loaded with game state:

```gdscript
# Collection is included in save data
var save_data = GameState.get_save_data()
# save_data["card_collection"] = {"weak_punch": 5, "heal_potion": 2, ...}

# Load from save
GameState.load_save_data(save_data)
```

### Important Notes

- **Quantity Limits**: The system tracks exact quantities - you can't add a card to your deck more times than you own it
- **Persistent**: Card collection persists across game sessions via save system
- **Starter Deck**: Default deck is automatically created from starter cards on first launch
- **Validation**: DeckManager validates ownership before allowing cards in deck

## Best Practices

1. **Use descriptive IDs** for cards (e.g., "fire_bolt", "healing_potion")
2. **Test new cards** in the demo scene before using in game
3. **Use keywords** to help players understand card mechanics
4. **Plan upgrade paths** for card progression
5. **Reward generously**: Give players multiple copies of common cards as rewards
6. **Balance collection**: Consider giving 1-2 rare cards, 2-3 uncommon, 3-5 common per reward
