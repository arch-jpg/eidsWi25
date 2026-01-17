extends Button
class_name MapNodeUI

## Visual representation of a MapNode
## Handles display and interaction for a single map node

signal node_clicked(node: MapNode)

@onready var type_label: Label = $TypeLabel if has_node("TypeLabel") else null
@onready var icon_container: Panel = $IconContainer
@onready var icon_sprite: TextureRect = $IconContainer/IconSprite
@onready var border_panel: Panel = $IconContainer/BorderPanel if has_node("IconContainer/BorderPanel") else null
@onready var glow_effect: Panel = $GlowEffect if has_node("GlowEffect") else null

var map_node: MapNode
var is_active: bool = false
var pulse_tween: Tween

# Icon paths for each node type
const ICON_PATHS: Dictionary = {
	MapNode.NodeType.COMBAT: "res://data/assets/maps/combat_icon.png",
	MapNode.NodeType.SHOP: "res://data/assets/maps/shop_icon.png",
	MapNode.NodeType.TREASURE: "res://data/assets/maps/treasure_icon.png",
	MapNode.NodeType.BOSS: "res://data/assets/maps/boss_icon.png"
}

# Color schemes for different states
const COLOR_ACTIVE = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_VISITED = Color(0.4, 0.4, 0.4, 0.8)
const COLOR_LOCKED = Color(0.25, 0.25, 0.3, 0.7)
const COLOR_HOVER = Color(1.2, 1.1, 1.0, 1.0)


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
	
	# Update label if exists
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
	
	# Update colors and states based on node state
	if map_node.is_visited:
		modulate = COLOR_VISITED
		disabled = true
		_stop_pulse()
	elif map_node.is_reachable:
		modulate = COLOR_ACTIVE
		disabled = false
		_start_pulse()
	else:
		modulate = COLOR_LOCKED
		disabled = true
		_stop_pulse()
	
	# Update border color based on node type
	if border_panel:
		var style: StyleBoxFlat = border_panel.get_theme_stylebox("panel").duplicate()
		if map_node.type == MapNode.NodeType.BOSS:
			style.border_color = Color(0.8, 0.2, 0.2, 1.0)  # Red for boss
		elif map_node.type == MapNode.NodeType.TREASURE:
			style.border_color = Color(1.0, 0.85, 0.1, 1.0)  # Gold for treasure
		elif map_node.type == MapNode.NodeType.SHOP:
			style.border_color = Color(0.2, 0.8, 0.4, 1.0)  # Green for shop
		else:
			style.border_color = Color(0.615133, 0.397776, 0.217245, 1.0)  # Default brown
		border_panel.add_theme_stylebox_override("panel", style)


func set_active(active: bool) -> void:
	is_active = active
	if is_active:
		scale = Vector2(1.2, 1.2)
		if glow_effect:
			glow_effect.visible = true
	else:
		scale = Vector2(1.0, 1.0)
		if glow_effect:
			glow_effect.visible = false


func _start_pulse() -> void:
	if not glow_effect or pulse_tween:
		return
	
	glow_effect.visible = true
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(glow_effect, "modulate:a", 0.8, 1.0)
	pulse_tween.tween_property(glow_effect, "modulate:a", 0.2, 1.0)


func _stop_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	if glow_effect:
		glow_effect.visible = false


func _on_pressed() -> void:
	if map_node and map_node.is_reachable and not map_node.is_visited:
		# Quick click animation
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
		
		node_clicked.emit(map_node)


func _on_mouse_entered() -> void:
	# Only scale on hover if node is selectable
	if map_node and map_node.is_reachable and not map_node.is_visited:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.2)
		tween.parallel().tween_property(self, "modulate", COLOR_HOVER, 0.2)
		
		# Rotate slightly on hover
		tween.parallel().tween_property(self, "rotation_degrees", 5.0, 0.15)
		tween.tween_property(self, "rotation_degrees", -5.0, 0.15)
		tween.tween_property(self, "rotation_degrees", 0.0, 0.1)


func _on_mouse_exited() -> void:
	# Return to normal or active size
	var target_scale: Vector2 = Vector2(1.2, 1.2) if is_active else Vector2(1.0, 1.0)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.2)
	tween.parallel().tween_property(self, "modulate", COLOR_ACTIVE if map_node.is_reachable else COLOR_LOCKED, 0.2)
	tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.2)


func get_center_position() -> Vector2:
	return global_position + size / 2.0
