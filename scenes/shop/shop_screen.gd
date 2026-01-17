extends Control
class_name ShopScreen

## Shop Screen
## Offers 3 random cards for purchase
## Players can buy 0 or 1 card before returning to map

@onready var card1_container: Control = $CenterContainer/VBoxContainer/CardsContainer/Card1Container
@onready var card2_container: Control = $CenterContainer/VBoxContainer/CardsContainer/Card2Container
@onready var card3_container: Control = $CenterContainer/VBoxContainer/CardsContainer/Card3Container
@onready var gold_label: Label = $TopPanel/GoldLabel
@onready var back_button: Button = $TopPanel/BackButton
@onready var info_label: Label = $CenterContainer/VBoxContainer/InfoLabel
@onready var bottom_back_button: Button = $CenterContainer/VBoxContainer/BottomBackButton

const CARD_UI_SCENE: PackedScene = preload("res://scenes/cards/card_ui.tscn")

# Price ranges for each rarity
const PRICE_RANGES: Dictionary = {
	"common": {"min": 20, "max": 35},
	"uncommon": {"min": 45, "max": 65},
	"rare": {"min": 85, "max": 115},
	"legendary": {"min": 160, "max": 210}
}

var shop_cards: Array = []  # Array of {card: Card, price: int}
var card_purchased: bool = false


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	bottom_back_button.pressed.connect(_on_back_pressed)
	bottom_back_button.visible = false
	
	# Generate 3 random cards for the shop
	_generate_shop_inventory()
	
	# Update gold display
	_update_gold_display()
	
	info_label.text = "You can purchase one card"
	
	# Animate entrance
	_animate_entrance()


func _generate_shop_inventory() -> void:
	"""Generate 3 random cards with random prices based on rarity"""
	shop_cards.clear()
	
	# Get all available cards
	var all_cards: Array = CardDatabase.get_all_cards()
	
	if all_cards.size() < 3:
		push_error("Not enough cards in database for shop")
		return
	
	# Shuffle and pick 3 random cards
	all_cards.shuffle()
	
	for i in range(3):
		var card: Card = all_cards[i]
		var price: int = _get_random_price_for_rarity(card.rarity)
		
		shop_cards.append({
			"card": card,
			"price": price
		})
	
	# Display cards in containers
	_display_shop_cards()


func _get_random_price_for_rarity(rarity: String) -> int:
	"""Get a random price within the range for the given rarity"""
	if not PRICE_RANGES.has(rarity):
		return 50  # Default fallback
	
	var range_data: Dictionary = PRICE_RANGES[rarity]
	return randi_range(range_data["min"], range_data["max"])


func _display_shop_cards() -> void:
	"""Display the 3 shop cards in their containers"""
	var containers: Array = [card1_container, card2_container, card3_container]
	
	for i in range(min(3, shop_cards.size())):
		var container: Control = containers[i]
		var shop_item: Dictionary = shop_cards[i]
		var card: Card = shop_item["card"]
		var price: int = shop_item["price"]
		
		# Create card UI
		var card_ui: CardUI = CARD_UI_SCENE.instantiate()
		container.add_child(card_ui)
		card_ui.setup_card(card)
		
		# Connect card click to purchase
		card_ui.card_clicked.connect(_on_card_clicked.bind(i))
		
		# Create price label
		var price_label: Label = Label.new()
		price_label.name = "PriceLabel"
		price_label.text = str(price) + " Gold"
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 20)
		price_label.add_theme_color_override("font_color", Color.GOLD)
		price_label.add_theme_color_override("font_outline_color", Color.BLACK)
		price_label.add_theme_constant_override("outline_size", 4)
		container.add_child(price_label)
		
		# Position price label below card
		price_label.position = Vector2(0, card_ui.size.y + 10)
		price_label.size = Vector2(card_ui.size.x, 30)
		
		# Create buy button
		var buy_button: Button = Button.new()
		buy_button.name = "BuyButton"
		buy_button.text = "Buy"
		buy_button.custom_minimum_size = Vector2(100, 40)
		container.add_child(buy_button)
		
		# Position buy button below price
		buy_button.position = Vector2((card_ui.size.x - 100) / 2, card_ui.size.y + 50)
		
		# Add hover effect to card container
		_setup_card_hover_effect(container, card_ui)
		
		# Connect buy button
		buy_button.pressed.connect(_on_buy_card.bind(i))


func _setup_card_hover_effect(container: Control, card_ui: CardUI) -> void:
	"""Setup hover effect for shop cards"""
	container.mouse_entered.connect(func():
		if not card_purchased:
			var tween: Tween = create_tween()
			tween.set_trans(Tween.TRANS_BACK)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(container, "scale", Vector2(1.1, 1.1), 0.2)
			tween.parallel().tween_property(container, "position:y", container.position.y - 10, 0.2)
	)
	
	container.mouse_exited.connect(func():
		if not card_purchased:
			var tween: Tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.2)
			tween.parallel().tween_property(container, "position:y", container.position.y + 10, 0.2)
	)


func _on_card_clicked(card_ui: CardUI, card_index: int) -> void:
	"""Handle card click to purchase"""
	_on_buy_card(card_index)


func _on_buy_card(card_index: int) -> void:
	"""Handle purchasing a card"""
	if card_purchased:
		info_label.text = "You already purchased a card!"
		return
	
	var shop_item: Dictionary = shop_cards[card_index]
	var card: Card = shop_item["card"]
	var price: int = shop_item["price"]
	
	# Check if player has enough gold
	if GameState.player_gold < price:
		info_label.text = "Not enough gold!"
		return
	
	# Purchase card
	if GameState.spend_gold(price):
		# Add card to collection
		GameState.add_card_to_collection(card.id, 1)
		
		# Add card directly to deck
		DeckManager.add_card_to_deck(card.id)
		
		card_purchased = true
		
		# Animate success message
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		info_label.scale = Vector2(0.5, 0.5)
		tween.tween_property(info_label, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(info_label, "scale", Vector2(1.0, 1.0), 0.2)
		
		info_label.text = "Purchased: %s for %d gold!" % [card.name, price]
		info_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		
		# Update gold display
		_update_gold_display()
		
		# Hide purchased card and show back button
		_hide_purchased_card(card_index)
		
		# Gray out other cards
		_gray_out_other_cards(card_index)
		
		# Show bottom back button
		bottom_back_button.visible = true
		
		print("Card purchased: %s for %d gold" % [card.name, price])


func _hide_purchased_card(card_index: int) -> void:
	"""Hide the purchased card and its buy button"""
	var containers: Array = [card1_container, card2_container, card3_container]
	var container: Control = containers[card_index]
	
	# Hide all children (card, price label, buy button)
	for child in container.get_children():
		child.visible = false


func _gray_out_other_cards(purchased_index: int) -> void:
	"""Gray out and disable hover for cards that weren't purchased"""
	var containers: Array = [card1_container, card2_container, card3_container]
	
	for i in range(containers.size()):
		if i == purchased_index:
			continue
		
		var container: Control = containers[i]
		
		# Get card UI and disable it
		var card_ui: CardUI = container.get_node_or_null("CardUI")
		if card_ui:
			card_ui.modulate = Color(0.4, 0.4, 0.4, 0.7)
			card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Hide buy button
		var buy_button: Button = container.get_node_or_null("BuyButton")
		if buy_button:
			buy_button.visible = false


func _update_gold_display() -> void:
	"""Update the gold label"""
	gold_label.text = "Gold: %d" % GameState.player_gold


func _on_back_pressed() -> void:
	"""Return to map screen"""
	get_tree().change_scene_to_file("res://scenes/map_system/map_screen.tscn")


func _animate_entrance() -> void:
	"""Animate the cards appearing"""
	var containers: Array = [card1_container, card2_container, card3_container]
	
	for i in range(containers.size()):
		var container: Control = containers[i]
		container.modulate.a = 0.0
		container.scale = Vector2(0.3, 0.3)
		
		# Stagger the animations
		await get_tree().create_timer(0.15 * i).timeout
		
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(container, "modulate:a", 1.0, 0.4)
		tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.5)
