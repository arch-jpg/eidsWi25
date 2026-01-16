extends Control
class_name CardUI

## UI representation of a card
## Displays card information and handles user interaction

@onready var name_label: Label = $NameLabel
@onready var energy_cost_label: Label = $EnergyCostLabel
@onready var card_art_container: HBoxContainer = $CardArtContainer
@onready var card_art1: TextureRect = $CardArtContainer/CardArt1
@onready var card_art2: TextureRect = $CardArtContainer/CardArt2
@onready var description_label: RichTextLabel = $DescriptionLabel
@onready var keywords_label: Label = $KeywordsLabel
@onready var rarity_background: TextureRect = $RarityBackground
@onready var background: Panel = $Background

var card_data
var is_hovered: bool = false
var is_selected: bool = false
var original_position: Vector2
var original_scale: Vector2
var quantity_label: Label = null  # Dynamically created label for card quantity
var is_available: bool = true

var dragging = false
var drag_offset := Vector2.ZERO

signal card_clicked(card_ui: CardUI)
signal card_hovered(card_ui: CardUI)
signal card_unhovered(card_ui: CardUI)

func _ready():
	original_scale = scale
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# Set pivot to center for uniform scaling
	pivot_offset = size / 2.0
	
	# Create quantity label dynamically
	quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.position = Vector2(size.x - 45, size.y - 30)
	quantity_label.size = Vector2(40, 25)
	quantity_label.add_theme_font_size_override("font_size", 14)
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	quantity_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quantity_label.add_theme_constant_override("outline_size", 4)
	quantity_label.visible = false
	add_child(quantity_label)

func setup_card(card):
	card_data = card
	update_display()

func update_display():
	if not card_data:
		return
	
	name_label.text = card_data.name
	energy_cost_label.text = str(card_data.energy_cost)
	description_label.text = card_data.description
	
	# Set keywords
	if card_data.keywords.size() > 0:
		keywords_label.text = ", ".join(card_data.keywords)
		keywords_label.visible = true
	else:
		keywords_label.visible = false
	
	# Set card art(s) based on effect types
	if card_data.card_arts and card_data.card_arts.size() > 0:
		# Load first card art
		var texture1 = load(card_data.card_arts[0])
		if texture1:
			card_art1.texture = texture1
			card_art1.visible = true
			card_art1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			card_art1.texture = null
			card_art1.visible = false
			card_art1.size_flags_horizontal = 0
		
		# Load second card art if it exists
		if card_data.card_arts.size() > 1:
			var texture2 = load(card_data.card_arts[1])
			if texture2:
				card_art2.texture = texture2
				card_art2.visible = true
				card_art2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else:
				card_art2.visible = false
				card_art2.size_flags_horizontal = 0
		else:
			card_art2.visible = false
			card_art2.size_flags_horizontal = 0
	else:
		card_art1.texture = null
		card_art1.visible = false
		card_art1.size_flags_horizontal = 0
		card_art2.visible = false
		card_art2.size_flags_horizontal = 0
	
	# Update border color based on rarity
	update_rarity_display()

func set_quantity(available: int, total: int):
	"""Set the quantity display (available/total)"""
	if quantity_label:
		quantity_label.text = "%d/%d" % [available, total]
		quantity_label.visible = true

func set_available(available: bool):
	"""Set whether the card is available (grays out if not)"""
	is_available = available
	if not available:
		modulate = Color(0.5, 0.5, 0.5, 0.7)  # Gray out
	else:
		modulate = Color(1, 1, 1, 1)  # Normal color

func update_rarity_display():
	if not card_data:
		return
	
	# Load rarity background image
	var rarity_path = "res://data/assets/cards/card_" + card_data.rarity + ".png"
	var bg_texture = load(rarity_path)
	if bg_texture:
		rarity_background.texture = bg_texture
	else:
		rarity_background.texture = null
	
	# Update border color based on rarity
	var style_box = background.get_theme_stylebox("panel").duplicate()
	style_box.border_color = card_data.get_rarity_color()
	background.add_theme_stylebox_override("panel", style_box)

func _on_mouse_entered():
	is_hovered = true
	card_hovered.emit(self)
	
	# Create hover animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", original_scale * 1.1, 0.2)
	tween.tween_property(self, "z_index", 10, 0.0)

func _on_mouse_exited():
	is_hovered = false
	card_unhovered.emit(self)
	
	if not is_selected:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", original_scale, 0.2)
		tween.tween_property(self, "z_index", 0, 0.0)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			card_clicked.emit(self)

func set_selected(selected: bool):
	is_selected = selected
	
	if is_selected:
		var style_box = background.get_theme_stylebox("panel").duplicate()
		style_box.border_width_left = 4
		style_box.border_width_top = 4
		style_box.border_width_right = 4
		style_box.border_width_bottom = 4
		style_box.border_color = Color.YELLOW
		background.add_theme_stylebox_override("panel", style_box)
	else:
		update_rarity_display()
		if not is_hovered:
			scale = original_scale

func get_card():
	return card_data

func animate_to_position(target_position: Vector2, duration: float = 0.5):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "global_position", target_position, duration)

func animate_play():
	"""Animation for when the card is played"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	queue_free()

func animate_draw():
	"""Animation for when the card is drawn"""
	scale = Vector2.ZERO
	modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", original_scale, 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func set_playable(playable: bool):
	"""Set whether the card can be played (enough energy, valid targets, etc.)"""
	if playable:
		modulate = Color.WHITE
		mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		modulate = Color(0.5, 0.5, 0.5, 1.0)  # Grayed out
		mouse_filter = Control.MOUSE_FILTER_IGNORE
