extends Button
class_name MapNodeUI

## Visual representation of a MapNode
## Handles display and interaction for a single map node

signal node_clicked(node: MapNode)

@onready var type_label: Label = $TypeLabel
@onready var icon_container: Panel = $IconContainer
@onready var icon_sprite: TextureRect = $IconContainer/IconSprite

var map_node: MapNode
var is_active: bool = false

# Icon paths for each node type
const ICON_PATHS: Dictionary = {
	MapNode.NodeType.COMBAT: "res://data/assets/maps/combat_icon.png",
	MapNode.NodeType.SHOP: "res://data/assets/maps/shop_icon.png",
	MapNode.NodeType.TREASURE: "res://data/assets/maps/treasure_icon.png",
	MapNode.NodeType.BOSS: "res://data/assets/maps/boss_icon.png"
}


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
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
	
	# Load and set icon
	if icon_sprite and ICON_PATHS.has(map_node.type):
		var icon_path: String = ICON_PATHS[map_node.type]
		if ResourceLoader.exists(icon_path):
			var texture: Texture2D = load(icon_path)
			icon_sprite.texture = texture
		else:
			print("Warning: Icon not found at path: " + icon_path)
	
	# Update colors based on state
	if map_node.is_visited:
		modulate = Color(0.5, 0.5, 0.5, 1.0)  # Grayed out
		disabled = true
	elif map_node.is_reachable:
		modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full color
		disabled = false
	else:
		modulate = Color(0.3, 0.3, 0.3, 1.0)  # Dark
		disabled = true
	
	# Remove background color - only show icon
	if icon_container:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)  # Transparent background
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


func _on_mouse_entered() -> void:
	# Only scale on hover if node is selectable
	if map_node and map_node.is_reachable and not map_node.is_visited:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)


func _on_mouse_exited() -> void:
	# Return to normal or active size
	var target_scale: Vector2 = Vector2(1.2, 1.2) if is_active else Vector2(1.0, 1.0)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.2)


func get_center_position() -> Vector2:
	return global_position + size / 2.0
