extends StaticBody2D
class_name BaseBuilding

# Base Building - AoE style

signal building_selected(building)
signal building_deselected(building)
signal building_destroyed(building)
signal unit_queued(unit_type: String)
signal unit_produced(unit_type: String)

enum BuildingState {
	CONSTRUCTING,
	ACTIVE,
	DESTROYED
}

@export var building_type: String = "house"
@export var faction: int = 0 # 0 player, 1 enemy

var max_hp: int = 500
var hp: int = 500
var state: BuildingState = BuildingState.ACTIVE
var is_selected: bool = false

var construction_progress: float = 0.0
var construction_time: float = 5.0

# Production queue
var production_queue: Array = []
var production_progress: float = 0.0
var current_production: String = ""

var rally_point: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var selection_indicator: Node2D
var health_bar: ProgressBar

func _ready():
	add_to_group("buildings")
	if faction == 0:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")
	
	if TechTree.building_stats.has(building_type):
		var stats = TechTree.building_stats[building_type]
		max_hp = stats.get("hp", 500)
		hp = max_hp
	
	_setup_visuals()
	rally_point = global_position + Vector2(80, 80)
	print("Building spawned: %s at %s" % [building_type, global_position])

func _setup_visuals():
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	var tex_path = "res://assets/sprites/buildings/%s.png" % building_type
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	
	selection_indicator = Node2D.new()
	selection_indicator.name = "Selection"
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	var sel = Sprite2D.new()
	sel.name = "Circle"
	if ResourceLoader.exists("res://assets/ui/selection_circle.png"):
		sel.texture = load("res://assets/ui/selection_circle.png")
		sel.scale = Vector2(2, 1)
	selection_indicator.add_child(sel)
	
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(60, 8)
	health_bar.position = Vector2(-30, -60)
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.show_percentage = false
	health_bar.visible = false
	add_child(health_bar)

func _process(delta):
	if state == BuildingState.CONSTRUCTING:
		construction_progress += delta
		if construction_progress >= construction_time:
			state = BuildingState.ACTIVE
			construction_progress = construction_time
		return
	
	if state != BuildingState.ACTIVE:
		return
	
	# Production
	if production_queue.size() > 0 and current_production == "":
		current_production = production_queue[0]
		production_progress = 0.0
	
	if current_production != "":
		production_progress += delta
		var build_time = _get_unit_build_time(current_production)
		if production_progress >= build_time:
			_produce_unit(current_production)
			production_queue.pop_front()
			current_production = ""
			production_progress = 0.0
	
	# Update health bar
	if health_bar:
		health_bar.value = hp
		health_bar.visible = hp < max_hp or is_selected

func queue_unit(unit_type: String) -> bool:
	if not _can_produce(unit_type):
		return false
	
	var cost = TechTree.unit_stats.get(unit_type, {}).get("cost", {})
	if not ResourceManager.can_afford(cost):
		return false
	
	if not GameManager.can_add_population(1):
		print("Population cap reached")
		return false
	
	if not ResourceManager.spend_resources(cost):
		return false
	
	production_queue.append(unit_type)
	emit_signal("unit_queued", unit_type)
	print("Queued unit: %s at %s" % [unit_type, building_type])
	return true

func _can_produce(unit_type: String) -> bool:
	# Check building can produce this unit
	var mapping = {
		"town_hall": ["villager"],
		"barracks": ["swordsman"],
		"archery": ["archer"],
		"stable": ["knight"],
		"mage_tower": ["mage", "golem", "dragon", "healer"],
		"market": [],
		"house": [],
		"wall": [],
		"lumber_camp": []
	}
	
	if not mapping.has(building_type):
		return false
	
	if unit_type not in mapping[building_type]:
		# Town hall can produce all in mythic? For simplicity allow
		if building_type == "town_hall" and TechTree.current_age >= TechTree.Age.MYTHIC:
			return true
		return false
	
	if not TechTree.is_unit_unlocked(unit_type):
		return false
	
	return true

func _get_unit_build_time(unit_type: String) -> float:
	var times = {
		"villager": 8.0,
		"swordsman": 10.0,
		"archer": 12.0,
		"knight": 15.0,
		"healer": 14.0,
		"mage": 18.0,
		"golem": 25.0,
		"dragon": 40.0
	}
	return times.get(unit_type, 10.0)

func _produce_unit(unit_type: String):
	# Instance unit - will be handled by GameManager or World
	emit_signal("unit_produced", unit_type)
	GameManager.add_population(1)
	GameManager.units_trained += 1
	print("Produced unit: %s" % unit_type)
	
	# Spawn unit near building
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("spawn_unit"):
		world.spawn_unit(unit_type, global_position + Vector2(randf_range(40,80), randf_range(40,80)), faction)

func take_damage(amount: int):
	hp -= amount
	hp = max(0, hp)
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1,0.5,0.5), 0.05)
		tween.tween_property(sprite, "modulate", Color(1,1,1), 0.1)
	
	if hp <= 0:
		destroy()

func destroy():
	state = BuildingState.DESTROYED
	emit_signal("building_destroyed", self)
	
	if building_type == "house":
		GameManager.add_max_population(-TechTree.building_stats["house"]["pop"])
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.8)
	tween.tween_callback(queue_free)

func select():
	is_selected = true
	if selection_indicator:
		selection_indicator.visible = true
	if health_bar:
		health_bar.visible = true
	emit_signal("building_selected", self)

func deselect():
	is_selected = false
	if selection_indicator:
		selection_indicator.visible = false
	if health_bar and hp == max_hp:
		health_bar.visible = false
	emit_signal("building_deselected", self)

func get_production_progress() -> float:
	if current_production == "":
		return 0.0
	var total = _get_unit_build_time(current_production)
	return production_progress / total if total > 0 else 0

func set_rally_point(pos: Vector2):
	rally_point = pos
