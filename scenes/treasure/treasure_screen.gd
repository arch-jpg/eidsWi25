extends Control
class_name TreasureScreen

## Treasure screen with CS:GO-style card opening animation
## Shows cards scrolling from left to right and stops at the drawn card

@onready var card_container: HBoxContainer = $CenterContainer/CardScrollArea/CardContainer
@onready var scroll_area: ScrollContainer = $CenterContainer/CardScrollArea
@onready var center_marker: Control = $CenterContainer/CenterMarker
@onready var title_label: Label = $TitleLabel
@onready var continue_button: Button = $ContinueButton
@onready var start_button: Button = $StartButton

const CARD_UI_SCENE: PackedScene = preload("res://scenes/cards/card_ui.tscn")

var all_available_cards: Array = []
var drawn_card_id: String = ""
var is_animating: bool = false

# Animation settings
const SCROLL_DURATION: float = 5.0
const CARD_SPACING: float = 259.0  # Card width (254) + separation (5)
const NUM_DUMMY_CARDS: int = 25


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.disabled = true
	continue_button.visible = false

	center_marker.visible = false
	
	
	start_button.pressed.connect(_on_start_button_pressed)
	
	# Wait for next frame
	await get_tree().process_frame


func _on_start_button_pressed() -> void:
	start_button.visible = false
	start_button.disabled = true

	center_marker.visible = true
	
	# Animate title with bounce effect
	var title_tween: Tween = create_tween()
	title_tween.set_trans(Tween.TRANS_ELASTIC)
	title_tween.set_ease(Tween.EASE_OUT)
	title_label.scale = Vector2(0.5, 0.5)
	title_label.modulate.a = 0.0
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.8)
	title_tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.6)

	title_label.text = "Opening Treasure..."
	start_card_draw()


func start_card_draw() -> void:
	is_animating = true
	
	# Get all available cards from database
	var all_cards: Array = CardDatabase.get_all_cards()
	
	if all_cards.is_empty():
		push_error("No cards available in database")
		return
	
	# Extract card IDs
	all_available_cards.clear()
	for card in all_cards:
		all_available_cards.append(card.id)
	
	# Pick the card that will be drawn
	drawn_card_id = all_available_cards[randi() % all_available_cards.size()]
	
	# Create card sequence
	_create_card_sequence()
	
	# Wait a frame for layout
	await get_tree().process_frame
	
	# Start scroll animation
	_animate_scroll()


func _create_card_sequence() -> void:
	# Clear existing cards
	for child in card_container.get_children():
		child.queue_free()
	
	# Create random cards before the drawn card
	for i in range(NUM_DUMMY_CARDS):
		var random_card_id: String = all_available_cards[randi() % all_available_cards.size()]
		_add_card_to_container(random_card_id)
	
	# Add the actual drawn card in the middle
	_add_card_to_container(drawn_card_id)
	
	# Add more random cards after
	for i in range(NUM_DUMMY_CARDS):
		var random_card_id: String = all_available_cards[randi() % all_available_cards.size()]
		_add_card_to_container(random_card_id)


func _add_card_to_container(card_id: String) -> void:
	var card: Card = CardDatabase.get_card_by_id(card_id)
	if not card:
		return
	
	var card_ui: Control = CARD_UI_SCENE.instantiate()
	card_container.add_child(card_ui)
	card_ui.setup_card(card)
	card_ui.scale = Vector2(0.8, 0.8)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Disable hover effects


func _animate_scroll() -> void:
	# Calculate target scroll position (center the drawn card)
	var target_card_index: int = NUM_DUMMY_CARDS
	var target_scroll: float = target_card_index * CARD_SPACING
	
	# Center it in the viewport
	var viewport_center: float = scroll_area.size.x / 2.0
	var card_center_offset: float = 127.0  # Half of card width (254/2)
	target_scroll = target_scroll - viewport_center + card_center_offset
	
	# Start from left
	scroll_area.scroll_horizontal = 0
	
	# Animate scroll with easing
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll_area, "scroll_horizontal", int(target_scroll), SCROLL_DURATION)
	
	# Wait for animation to finish
	await tween.finished
	
	# Animation complete
	is_animating = false
	_on_card_revealed()


func _on_card_revealed() -> void:
	# Add card to player's collection and deck
	GameState.add_card_to_collection(drawn_card_id)
	DeckManager.add_card_to_deck(drawn_card_id)
	
	center_marker.visible = false

	# Hide dummy cards and highlight the drawn card
	await _highlight_drawn_card()
	
	

	# Update UI with celebration animation
	var title_tween: Tween = create_tween()
	title_tween.set_trans(Tween.TRANS_BOUNCE)
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.tween_property(title_label, "scale", Vector2(1.2, 1.2), 0.3)
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.2)
	
	title_label.text = "Card Obtained!"
	title_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	
	continue_button.disabled = false
	continue_button.visible = true


func _highlight_drawn_card() -> void:
	"""Hide dummy cards and highlight the drawn card"""
	var all_cards: Array = card_container.get_children()
	var drawn_card_index: int = NUM_DUMMY_CARDS
	
	# Get the drawn card before fading
	var drawn_card: Control = all_cards[drawn_card_index]
	
	# Fade out and shrink all dummy cards
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_IN)
	
	for i in range(all_cards.size()):
		if i != drawn_card_index:
			var card: Control = all_cards[i]
			fade_tween.tween_property(card, "modulate:a", 0.0, 0.5)
			fade_tween.tween_property(card, "scale", Vector2(0.3, 0.3), 0.5)
	
	await fade_tween.finished
	
	# Disable scrolling
	scroll_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Calculate center position of the screen
	var viewport_center: Vector2 = get_viewport_rect().size / 2.0
	
	# Get the current global position of the drawn card
	var card_global_pos: Vector2 = drawn_card.global_position
	var card_size: Vector2 = drawn_card.size * drawn_card.scale
	var card_center: Vector2 = card_global_pos + card_size / 2.0
	
	# Calculate offset needed to center the card
	var offset_needed: Vector2 = viewport_center - card_center
	
	# Reparent card to main control for absolute positioning
	var original_scale: Vector2 = drawn_card.scale
	var original_global_pos: Vector2 = drawn_card.global_position
	
	drawn_card.reparent(self)
	drawn_card.global_position = original_global_pos
	drawn_card.scale = original_scale
	
	# Animate the drawn card to center and enlarge
	var highlight_tween: Tween = create_tween()
	highlight_tween.set_trans(Tween.TRANS_BACK)
	highlight_tween.set_ease(Tween.EASE_OUT)
	highlight_tween.set_parallel(true)
	
	# Move to center and scale up
	highlight_tween.tween_property(drawn_card, "global_position", viewport_center - (drawn_card.size * 1.5 / 2.0), 0.6)
	highlight_tween.tween_property(drawn_card, "scale", Vector2(1.5, 1.5), 0.6)
	
	# Add a glow effect by modulating
	highlight_tween.tween_property(drawn_card, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.3)
	highlight_tween.tween_property(drawn_card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3).set_delay(0.3)
	
	await highlight_tween.finished
	
	print("Treasure: Drew card %s and added to deck" % drawn_card_id)


func _on_continue_pressed() -> void:
	# Return to map
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")
