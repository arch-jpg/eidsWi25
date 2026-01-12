extends Node
class_name MapGenerator

## Generates a procedural map graph similar to Slay the Spire
## Creates layers of nodes with connections ensuring no dead ends

## Number of layers (columns) in the map
@export var num_layers: int = 8

## Minimum nodes per layer
@export var min_nodes_per_layer: int = 2

## Maximum nodes per layer
@export var max_nodes_per_layer: int = 4

## Spacing between nodes horizontally (layers)
@export var layer_spacing: float = 200.0

## Spacing between nodes vertically
@export var node_spacing: float = 150.0

## Maximum connections from one node to next layer
@export var max_connections_per_node: int = 2

## Probability of combat nodes (0.0 - 1.0)
@export var combat_probability: float = 0.6

## Probability of shop nodes (0.0 - 1.0)
@export var shop_probability: float = 0.15

## All nodes in the map
var all_nodes: Array[MapNode] = []

## Nodes organized by layer
var layers: Array[Array] = []


func generate_map() -> Array[MapNode]:
	all_nodes.clear()
	layers.clear()
	
	# Generate all layers except boss
	for layer_idx in range(num_layers):
		var layer_nodes: Array[MapNode] = _generate_layer(layer_idx)
		layers.append(layer_nodes)
		all_nodes.append_array(layer_nodes)
	
	# Generate boss layer
	var boss_layer: Array[MapNode] = _generate_boss_layer(num_layers)
	layers.append(boss_layer)
	all_nodes.append_array(boss_layer)
	
	# Connect nodes between layers
	_connect_layers()
	
	# Ensure no dead ends (except boss)
	_ensure_all_nodes_connected()
	
	# Set first layer as reachable
	for node in layers[0]:
		node.is_reachable = true
	
	return all_nodes


func _generate_layer(layer_idx: int) -> Array[MapNode]:
	var layer_nodes: Array[MapNode] = []
	var num_nodes: int = randi_range(min_nodes_per_layer, max_nodes_per_layer)
	
	# Calculate vertical offset to center the nodes
	var total_height: float = (num_nodes - 1) * node_spacing
	var start_y: float = -total_height / 2.0
	
	for node_idx in range(num_nodes):
		var node_type: MapNode.NodeType = _get_random_node_type(layer_idx)
		var pos: Vector2 = Vector2(
			layer_idx * layer_spacing,
			start_y + node_idx * node_spacing
		)
		
		var node: MapNode = MapNode.new(node_type, pos, layer_idx)
		layer_nodes.append(node)
	
	return layer_nodes


func _generate_boss_layer(layer_idx: int) -> Array[MapNode]:
	var boss_node: MapNode = MapNode.new(
		MapNode.NodeType.BOSS,
		Vector2(layer_idx * layer_spacing, 0.0),
		layer_idx
	)
	return [boss_node]


func _get_random_node_type(layer_idx: int) -> MapNode.NodeType:
	# Never generate boss nodes in regular layers
	var rand: float = randf()
	
	if rand < combat_probability:
		return MapNode.NodeType.COMBAT
	elif rand < combat_probability + shop_probability:
		return MapNode.NodeType.SHOP
	else:
		return MapNode.NodeType.TREASURE


func _connect_layers() -> void:
	# Connect each layer to the next
	for layer_idx in range(layers.size() - 1):
		var current_layer: Array = layers[layer_idx]
		var next_layer: Array = layers[layer_idx + 1]
		
		# Each node in current layer connects to next layer
		for node in current_layer:
			_connect_node_to_next_layer(node, next_layer)


func _connect_node_to_next_layer(node: MapNode, next_layer: Array) -> void:
	# Determine number of connections (1 to max_connections_per_node)
	var num_connections: int = randi_range(1, min(max_connections_per_node, next_layer.size()))
	
	# Get node indices in next layer, prefer nodes at similar vertical positions
	var candidates: Array[int] = []
	for i in range(next_layer.size()):
		candidates.append(i)
	
	# Sort candidates by distance to current node's Y position
	var node_y: float = node.position.y
	candidates.sort_custom(func(a, b): 
		var dist_a: float = abs(next_layer[a].position.y - node_y)
		var dist_b: float = abs(next_layer[b].position.y - node_y)
		return dist_a < dist_b
	)
	
	# Connect to closest candidates
	for i in range(num_connections):
		var target_node: MapNode = next_layer[candidates[i]]
		node.add_connection(target_node)


func _ensure_all_nodes_connected() -> void:
	# Make sure every node in layers 1+ has at least one incoming connection
	for layer_idx in range(1, layers.size()):
		var current_layer: Array = layers[layer_idx]
		
		for node in current_layer:
			if not _has_incoming_connection(node, layers[layer_idx - 1]):
				# Connect from a random node in previous layer
				var prev_layer: Array = layers[layer_idx - 1]
				var random_prev_node: MapNode = prev_layer[randi() % prev_layer.size()]
				random_prev_node.add_connection(node)


func _has_incoming_connection(node: MapNode, previous_layer: Array) -> bool:
	for prev_node in previous_layer:
		if prev_node.next_nodes.has(node):
			return true
	return false


func get_layer_nodes(layer_idx: int) -> Array[MapNode]:
	if layer_idx >= 0 and layer_idx < layers.size():
		var result: Array[MapNode] = []
		result.assign(layers[layer_idx])
		return result
	return []


func get_total_layers() -> int:
	return layers.size()
