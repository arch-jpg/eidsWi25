class_name CardData extends Resource

enum Type {
	ATTACK,
	DEFENSE,
	HEAL
}

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var cost: int
@export var icon: Texture2D
@export var type: Type = Type.ATTACK # Attack is base value

# funkton is implementet for each card 
func apply_effect(target: Node, user: Node):
	print("Effekt ausgelöst")
