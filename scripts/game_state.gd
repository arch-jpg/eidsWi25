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

# Combat results
var last_combat_won: bool = false
var combat_rewards: Dictionary = {}

func _ready():
    print("GameState initialized")

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
        "current_map": current_map
    }

func load_save_data(data: Dictionary):
    """Load game state from saved data."""
    #completed_levels = data.get("completed_levels", [])
    player_health = data.get("player_health", player_max_health)
    player_max_health = data.get("player_max_health", 100)
    player_gold = data.get("player_gold", 0)
    current_map = data.get("current_map", "map_01")
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
    print("Game state reset")
