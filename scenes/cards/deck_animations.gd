extends Node2D

# Animation settings
var card_delay_between_draws: float = 0.3  # Delay in seconds between each card draw
var card_move_distance: float = 250.0  # How far down the card moves in pixels
var card_move_duration: float = 0.5  # Duration of the move animation in seconds
var card_fade_duration: float = 0.3  # Duration of the fade out animation in seconds
var card_fade_delay: float = 0.3  # Delay before starting the fade out in seconds
var default_deck_position: Vector2 = Vector2(138, 201)  # Fallback deck position

# Preload card back texture
var card_back_texture = preload("res://data/assets/cards/card_back.png")

# Reference to the deck sprite
@onready var card_deck = $CardDeck

# Draw multiple cards with animation
func draw_cards(count: int) -> void:
	for i in range(count):
		# Stagger the animation for each card
		await get_tree().create_timer(card_delay_between_draws).timeout
		_spawn_draw_animation()

# Spawn and animate a single card being drawn
func _spawn_draw_animation() -> void:
	# Create a new sprite for the card back
	var card_sprite = Sprite2D.new()
	card_sprite.texture = card_back_texture
	
	# Position it at the deck location
	if card_deck:
		card_sprite.position = card_deck.position
	else:
		card_sprite.position = default_deck_position
	
	# Add to scene
	add_child(card_sprite)
	
	# Animate the card moving down
	var tween = create_tween()
	tween.set_parallel(false)
	
	# Move down
	tween.tween_property(card_sprite, "position:y", card_sprite.position.y + card_move_distance, card_move_duration)
	
	# Fade out near the end
	tween.parallel().tween_property(card_sprite, "modulate:a", 0.0, card_fade_duration).set_delay(card_fade_delay)
	
	# Remove the sprite when animation is done
	tween.tween_callback(func(): card_sprite.queue_free())
