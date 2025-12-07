class_name CardEffect
extends Resource

"""
Represents a single effect that a card can have
Used for damage, healing, status effects, etc.
"""

@export var type: String  # damage, heal, block, status_effect, etc.
@export var element: String  # fire, ice, lightning, physical, etc. rn standard only!
@export var value: int
@export var target: String  # self, selected_enemy, all_enemies, etc.
@export var effect_name: String  # for status effects
@export var duration: int  # for temporary effects
@export var conditional: Dictionary  # for conditional effects

func _init(effect_data: Dictionary = {}):
	if effect_data.is_empty():
		return
		
	type = effect_data.get("type", "")
	element = effect_data.get("element", "")
	value = effect_data.get("value", 0)
	target = effect_data.get("target", "")
	effect_name = effect_data.get("effect_name", "")
	duration = effect_data.get("duration", 0)
	conditional = effect_data.get("conditional", {})

func get_effect_type() -> String:
	return type

func get_value() -> int:
	return value

func get_target() -> String:
	return target

func has_conditional() -> bool:
	return not conditional.is_empty()

func get_conditional() -> Dictionary:
	return conditional

func is_damage_effect() -> bool:
	return type == "damage"

func is_heal_effect() -> bool:
	return type == "heal"

func is_status_effect() -> bool:
	return type == "status_effect"

func is_block_effect() -> bool:
	return type == "block"

func get_element() -> String:
	return element

func get_effect_name() -> String:
	return effect_name

func get_duration() -> int:
	return duration

func duplicate_effect() -> CardEffect:
	var new_effect = CardEffect.new()
	new_effect.type = type
	new_effect.element = element
	new_effect.value = value
	new_effect.target = target
	new_effect.effect_name = effect_name
	new_effect.duration = duration
	new_effect.conditional = conditional.duplicate()
	return new_effect

func get_description() -> String:
	match type:
		"damage":
			if element.is_empty() or element == "standard":
				return "Deal %d damage" % value
			else:
				return "Deal %d %s damage" % [value, element.capitalize()]
		"heal":
			return "Restore %d Health" % value
		"block":
			return "Gain %d Block" % value
		"status_effect":
			if duration > 0:
				return "Apply %s for %d turns" % [effect_name.capitalize(), duration]
			else:
				return "Apply %s" % effect_name.capitalize()
		"draw_cards":
			return "Draw %d cards" % value
		"energy":
			return "Gain %d Energy" % value
		_:
			return "Unknown effect"