extends Area2D

@export var draggable := true
@onready var card_data
var root
var dragging := false
var drag_offset := Vector2.ZERO
var orig_pos = Vector2.ZERO
signal card_used(Area2D)
signal is_dragging(bool)

func _ready() -> void:
	root = get_parent().get_parent()

func _input_event(viewport, event, shape_idx):
	if not draggable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			emit_signal("is_dragging", true)
			orig_pos = global_position
			drag_offset = global_position - get_global_mouse_position()
		else:
			emit_signal("is_dragging", false)
			dragging = false
			try_drop()

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
	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		orig_pos,
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
