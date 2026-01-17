extends Control
class_name MapScreen

## Main controller for the procedural map system
## Manages map generation, node display, and player interaction

signal node_selected(node: MapNode)

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var lines_layer: Node2D = $ScrollContainer/MapContainer/LinesLayer
@onready var nodes_layer: Control = $ScrollContainer/MapContainer/NodesLayer
@onready var gold_label: Label = $UILayer/HBoxContainer/GoldLabel

@export var node_ui_scene: PackedScene = preload("res://scenes/map_system/map_node_ui.tscn")

var generator: MapGenerator
var all_nodes: Array[MapNode] = []
var node_ui_map: Dictionary = {}  # MapNode -> MapNodeUI
var current_node: MapNode = null

# Line drawing settings - improved colors
var active_line_color: Color = Color(0.9, 0.7, 0.3, 0.9)  # Golden active path
var inactive_line_color: Color = Color(0.3, 0.3, 0.35, 0.5)  # Darker inactive
var visited_line_color: Color = Color(0.2, 0.6, 0.8, 0.7)  # Blue for completed paths
var line_width: float = 4.0


func _ready() -> void:
	generator = MapGenerator.new()
	
	# Wait for DeckManager to load save data first
	if not DeckManager.is_node_ready():
		await DeckManager.ready
	
	# Small delay to ensure all save data is loaded
	await get_tree().process_frame
	
	# Check if there's a saved map, otherwise generate new one
	if GameState.has_saved_map():
		print("Loading existing map with %d nodes" % GameState.saved_map_data.size())
		load_saved_map()
		# Restore scroll position after a frame to ensure layout is ready
		await get_tree().process_frame
		scroll_container.scroll_horizontal = int(GameState.map_scroll_position.x)
		scroll_container.scroll_vertical = int(GameState.map_scroll_position.y)
	else:
		print("No saved map found, generating new one")
		generate_and_display_map()
	
	# Update gold display
	_update_gold_display()


func _unhandled_input(event: InputEvent) -> void:
	# Cheat key: Press G to add 1000 gold
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			GameState.add_gold(10000)
			print("Cheat activated: +10000 gold (Total: %d)" % GameState.player_gold)
			get_viewport().set_input_as_handled()


func generate_and_display_map() -> void:
	# Clear existing
	_clear_map()
	
	# Reset scroll position to top-left
	scroll_container.scroll_horizontal = 0
	scroll_container.scroll_vertical = 0
	
	# Generate map
	all_nodes = generator.generate_map()
	
	# Calculate map size and set container size
	_setup_container_size()
	
	# Create UI for each node
	_create_node_uis()
	
	# Draw connections
	_draw_all_connections()
	
	# Save the generated map with initial scroll position (0,0)
	GameState.save_map_state(all_nodes, current_node, Vector2.ZERO)
	# Persist to disk immediately
	DeckManager.save_deck()
	print("New map generated and saved to disk")


func _clear_map() -> void:
	# Clear all node UIs
	for child in nodes_layer.get_children():
		child.queue_free()
	
	# Clear all lines
	for child in lines_layer.get_children():
		child.queue_free()
	
	node_ui_map.clear()
	current_node = null


func _setup_container_size() -> void:
	# Calculate required size based on all nodes
	var max_x: float = 0.0
	var min_y: float = 0.0
	var max_y: float = 0.0
	
	for node in all_nodes:
		max_x = max(max_x, node.position.x)
		min_y = min(min_y, node.position.y)
		max_y = max(max_y, node.position.y)
	
	# Add padding
	var padding: Vector2 = Vector2(300, 300)
	var map_size: Vector2 = Vector2(
		max_x + padding.x,
		max_y - min_y + padding.y
	)
	
	map_container.custom_minimum_size = map_size
	map_container.size = map_size


func _create_node_uis() -> void:
	# Calculate offset once for UI positioning
	var max_x: float = 0.0
	var min_y: float = 0.0
	var max_y: float = 0.0
	
	for node in all_nodes:
		max_x = max(max_x, node.position.x)
		min_y = min(min_y, node.position.y)
		max_y = max(max_y, node.position.y)
	
	var padding: Vector2 = Vector2(300, 300)
	var map_size: Vector2 = Vector2(
		max_x + padding.x,
		max_y - min_y + padding.y
	)
	var y_offset: float = (map_size.y - (max_y - min_y)) / 2.0 - min_y
	var x_offset: float = 100.0  # Left padding
	
	for node in all_nodes:
		var node_ui: MapNodeUI = node_ui_scene.instantiate()
		nodes_layer.add_child(node_ui)
		
		# Position the UI with offset (don't modify node.position)
		node_ui.position = Vector2(node.position.x + x_offset, node.position.y + y_offset)
		
		# Setup the node
		node_ui.setup(node)
		node_ui.node_clicked.connect(_on_node_clicked)
		
		# Store reference
		node_ui_map[node] = node_ui


func _draw_all_connections() -> void:
	# Draw lines for all connections
	for node in all_nodes:
		for next_node in node.next_nodes:
			_draw_connection(node, next_node)


func _draw_connection(from_node: MapNode, to_node: MapNode) -> void:
	var line: Line2D = Line2D.new()
	lines_layer.add_child(line)
	
	# Get UI positions
	var from_ui: MapNodeUI = node_ui_map.get(from_node)
	var to_ui: MapNodeUI = node_ui_map.get(to_node)
	
	if not from_ui or not to_ui:
		return
	
	# Calculate center positions
	var from_pos: Vector2 = from_ui.position + from_ui.size / 2.0
	var to_pos: Vector2 = to_ui.position + to_ui.size / 2.0
	
	# Set line points
	line.add_point(from_pos)
	line.add_point(to_pos)
	
	# Set line appearance with rounded ends
	line.width = line_width
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	
	# Determine line color based on state
	var line_color: Color
	if from_node.is_visited:
		line_color = visited_line_color  # Blue for completed paths
	elif from_node.is_reachable and not from_node.is_visited:
		line_color = active_line_color  # Golden for active paths
	else:
		line_color = inactive_line_color  # Gray for locked paths
	
	line.default_color = line_color
	
	# Store reference for later updates
	line.set_meta("from_node", from_node)
	line.set_meta("to_node", to_node)


func _on_node_clicked(node: MapNode) -> void:
	if not node.is_reachable or node.is_visited:
		return
	
	# Mark current node as visited
	if current_node:
		current_node.is_visited = true
		var current_ui: MapNodeUI = node_ui_map.get(current_node)
		if current_ui:
			current_ui.set_active(false)
			current_ui.update_visual()
	
	# Lock all other reachable nodes on the same layer (other paths)
	_lock_alternative_paths(node)
	
	# Set new current node
	current_node = node
	node.is_visited = true
	
	# Update current node UI (mark as visited, not active)
	var node_ui: MapNodeUI = node_ui_map.get(node)
	if node_ui:
		node_ui.set_active(false)
		node_ui.update_visual()
	
	# Update reachability for next nodes and make them active
	for next_node in node.next_nodes:
		next_node.is_reachable = true
		var next_ui: MapNodeUI = node_ui_map.get(next_node)
		if next_ui:
			next_ui.set_active(true)  # Make next nodes larger
			next_ui.update_visual()
	
	# Update line colors
	_update_line_colors()
	
	# Save map state after node selection with scroll position
	var scroll_pos: Vector2 = Vector2(
		scroll_container.scroll_horizontal,
		scroll_container.scroll_vertical
	)
	GameState.save_map_state(all_nodes, current_node, scroll_pos)
	
	# Emit signal for game logic
	node_selected.emit(node)
	
	# Handle node type specific logic
	_handle_node_type(node)


func _update_line_colors() -> void:
	for line in lines_layer.get_children():
		if line is Line2D:
			var from_node: MapNode = line.get_meta("from_node")
			
			# Determine line color based on state
			var line_color: Color
			if from_node.is_visited:
				line_color = visited_line_color  # Blue for completed paths
			elif from_node.is_reachable and not from_node.is_visited:
				line_color = active_line_color  # Golden for active paths
			else:
				line_color = inactive_line_color  # Gray for locked paths
			
			line.default_color = line_color


func _lock_alternative_paths(selected_node: MapNode) -> void:
	"""Lock all other nodes on the same layer that weren't selected."""
	for node in all_nodes:
		# Find nodes on the same layer that are reachable but not the selected one
		if node.layer == selected_node.layer and node != selected_node:
			if node.is_reachable and not node.is_visited:
				node.is_reachable = false
				var node_ui: MapNodeUI = node_ui_map.get(node)
				if node_ui:
					node_ui.update_visual()
				
				# Also lock all nodes that are only reachable through this alternative path
				_lock_downstream_nodes(node)


func _lock_downstream_nodes(node: MapNode) -> void:
	"""Recursively lock all nodes that follow this node."""
	for next_node in node.next_nodes:
		if not next_node.is_visited:
			next_node.is_reachable = false
			var next_ui: MapNodeUI = node_ui_map.get(next_node)
			if next_ui:
				next_ui.update_visual()
			
			# Recursively lock downstream
			_lock_downstream_nodes(next_node)


func _handle_node_type(node: MapNode) -> void:
	match node.type:
		MapNode.NodeType.COMBAT:
			print("Starting combat encounter...")
			GameState.is_boss_fight = false
			get_tree().change_scene_to_file("res://scenes/fightscene/combat_scene.tscn")
		MapNode.NodeType.SHOP:
			print("Entering shop...")
			get_tree().change_scene_to_file("res://scenes/shop/shop_screen.tscn")
		MapNode.NodeType.TREASURE:
			print("Opening treasure...")
			get_tree().change_scene_to_file("res://scenes/treasure/treasure_screen.tscn")
		MapNode.NodeType.BOSS:
			print("Boss battle!")
			GameState.is_boss_fight = true
			get_tree().change_scene_to_file("res://scenes/fightscene/combat_scene.tscn")


func get_current_node() -> MapNode:
	return current_node


func reset_map() -> void:
	generate_and_display_map()
	# Map is already saved by generate_and_display_map()


func _on_back_button_pressed() -> void:
	# Save current scroll position before leaving
	var scroll_pos: Vector2 = Vector2(
		scroll_container.scroll_horizontal,
		scroll_container.scroll_vertical
	)
	GameState.save_map_state(all_nodes, current_node, scroll_pos)
	get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")


func _on_deck_editor_button_pressed() -> void:
	"""Open the deck editor"""
	# Save current scroll position before leaving
	var scroll_pos: Vector2 = Vector2(
		scroll_container.scroll_horizontal,
		scroll_container.scroll_vertical
	)
	GameState.save_map_state(all_nodes, current_node, scroll_pos)
	
	# Set return scene so deck editor knows where to go back
	GameState.return_scene = "res://scenes/map_system/map_screen.tscn"
	
	get_tree().change_scene_to_file("res://scenes/deck_editor/deck_editor.tscn")


func _update_gold_display() -> void:
	"""Update the gold label"""
	if gold_label:
		gold_label.text = "Gold: %d" % GameState.player_gold


func load_saved_map() -> void:
	"""Load and reconstruct map from saved data."""
	_clear_map()
	
	var saved_data: Dictionary = GameState.saved_map_data
	var node_lookup: Dictionary = {}  # id -> MapNode
	
	# First pass: Create all nodes
	for node_id in saved_data.keys():
		var node_data: Dictionary = saved_data[node_id]
		var node: MapNode = MapNode.new()
		node.id = node_id
		node.type = node_data["type"]
		node.position = Vector2(node_data["position"]["x"], node_data["position"]["y"])
		node.layer = node_data["layer"]
		node.is_reachable = node_data["is_reachable"]
		node.is_visited = node_data["is_visited"]
		
		all_nodes.append(node)
		node_lookup[node_id] = node
	
	# Second pass: Restore connections
	for node_id in saved_data.keys():
		var node_data: Dictionary = saved_data[node_id]
		var node: MapNode = node_lookup[node_id]
		
		for next_id in node_data["next_node_ids"]:
			if next_id in node_lookup:
				node.next_nodes.append(node_lookup[next_id])
	
	# Restore current node
	if GameState.current_map_node_id != "" and GameState.current_map_node_id in node_lookup:
		current_node = node_lookup[GameState.current_map_node_id]
	
	# Setup UI
	_setup_container_size()
	_create_node_uis()
	_draw_all_connections()
	
	# Make reachable (but not visited) nodes active/larger
	for node in all_nodes:
		if node.is_reachable and not node.is_visited:
			var node_ui: MapNodeUI = node_ui_map.get(node)
			if node_ui:
				node_ui.set_active(true)
	
	print("Loaded saved map with %d nodes" % all_nodes.size())
