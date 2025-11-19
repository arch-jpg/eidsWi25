extends Control
class_name CardUI

var card_data: CardData

@onready var name_label = $Name
@onready var cost_label = $Cost
@onready var description_label = $Description 
@onready var icon_texture = $CardImage
@onready var background_texture = $Background
#const BG_ATTACK = preload("") 
#const BG_DEFENSE = preload("")
#const BG_HEAL = preload("")

signal card_played(card: CardUI)

var is_hovered = false
var is_dragging = false
var start_position = Vector2()
var offset_from_mouse = Vector2() 


# set card data for card ui
func set_card(data: CardData):
	card_data = data
	name_label.text = data.display_name
	cost_label.text = str(data.cost)
	description_label.text = data.description 
	
	if data.icon:
		icon_texture.texture = data.icon
		
	#match data.type:
		#CardData.Type.ATTACK: # oder "Attack", wenn du String nutzt
			#background_texture.texture = BG_ATTACK
		#CardData.Type.DEFENSE:
			#background_texture.texture = BG_DEFENSE

# increases the card size from the middle
func _ready():
	pivot_offset = size/2

func _gui_input(event):
	# grab card and remember position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			start_position = position 
			offset_from_mouse = global_position - get_global_mouse_position()
			z_index = 100 # to get it in a higher layer

func _input(event):
	# checks for mouse inputs
	if not is_dragging:
		return
		
	# moves card on click
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + offset_from_mouse
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			# stop holding -> try play card or reset card
			is_dragging = false
			z_index = 0 
			_try_play_card()

func _on_mouse_entered():
	# increases the card size
	if not is_dragging: 
		is_hovered = true
		scale = Vector2(1.2, 1.2)
		z_index = 10

func _on_mouse_exited():
	# reset card size
	if not is_dragging:
		is_hovered = false
		scale = Vector2(1.0, 1.0)
		z_index = 0

func _try_play_card():
	# logic missing
	# cant play card -> back to hand
	var tween = create_tween()
	# Easing smoths card movement
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", start_position, 0.3)
