extends StaticBody2D
class_name BaseBuilding

# BaseBuilding - Idle Auto-Battler Edition
# Auto-generates resources, auto-queues units, tap for bonuses

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
var construction_time: float = 2.0 # Faster for idle

# Production queue - idle auto-queue
var production_queue: Array = []
var production_progress: float = 0.0
var current_production: String = ""
var production_speed_multiplier: float = 1.0

# Idle generation
var idle_gen: Dictionary = {}

var sprite: Sprite2D
var selection_indicator: Node2D
var health_bar: ProgressBar
var progress_bar: ProgressBar
var level: int = 1
var gen_timer: float = 0.0

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
		idle_gen = stats.get("gen", {}).duplicate()
	
	# Apply prestige bonuses
	var im = get_node_or_null("/root/IdleManager")
	if im:
		var lvl = im.get_prestige_upgrade_level("master_builder")
		production_speed_multiplier = 1.0 + lvl * 0.2
	
	_setup_visuals()
	print("Idle Building spawned: %s at %s gen %s" % [building_type, global_position, idle_gen])

func _setup_visuals():
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	var tex_path = "res://assets/sprites/buildings/%s.png" % building_type
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		# Fallback
		var img = Image.create(96, 96, false, Image.FORMAT_RGBA8)
		var col = Color(0.6, 0.4, 0.2)
		match building_type:
			"town_hall": col = Color(0.8, 0.6, 0.2)
			"house": col = Color(0.5, 0.7, 0.5)
			"barracks": col = Color(0.7, 0.2, 0.2)
			"archery": col = Color(0.2, 0.7, 0.2)
			"stable": col = Color(0.8, 0.7, 0.2)
			"mage_tower": col = Color(0.5, 0.2, 0.8)
			"wall": col = Color(0.5, 0.5, 0.5)
			"market": col = Color(0.9, 0.8, 0.2)
		img.fill(col)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
	
	sprite.scale = Vector2(1.0, 1.0)
	
	selection_indicator = Node2D.new()
	selection_indicator.name = "Selection"
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	# Health bar
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(70, 8)
	health_bar.position = Vector2(-35, -60)
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.show_percentage = false
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0,0,0,0.5)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2
	style_bg.corner_radius_bottom_right = 2
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.2, 0.9, 0.2)
	style_fg.corner_radius_top_left = 2
	style_fg.corner_radius_top_right = 2
	style_fg.corner_radius_bottom_left = 2
	style_fg.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", style_bg)
	health_bar.add_theme_stylebox_override("fill", style_fg)
	add_child(health_bar)
	
	# Production progress bar
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.size = Vector2(70, 6)
	progress_bar.position = Vector2(-35, -50)
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	var style_bg2 = StyleBoxFlat.new()
	style_bg2.bg_color = Color(0,0,0,0.4)
	var style_fg2 = StyleBoxFlat.new()
	style_fg2.bg_color = Color(0.2, 0.6, 1.0)
	progress_bar.add_theme_stylebox_override("background", style_bg2)
	progress_bar.add_theme_stylebox_override("fill", style_fg2)
	progress_bar.visible = false
	add_child(progress_bar)

func _process(delta):
	if state == BuildingState.CONSTRUCTING:
		construction_progress += delta
		if construction_progress >= construction_time:
			state = BuildingState.ACTIVE
			construction_progress = construction_time
			_on_construction_complete()
		return
	
	if state != BuildingState.ACTIVE:
		return
	
	# Idle resource generation
	_process_idle_generation(delta)
	
	# Production
	_process_production(delta)
	
	# Update health bar
	if health_bar:
		health_bar.value = hp
		health_bar.visible = hp < max_hp or is_selected

func _on_construction_complete():
	# Recalc global gen
	ResourceManager.recalc_building_gen()
	# Visual pop
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

func _process_idle_generation(delta):
	if idle_gen.size() == 0:
		return
	gen_timer += delta
	if gen_timer >= 1.0:
		gen_timer = 0.0
		for res_type in idle_gen.keys():
			var amount = idle_gen[res_type] * level
			# Apply tech bonuses via ResourceManager modifiers
			amount *= ResourceManager.gather_modifiers.get(res_type, 1.0)
			if amount >= 1.0:
				ResourceManager.add_resource(res_type, int(amount))
			else:
				# fractional handled by ResourceManager buffer via add_building_generation? For now accumulate
				ResourceManager._add_fractional(res_type, amount)

func _process_production(delta):
	# Start next in queue
	if production_queue.size() > 0 and current_production == "":
		current_production = production_queue[0]
		production_progress = 0.0
		if progress_bar:
			progress_bar.visible = true
	
	if current_production != "":
		production_progress += delta * production_speed_multiplier
		var build_time = _get_unit_build_time(current_production)
		# Tech speed bonus
		if TechTree.techs.has("auto_queue_2") and TechTree.techs["auto_queue_2"]["researched"]:
			build_time *= 0.8
		
		if progress_bar:
			progress_bar.value = production_progress / build_time
		
		if production_progress >= build_time:
			_produce_unit(current_production)
			production_queue.pop_front()
			current_production = ""
			production_progress = 0.0
			if progress_bar:
				progress_bar.visible = production_queue.size() > 0

func queue_unit(unit_type: String) -> bool:
	if not _can_produce(unit_type):
		return false
	
	var cost = TechTree.unit_stats.get(unit_type, {}).get("cost", {})
	if not ResourceManager.can_afford(cost):
		return false
	
	if not GameManager.can_add_population(1):
		return false
	
	if not ResourceManager.spend_resources(cost):
		return false
	
	production_queue.append(unit_type)
	emit_signal("unit_queued", unit_type)
	#print("Queued unit: %s at %s" % [unit_type, building_type])
	return true

func _can_produce(unit_type: String) -> bool:
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
		if building_type == "town_hall" and TechTree.current_age >= TechTree.Age.MYTHIC:
			return true
		return false
	
	if not TechTree.is_unit_unlocked(unit_type):
		return false
	
	return true

func _get_unit_build_time(unit_type: String) -> float:
	var times = {
		"villager": 6.0,
		"swordsman": 8.0,
		"archer": 10.0,
		"knight": 12.0,
		"healer": 11.0,
		"mage": 15.0,
		"golem": 20.0,
		"dragon": 30.0
	}
	return times.get(unit_type, 8.0)

func _produce_unit(unit_type: String):
	emit_signal("unit_produced", unit_type)
	GameManager.add_population(1)
	GameManager.units_trained += 1
	
	# Spawn unit - in base mode spawn near building, in battle mode spawn via lane
	var world = get_tree().get_first_node_in_group("world")
	if world:
		if GameManager.current_mode == GameManager.GameMode.BATTLE and world.has_method("spawn_unit_in_lane"):
			# Spawn in random lane for idle auto-queue in battle
			world.spawn_unit_in_lane(unit_type, randi() % 3, faction)
		elif world.has_method("spawn_unit"):
			world.spawn_unit(unit_type, global_position + Vector2(randf_range(30,60), randf_range(30,60)), faction)
	
	# Quests
	var im = get_node_or_null("/root/IdleManager")
	if im:
		im.update_quest_progress("train_units", 1)
		im.check_achievements_triggers(GameManager.wave, GameManager.buildings_built, GameManager.units_trained)

func get_idle_generation() -> Dictionary:
	var gen = idle_gen.duplicate()
	# Scale by level
	for k in gen.keys():
		gen[k] *= level
	return gen

func get_production_progress() -> float:
	if current_production == "":
		return 0.0
	var total = _get_unit_build_time(current_production)
	return production_progress / total if total > 0 else 0

func upgrade() -> bool:
	var cost = {
		"wood": 100 * level,
		"gold": 100 * level,
		"stone": 50 * level
	}
	if level >= 2:
		cost["mana"] = 50 * level
	if not ResourceManager.can_afford(cost):
		return false
	if not ResourceManager.spend_resources(cost):
		return false
	level += 1
	max_hp += 200
	hp = max_hp
	if health_bar:
		health_bar.max_value = max_hp
	# Boost gen
	for k in idle_gen.keys():
		idle_gen[k] *= 1.5
	ResourceManager.recalc_building_gen()
	print("Upgraded %s to level %d" % [building_type, level])
	# Visual
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.15)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
	return true

func on_tap() -> Dictionary:
	# Tap building for bonus
	match building_type:
		"town_hall":
			# Tap frenzy progress
			var im = get_node_or_null("/root/IdleManager")
			if im:
				var frenzy = im.register_tap(global_position)
				if frenzy:
					return {"frenzy": true}
			# Small gold/food
			ResourceManager.add_resource_with_fx("gold", randi_range(2,5), global_position)
			ResourceManager.add_resource_with_fx("food", randi_range(1,3), global_position)
			return {"gold": 3, "food": 2}
		"market":
			ResourceManager.add_resource_with_fx("gold", randi_range(3,6), global_position)
			return {"gold": 4}
		"lumber_camp":
			ResourceManager.add_resource_with_fx("wood", randi_range(2,4), global_position)
			return {"wood": 3}
		"house":
			ResourceManager.add_resource_with_fx("food", randi_range(2,4), global_position)
			return {"food": 3}
		_:
			return {}

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
	
	ResourceManager.recalc_building_gen()
	
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
