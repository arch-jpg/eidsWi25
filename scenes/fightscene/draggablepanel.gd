extends Panel
@export var panel_value: int = 2   # The number this panel represents

var card_data: Card
var dragging := false
var drag_offset := Vector2.ZERO
var home_position := Vector2.ZERO
var drop_target            # The Area2D we might drop onto

func _ready():
	home_position = position
	self.card_data = CardDatabase.get_random_card()
	$cardname.text = card_data["name"]

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
			else:
				dragging = false
				try_drop()
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset

func _process(delta):
	if !dragging:
		# Lerp smoothly back to original spot
		position = position.lerp(home_position, delta * 10.0)

func play_card_on_enemy(enemy):
	
	for effect in card_data["effects"]:
		if effect["type"] == "damage":
			var amount = effect["value"]
			enemy.apply_damage(amount)

func try_drop():
	if !drop_target:
		return
# check if the drop target is an enemy
	if drop_target.is_in_group("enemy"):
		play_card_on_enemy(drop_target)
		hide_card()
	else:
		invalid_drop()
		print("Invalid target for this card.")
		
func invalid_drop():
	$cardname.modulate = Color(1.0,0.3,0.3,0.3)
	await get_tree().create_timer(0.15).timeout
	$cardname.modulate = Color(1, 1, 1, 1)     # reset

func hide_card():
	hide()
	pass
