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
	
	# Update UI
	title_label.text = "Card Obtained!"
	continue_button.disabled = false
	continue_button.visible = true
	
	print("Treasure: Drew card %s and added to deck" % drawn_card_id)


func _on_continue_pressed() -> void:
	# Return to map
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")
