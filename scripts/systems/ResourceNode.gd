extends StaticBody2D
class_name ResourceNode

# ResourceNode - Idle Edition
# Tap to collect small bonus, auto-gen is via buildings

@export var resource_type: String = "wood"
@export var amount: int = 500
@export var max_amount: int = 500

var sprite: Sprite2D
var is_depleted: bool = false
var tap_cooldown: float = 0.0

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
	else:
		# Fallback colored
		var img = Image.create(48,48,false,Image.FORMAT_RGBA8)
		var col = Color(0.2,0.8,0.2)
		match resource_type:
			"wood": col = Color(0.3,0.6,0.2)
			"gold": col = Color(0.9,0.8,0.1)
			"stone": col = Color(0.6,0.6,0.6)
			"mana": col = Color(0.4,0.2,0.9)
		img.fill(col)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
	
	# Amount label
	var label = Label.new()
	label.name = "AmountLabel"
	label.text = resource_type.capitalize()
	label.position = Vector2(-30, -40)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

func _process(delta):
	if tap_cooldown > 0:
		tap_cooldown -= delta

func _get_tile_name() -> String:
	match resource_type:
		"wood": return "forest"
		"gold": return "gold_vein"
		"stone": return "stone"
		"mana": return "mana_crystal"
		"food": return "grass"
		_: return "grass"

func on_tap() -> int:
	if tap_cooldown > 0:
		return 0
	tap_cooldown = 0.5
	var gathered = randi_range(2,5)
	ResourceManager.add_resource_with_fx(resource_type, gathered, global_position)
	# Tap effect
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3,1.3), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0,1.0), 0.1)
	
	# Update quest
	var im = get_node_or_null("/root/IdleManager")
	if im:
		im.update_quest_progress("collect_gold", gathered if resource_type == "gold" else 0)
		im.register_tap(global_position)
	
	return gathered

# Legacy gather method
func gather(requested: int) -> int:
	if is_depleted:
		return 0
	var gathered = min(requested, amount)
	amount -= gathered
	if amount <= 0:
		deplete()
	return gathered

func deplete():
	is_depleted = true
	modulate = Color(0.5,0.5,0.5,0.6)
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(self, "modulate", Color(0.3,0.3,0.3,0), 1.0)
	tween.tween_callback(queue_free)
