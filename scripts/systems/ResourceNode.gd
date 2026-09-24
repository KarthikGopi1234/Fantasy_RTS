extends StaticBody2D
class_name ResourceNode

@export var resource_type: String = "wood"
@export var amount: int = 500
@export var max_amount: int = 500

var sprite: Sprite2D
var is_depleted: bool = false

func _ready():
	add_to_group("resources")
	max_amount = amount
	_setup_visuals()

func _setup_visuals():
	sprite = Sprite2D.new()
	add_child(sprite)
	
	var tex_path = "res://assets/sprites/tiles/%s.png" % _get_tile_name()
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	
	# Label for amount
	var label = Label.new()
	label.name = "AmountLabel"
	label.text = str(amount)
	label.position = Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

func _get_tile_name() -> String:
	match resource_type:
		"wood": return "forest"
		"gold": return "gold_vein"
		"stone": return "stone"
		"mana": return "mana_crystal"
		"food": return "grass"
		_: return "grass"

func gather(requested: int) -> int:
	if is_depleted:
		return 0
	
	var gathered = min(requested, amount)
	amount -= gathered
	
	if amount <= 0:
		deplete()
	
	# Update label
	var label = get_node_or_null("AmountLabel")
	if label:
		label.text = str(amount)
	
	return gathered

func deplete():
	is_depleted = true
	modulate = Color(0.5,0.5,0.5,0.6)
	print("Resource depleted: %s" % resource_type)
	# Could queue_free after delay
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(self, "modulate", Color(0.3,0.3,0.3,0), 1.0)
	tween.tween_callback(queue_free)
