extends Button
class_name MapNodeUI

## Visual representation of a MapNode
## Handles display and interaction for a single map node

signal node_clicked(node: MapNode)

@onready var type_label: Label = $TypeLabel
@onready var icon_container: Panel = $IconContainer

var map_node: MapNode
var is_active: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)
	update_visual()


func setup(node: MapNode) -> void:
	map_node = node
	update_visual()


func update_visual() -> void:
	if not map_node:
		return
	
	# Update button appearance
	if type_label:
		type_label.text = map_node.get_type_name()
	
	# Update colors based on state
	var base_color: Color = map_node.get_type_color()
	
	if map_node.is_visited:
		modulate = Color(0.5, 0.5, 0.5, 1.0)  # Grayed out
		disabled = true
	elif map_node.is_reachable:
		modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full color
		disabled = false
	else:
		modulate = Color(0.3, 0.3, 0.3, 1.0)  # Dark
		disabled = true
	
	# Set button color
	if icon_container:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = base_color
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		icon_container.add_theme_stylebox_override("panel", style)


func set_active(active: bool) -> void:
	is_active = active
	if is_active:
		scale = Vector2(1.2, 1.2)
	else:
		scale = Vector2(1.0, 1.0)


func _on_pressed() -> void:
	if map_node and map_node.is_reachable and not map_node.is_visited:
		node_clicked.emit(map_node)


func get_center_position() -> Vector2:
	return global_position + size / 2.0
