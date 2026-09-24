extends Node

# Game Manager - Core RTS state
signal game_started
signal game_paused(is_paused: bool)
signal selection_changed(selected_units: Array)
signal building_placed(building_type: String, position: Vector2)
signal unit_created(unit_type: String)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	BUILDING_PLACEMENT,
	VICTORY,
	DEFEAT
}

var current_state: GameState = GameState.MENU
var selected_units: Array = []
var selected_buildings: Array = []
var player_faction: String = "human"
var enemy_faction: String = "orc"

# Population
var max_population: int = 10
var current_population: int = 0

# Map
var map_size: Vector2 = Vector2(2000, 2000)
var grid_size: int = 32

# Build mode
var building_to_place: String = ""
var is_placing_building: bool = false

# Game stats
var game_time: float = 0.0
var enemies_defeated: int = 0
var buildings_built: int = 0
var units_trained: int = 0

# Touch controls
var drag_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var drag_rect: Rect2 = Rect2()

func _ready():
	print("GameManager initialized")
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if current_state == GameState.PLAYING:
		game_time += delta

func start_game():
	current_state = GameState.PLAYING
	max_population = 10
	current_population = 3 # starting villagers
	game_time = 0
	enemies_defeated = 0
	buildings_built = 0
	units_trained = 0
	emit_signal("game_started")
	print("Game started!")

func pause_game():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		emit_signal("game_paused", true)
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		emit_signal("game_paused", false)

func select_units(units: Array):
	selected_units = units
	selected_buildings = []
	emit_signal("selection_changed", selected_units)

func select_buildings(buildings: Array):
	selected_buildings = buildings
	selected_units = []
	emit_signal("selection_changed", selected_buildings)

func clear_selection():
	selected_units = []
	selected_buildings = []
	emit_signal("selection_changed", [])

func can_add_population(amount: int) -> bool:
	return current_population + amount <= max_population

func add_population(amount: int):
	current_population += amount
	current_population = clamp(current_population, 0, max_population)

func add_max_population(amount: int):
	max_population += amount

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
	current_state = GameState.PLAYING

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
	
	# Reset placement mode
	building_to_place = ""
	is_placing_building = false
	current_state = GameState.PLAYING
	return true

func get_population_string() -> String:
	return "%d/%d" % [current_population, max_population]

func get_game_time_string() -> String:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func victory():
	current_state = GameState.VICTORY
	print("Victory!")

func defeat():
	current_state = GameState.DEFEAT
	print("Defeat!")
