extends Area2D

@export var draggable := true
@onready var card_data
var root
var dragging := false
var drag_offset := Vector2.ZERO
var orig_pos = Vector2.ZERO
var hand_container
var is_hovered := false
var original_z_index := 0
signal card_used(Area2D)
signal is_dragging(bool)

static var currently_dragging_card = null

func _ready() -> void:
	root = get_parent().get_parent()
	hand_container = get_parent()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if dragging or currently_dragging_card != null:
		return
	
	is_hovered = true
	original_z_index = z_index
	z_index = 100  # Bring to front while hovering
	
	var card_ui = get_node_or_null("CardUI")
	if card_ui:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card_ui, "scale", Vector2(1.15, 1.15), 0.2)
		tween.tween_property(self, "position:y", position.y - 30, 0.2)

func _on_mouse_exited() -> void:
	if dragging:
		return
	
	is_hovered = false
	z_index = original_z_index
	
	var card_ui = get_node_or_null("CardUI")
	if card_ui:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card_ui, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(self, "position:y", position.y + 30, 0.2)

func _input_event(_viewport, event, _shape_idx):
	if not draggable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if another card is already being dragged
			if currently_dragging_card != null:
				return
			
			# Check if this is the topmost card
			if not is_topmost_card():
				return
			
			currently_dragging_card = self
			dragging = true
			is_hovered = false
			
			# Reset hover effects when starting drag
			var card_ui = get_node_or_null("CardUI")
			if card_ui:
				card_ui.scale = Vector2(1.0, 1.0)
			
			emit_signal("is_dragging", true)
			z_index = original_z_index
			orig_pos = global_position
			drag_offset = global_position - get_global_mouse_position()
		else:
			if currently_dragging_card == self:
				emit_signal("is_dragging", false)
				dragging = false
				currently_dragging_card = null
				z_index = original_z_index
				try_drop()

func is_topmost_card() -> bool:
	if not hand_container:
		return true
	
	var my_z = z_index
	var mouse_pos = get_global_mouse_position()
	
	# Check all sibling cards in the hand
	for sibling in hand_container.hand_cards:
		if sibling == self:
			continue
		
		# Check if sibling is also under the mouse and has higher z_index
		var sibling_rect = Rect2(sibling.global_position - Vector2(127, 192), Vector2(254, 384))
		if sibling_rect.has_point(mouse_pos) and sibling.z_index > my_z:
			return false
	
	return true

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + drag_offset
		
func try_drop():
	for target in get_overlapping_areas():
		if target.is_in_group("enemies") and root.energy_count>=card_data["energy_cost"]:
			if target.dropped_on(card_data):
				root.energy_count-=card_data["energy_cost"]
				root.get_child(2).text=str(root.energy_count)
				card_used.emit(self)
				hide()
				global_position= Vector2(0,0)
				return
				
		if target.is_in_group("player") and root.energy_count>=card_data["energy_cost"]:
			if target.dropped_on(card_data):
				root.energy_count-=card_data["energy_cost"]
				root.get_child(2).text=str(root.energy_count)
				card_used.emit(self)
				hide()
				global_position = Vector2(0,0)
				return
	
	snap_back()
	
func snap_back():
	# Get the current target position from hand layout
	if hand_container and hand_container.hand_cards.has(self):
		var hand_size = hand_container.hand_cards.size()
		var index = hand_container.hand_cards.find(self)
		
		if index >= 0:
			var center: float = (hand_size - 1) * 0.5
			var offset: float = index - center
			
			var target_pos = hand_container.global_position
			target_pos.x += offset * hand_container.spacing + 160
			target_pos.y += hand_container.base_lift + abs(offset) * hand_container.fan_lift + 140
			
			var snap_tween := create_tween()
			snap_tween.set_trans(Tween.TRANS_CUBIC)
			snap_tween.set_ease(Tween.EASE_OUT)
			snap_tween.tween_property(self, "global_position", target_pos, 0.25)
			return
	
	# Fallback to original position if hand container not found
	var fallback_tween := create_tween()
	fallback_tween.tween_property(
		self,
		"global_position",
		orig_pos,
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
