extends Node

## EnemyDatabase Singleton
## Loads and manages all enemy data from JSON
## Provides easy access to enemies throughout the game

var _enemies: Dictionary = {}

const ENEMIES_DATA_PATH = "res://data/enemies.json"

func _ready():
    load_enemies_database()

func load_enemies_database():
    var file = FileAccess.open(ENEMIES_DATA_PATH, FileAccess.READ)
    if not file:
        push_error("Could not open enemies database file: " + ENEMIES_DATA_PATH)
        return
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        push_error("Error parsing enemies.json: " + str(parse_result))
        return
    
    var data = json.data
    
    # Load enemies
    _enemies.clear()
    for enemy_id in data.keys():
        var enemy_data = data[enemy_id]
        enemy_data["id"] = enemy_id  # Add ID to the data
        _enemies[enemy_id] = enemy_data
    
    print("Loaded %d enemies from database" % _enemies.size())

func get_enemy_by_id(enemy_id: String) -> Dictionary:
    """Get enemy data by ID. Returns a duplicate to prevent modification of original data."""
    if enemy_id in _enemies:
        return _enemies[enemy_id].duplicate(true)
    else:
        push_warning("Enemy not found: " + enemy_id)
        return {}

func enemy_exists(enemy_id: String) -> bool:
    """Check if an enemy with the given ID exists."""
    return enemy_id in _enemies

func get_all_enemies() -> Array:
    """Get all enemy IDs."""
    return _enemies.keys()

func get_enemy_health(enemy_id: String) -> int:
    """Get the health of an enemy."""
    var enemy = get_enemy_by_id(enemy_id)
    return enemy.get("health", 0)

func get_enemy_attacks(enemy_id: String) -> Array:
    """Get all attacks for an enemy."""
    var enemy = get_enemy_by_id(enemy_id)
    return enemy.get("attacks", [])

func get_enemy_defenses(enemy_id: String) -> Array:
    """Get all defenses for an enemy."""
    var enemy = get_enemy_by_id(enemy_id)
    return enemy.get("defenses", [])

func get_enemy_aggro(enemy_id: String) -> float:
    """Get the aggression level of an enemy (0.0 = defensive, 1.0 = aggressive)."""
    var enemy = get_enemy_by_id(enemy_id)
    return enemy.get("aggro", 0.5)
