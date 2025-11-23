extends Control
class_name CardUI

## UI representation of a card
## Displays card information and handles user interaction

@onready var name_label: Label = $VBoxContainer/TopRow/NameLabel
@onready var energy_cost_label: Label = $VBoxContainer/TopRow/EnergyCostLabel
@onready var card_art: TextureRect = $VBoxContainer/CardArt
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var description_label: RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var keywords_label: Label = $VBoxContainer/KeywordsLabel
@onready var background: Panel = $Background

var card_data
var is_hovered: bool = false
var is_selected: bool = false
var original_position: Vector2
var original_scale: Vector2

signal card_clicked(card_ui: CardUI)
signal card_hovered(card_ui: CardUI)
signal card_unhovered(card_ui: CardUI)

func _ready():
	original_scale = scale
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup_card(card):
	card_data = card
	update_display()

func update_display():
	if not card_data:
		return
	
	name_label.text = card_data.name
	energy_cost_label.text = str(card_data.energy_cost)
	type_label.text = card_data.type.capitalize()
	description_label.text = card_data.description
	
	# Set keywords
	if card_data.keywords.size() > 0:
		keywords_label.text = ", ".join(card_data.keywords)
		keywords_label.visible = true
	else:
		keywords_label.visible = false
	
	# Set card art if available
	if card_data.card_art and not card_data.card_art.is_empty():
		var texture = load(card_data.card_art)
		if texture:
			card_art.texture = texture
		else:
			card_art.texture = null
	else:
		card_art.texture = null
	
	# Update border color based on rarity
	update_rarity_display()

func update_rarity_display():
	if not card_data:
		return
	
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

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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