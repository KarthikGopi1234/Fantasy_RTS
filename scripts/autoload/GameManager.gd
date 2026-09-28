extends Node

# GameManager - Idle Auto-Battler Edition
# Portrait, lanes, waves, no drag-box selection

signal game_started
signal game_paused(is_paused: bool)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int, rewards: Dictionary)
signal building_placed(building_type: String, position: Vector2)
signal unit_created(unit_type: String)
signal lane_selected(lane: int)
signal unit_card_selected(unit_type: String)
signal battle_mode_changed(is_battle: bool)
signal game_mode_changed(mode: String)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	BUILDING_PLACEMENT,
	BATTLE,
	VICTORY,
	DEFEAT
}

enum GameMode {
	BASE,      # Building base view
	BATTLE,    # 3-lane auto-battler
	ARMY,      # Army management
	SHOP,      # Chests & upgrades
	PRESTIGE   # Prestige screen
}

var current_state: GameState = GameState.MENU
var current_mode: GameMode = GameMode.BASE

# Population
var max_population: int = 15
var current_population: int = 5

# Map
var map_size: Vector2 = Vector2(1080, 1920)

# Build mode
var building_to_place: String = ""
var is_placing_building: bool = false

# Game stats
var game_time: float = 0.0
var enemies_defeated: int = 0
var buildings_built: int = 0
var units_trained: int = 0

# Idle Auto-Battler
var wave: int = 0
var max_wave: int = 100
var is_wave_active: bool = false
var wave_timer: float = 0.0
var wave_spawn_timer: float = 0.0
var enemies_in_wave: int = 0
var enemies_spawned: int = 0
var enemies_remaining: int = 0
var wave_difficulty: float = 1.0

# Lanes: 0 top, 1 mid, 2 bottom
var selected_lane: int = 1
var selected_unit_card: String = "swordsman"
var lanes_y: Array = [400.0, 960.0, 1520.0] # for 1080x1920 portrait, but battle uses different
var battle_lanes_y: Array = [ -200.0, 0.0, 200.0 ] # relative to center

# Auto-queue
var auto_queue_enabled: bool = true
var auto_queue: Dictionary = {} # building_id -> unit_type
var auto_queue_timers: Dictionary = {}

# Tap frenzy
var tap_frenzy_enabled: bool = true

func _ready():
	print("GameManager Idle Auto-Battler initialized")
	process_mode = Node.PROCESS_MODE_ALWAYS
	lanes_y = [500.0, 960.0, 1420.0]

func _process(delta):
	if current_state == GameState.PLAYING or current_state == GameState.BATTLE:
		game_time += delta
		_process_wave(delta)
		_process_auto_queue(delta)

func start_game():
	current_state = GameState.PLAYING
	current_mode = GameMode.BASE
	max_population = 15
	current_population = 5
	game_time = 0
	enemies_defeated = 0
	buildings_built = 0
	units_trained = 0
	wave = 0
	is_wave_active = false
	emit_signal("game_started")
	print("Idle Game started! Wave 0, Base mode")

func pause_game():
	if current_state == GameState.PLAYING or current_state == GameState.BATTLE:
		current_state = GameState.PAUSED
		get_tree().paused = true
		emit_signal("game_paused", true)
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING if current_mode == GameMode.BASE else GameState.BATTLE
		get_tree().paused = false
		emit_signal("game_paused", false)

func switch_mode(mode: GameMode):
	current_mode = mode
	emit_signal("game_mode_changed", _mode_to_string(mode))
	if mode == GameMode.BATTLE:
		current_state = GameState.BATTLE
		emit_signal("battle_mode_changed", true)
	else:
		current_state = GameState.PLAYING
		emit_signal("battle_mode_changed", false)
	print("Switched to mode: ", _mode_to_string(mode))

func _mode_to_string(mode: GameMode) -> String:
	match mode:
		GameMode.BASE: return "base"
		GameMode.BATTLE: return "battle"
		GameMode.ARMY: return "army"
		GameMode.SHOP: return "shop"
		GameMode.PRESTIGE: return "prestige"
		_: return "base"

func get_mode_string() -> String:
	return _mode_to_string(current_mode)

# --- Population ---
func can_add_population(amount: int) -> bool:
	return current_population + amount <= max_population

func add_population(amount: int):
	current_population += amount
	current_population = clamp(current_population, 0, max_population)

func add_max_population(amount: int):
	max_population += amount
	max_population = max(5, max_population)

# --- Building placement (tap to place, no drag) ---
func start_building_placement(building_type: String):
	if not TechTree.is_building_unlocked(building_type):
		print("Building not unlocked: ", building_type)
		return
	building_to_place = building_type
	is_placing_building = true
	current_state = GameState.BUILDING_PLACEMENT
	print("Placing building: ", building_type)

func cancel_building_placement():
	building_to_place = ""
	is_placing_building = false
	current_state = GameState.PLAYING if current_mode == GameMode.BASE else GameState.BATTLE

func place_building_at(position: Vector2) -> bool:
	if building_to_place == "":
		return false
	var cost = TechTree.building_stats.get(building_to_place, {}).get("cost", {})
	if not ResourceManager.can_afford(cost):
		print("Cannot afford building: ", building_to_place)
		return false
	if not ResourceManager.spend_resources(cost):
		return false

	emit_signal("building_placed", building_to_place, position)
	buildings_built += 1

	if TechTree.building_stats.has(building_to_place):
		var pop = TechTree.building_stats[building_to_place].get("pop", 0)
		if pop > 0:
			add_max_population(pop)

	# Auto-queue setup for production buildings
	if building_to_place in ["barracks", "archery", "stable", "mage_tower"]:
		var default_units = {
			"barracks": "swordsman",
			"archery": "archer",
			"stable": "knight",
			"mage_tower": "mage"
		}
		if default_units.has(building_to_place):
			auto_queue[building_to_place + "_" + str(buildings_built)] = default_units[building_to_place]

	building_to_place = ""
	is_placing_building = false
	current_state = GameState.PLAYING

	# Update quests and achievements
	if Engine.has_singleton("IdleManager") or get_node_or_null("/root/IdleManager"):
		var im = get_node_or_null("/root/IdleManager")
		if im:
			im.update_quest_progress("build_buildings", 1)
			im.check_achievements_triggers(wave, buildings_built, units_trained)

	return true

# --- Unit Cards (tap to deploy) ---
func select_unit_card(unit_type: String):
	if not TechTree.is_unit_unlocked(unit_type):
		return
	selected_unit_card = unit_type
	emit_signal("unit_card_selected", unit_type)
	print("Selected unit card: ", unit_type)

func select_lane(lane: int):
	selected_lane = clamp(lane, 0, 2)
	emit_signal("lane_selected", selected_lane)
	print("Selected lane: ", selected_lane)

func can_deploy_unit(unit_type: String) -> bool:
	var cost = TechTree.unit_stats.get(unit_type, {}).get("cost", {})
	return ResourceManager.can_afford(cost) and can_add_population(1)

func deploy_unit(unit_type: String, lane: int) -> bool:
	if not can_deploy_unit(unit_type):
		return false
	var cost = TechTree.unit_stats.get(unit_type, {}).get("cost", {})
	if not ResourceManager.spend_resources(cost):
		return false
	add_population(1)
	units_trained += 1
	emit_signal("unit_created", unit_type)

	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("spawn_unit_in_lane"):
		world.spawn_unit_in_lane(unit_type, lane, 0)

	# Quests
	var im = get_node_or_null("/root/IdleManager")
	if im:
		im.update_quest_progress("train_units", 1)
		im.check_achievements_triggers(wave, buildings_built, units_trained)

	return true

# --- Waves (Auto-Battler) ---
func start_next_wave():
	if is_wave_active:
		return
	wave += 1
	wave = min(wave, max_wave)
	is_wave_active = true
	wave_difficulty = 1.0 + (wave-1) * 0.25
	enemies_in_wave = 3 + int(wave * 1.5) + int(wave_difficulty)
	enemies_spawned = 0
	enemies_remaining = enemies_in_wave
	wave_spawn_timer = 0.0
	wave_timer = 0.0

	emit_signal("wave_started", wave)
	print("=== Wave %d started! Enemies: %d Difficulty: %.2f ===" % [wave, enemies_in_wave, wave_difficulty])

func _process_wave(delta):
	if not is_wave_active:
		return
	wave_timer += delta
	wave_spawn_timer += delta

	# Spawn enemies over time
	if enemies_spawned < enemies_in_wave and wave_spawn_timer > 1.5:
		wave_spawn_timer = 0.0
		_spawn_wave_enemy()
		enemies_spawned += 1

	# Check wave complete - no enemies left
	if enemies_spawned >= enemies_in_wave:
		var enemy_count = get_tree().get_nodes_in_group("enemy_units").size()
		if enemy_count == 0:
			_complete_wave()

func _spawn_wave_enemy():
	var world = get_tree().get_first_node_in_group("world")
	if not world or not world.has_method("spawn_unit_in_lane"):
		return

	# Choose enemy type based on wave
	var enemy_types = ["swordsman"]
	if wave >= 3:
		enemy_types.append("archer")
	if wave >= 6:
		enemy_types.append("knight")
	if wave >= 10:
		enemy_types.append("mage")
	if wave >= 15:
		enemy_types.append("golem")
	if wave >= 20:
		enemy_types.append("dragon")
	if wave >= 8:
		enemy_types.append("healer")

	var enemy_type = enemy_types[randi() % enemy_types.size()]
	var lane = randi() % 3
	world.spawn_unit_in_lane(enemy_type, lane, 1) # faction 1 enemy

func _complete_wave():
	is_wave_active = false
	var rewards = _calculate_wave_rewards()
	# Give rewards
	for k in rewards.keys():
		ResourceManager.add_resource(k, rewards[k])

	emit_signal("wave_completed", wave, rewards)
	print("Wave %d completed! Rewards: %s" % [wave, rewards])

	# Quests & Achievements
	var im = get_node_or_null("/root/IdleManager")
	if im:
		im.update_quest_progress("defeat_waves", 1)
		im.check_achievements_triggers(wave, buildings_built, units_trained)
		# Chance for chest
		if randf() < 0.3 + float(wave) * 0.01:
			# Auto give common chest chance
			if randf() < 0.15:
				im.open_chest(0) # common free?

func _calculate_wave_rewards() -> Dictionary:
	var base_gold = 50 + wave * 20
	var base_food = 20 + wave * 5
	var base_mana = 5 + int(wave * 0.8)
	var gems = 0
	if wave % 5 == 0:
		gems = 5 + int(wave / 5)
	if wave % 10 == 0:
		gems += 10

	# Scale by difficulty
	base_gold = int(base_gold * (1.0 + wave_difficulty * 0.1))
	return {"gold": base_gold, "food": base_food, "mana": base_mana, "gems": gems}

func get_wave_progress() -> float:
	if not is_wave_active:
		return 0.0
	if enemies_in_wave == 0:
		return 0.0
	return float(enemies_spawned) / float(enemies_in_wave)

# --- Auto Queue ---
func _process_auto_queue(delta):
	if not auto_queue_enabled:
		return
	# Simple: every building with queue produces if can afford
	var buildings = get_tree().get_nodes_in_group("player_buildings")
	for b in buildings:
		if not is_instance_valid(b):
			continue
		if not b.has_method("queue_unit"):
			continue
		# Check if building is production building and not currently producing and has auto-queue
		var b_type = b.get("building_type")
		if b_type in ["barracks", "archery", "stable", "mage_tower", "town_hall"]:
			if b.get("production_queue").size() == 0 and b.get("current_production") == "":
				# Try auto-queue default unit
				var default_unit = ""
				match b_type:
					"town_hall": default_unit = "villager"
					"barracks": default_unit = "swordsman"
					"archery": default_unit = "archer"
					"stable": default_unit = "knight"
					"mage_tower": default_unit = "mage"
				if default_unit != "" and TechTree.is_unit_unlocked(default_unit):
					var cost = TechTree.unit_stats.get(default_unit, {}).get("cost", {})
					if ResourceManager.can_afford(cost) and can_add_population(1):
						b.queue_unit(default_unit)

func set_auto_queue_enabled(enabled: bool):
	auto_queue_enabled = enabled

# --- Utility ---
func get_population_string() -> String:
	return "%d/%d" % [current_population, max_population]

func get_game_time_string() -> String:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_wave_string() -> String:
	if is_wave_active:
		return "Wave %d - %d/%d" % [wave, enemies_spawned, enemies_in_wave]
	else:
		return "Wave %d Ready" % [wave+1]

func victory():
	current_state = GameState.VICTORY
	print("Victory!")

func defeat():
	current_state = GameState.DEFEAT
	print("Defeat!")

func reset_for_prestige():
	# Called when prestige happens
	buildings_built = 0
	units_trained = 0
	wave = 0
	is_wave_active = false
	max_population = 15 + IdleManager.get_prestige_upgrade_level("starting_boost") * 2
	current_population = 5
	game_time = 0
	# Clear world
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("clear_all"):
		world.clear_all()
	# Restart
	start_game()
