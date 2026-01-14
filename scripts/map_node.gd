extends Resource
class_name MapNode

## Represents a single node in the procedural map
## Can be Combat, Shop, Treasure, or Boss type

enum NodeType {
	COMBAT,
	SHOP,
	TREASURE,
	BOSS
}

@export var type: NodeType = NodeType.COMBAT
@export var position: Vector2 = Vector2.ZERO
@export var next_nodes: Array[MapNode] = []
@export var is_reachable: bool = false
@export var is_visited: bool = false

## Layer index in the map (used for generation)
@export var layer: int = 0

## Unique identifier for this node
@export var id: String = ""


func _init(p_type: NodeType = NodeType.COMBAT, p_position: Vector2 = Vector2.ZERO, p_layer: int = 0) -> void:
	type = p_type
	position = p_position
	layer = p_layer
	id = _generate_id()


func _generate_id() -> String:
	return "%d_%d_%d" % [layer, randi() % 10000, Time.get_ticks_msec()]


func add_connection(node: MapNode) -> void:
	if node and not next_nodes.has(node):
		next_nodes.append(node)


func get_type_name() -> String:
	match type:
		NodeType.COMBAT:
			return "Combat"
		NodeType.SHOP:
			return "Shop"
		NodeType.TREASURE:
			return "Treasure"
		NodeType.BOSS:
			return "Boss"
		_:
			return "Unknown"


func get_type_color() -> Color:
	match type:
		NodeType.COMBAT:
			return Color.RED
		NodeType.SHOP:
			return Color.GOLD
		NodeType.TREASURE:
			return Color.CYAN
		NodeType.BOSS:
			return Color.PURPLE
		_:
			return Color.WHITE
