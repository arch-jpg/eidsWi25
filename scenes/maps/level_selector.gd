extends Area2D

@export var required_levels : Array[String] = []
@export var enemy_1_id : String = ""
@export var enemy_2_id : String = ""
@export var enemy_3_id : String = ""

const SAVE_PATH = "user://player.save"

var is_clickable: bool = false
var level_id: String = ""

func _ready():
	level_id = name  # e.g. "Lvl100", "Lvl111", etc.
	update_clickable_state()
	update_visual_state()
	

func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_clickable:
			on_level_clicked()

func on_level_clicked():
	"""Level was clicked - save and load"""
	print("Level selected: " + level_id)
	
	save_completed_level()
	# Load combat scene or level here
	GameState.setup_combat(level_id, [enemy_1_id, enemy_2_id, enemy_3_id])
	get_tree().change_scene_to_file("res://scenes/fightscene/combat_scene.tscn")

func update_clickable_state():
	"""Checks if this level should be clickable"""
	var save_data = load_save_data()
	
	# Start-Level 
	#  if required_levels.size() == 0 and (save_data.has("last_completed_level") == null or save_data["last_completed_level"] == ""):
	if required_levels.size() == 0 and (not save_data.has("last_completed_level") or save_data.get("last_completed_level", "") == ""):
		is_clickable = true
		return
	
	# Check if the previous level was completed
	if save_data.has("last_completed_level"):
		var last_level_name = save_data["last_completed_level"]
		if required_levels.has(last_level_name):
			is_clickable = true
	else:
		is_clickable = false

	#  if save_data.has("last_completed_level") and save_data["last_completed_level"].ends_with("XX"):
	var last_level = save_data.get("last_completed_level", "")
	if last_level is String and last_level.ends_with("XX"):
		is_clickable = false  # Bereits abgeschlossen
		print("MAP ABGESCHLOSSEN: " + level_id)

func update_visual_state():
	#ACHTUNG TOTE FUNKTION IDK MAN
	"""Updates the visual representation based on clickability"""
	# CollisionShape2D haben keine modulate-Eigenschaft die sichtbar ist
	# You must either add Sprites as children or solve the visualization differently
	for child in get_children():
		if child is CollisionShape2D:
			# Debug-Farbe (nur in Editor/Debug sichtbar)
			child.debug_color = Color.GREEN if is_clickable else Color.RED
	
	# If you add Sprites later, use this:
	# for child in get_children():
	#     if child is Sprite2D:
	#         child.modulate = Color.WHITE if is_clickable else Color(0.3, 0.3, 0.3, 1.0)
	
func save_completed_level():
	# TODO: Consider moving this function to a more appropriate location
	"""Saves this level as last completed"""
	var save_data = load_save_data()
	save_data["last_completed_level"] = level_id

	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(save_data))
		file.close()
		print("Saved completed level: " + level_id)
	else:
		push_error("Could not save to " + SAVE_PATH)

func load_save_data() -> Dictionary:
	"""Loads the save data"""
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			return json.data
	
	return {}
