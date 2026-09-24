extends Node2D
class_name World

# World - Main game world controller
# Handles spawning, selection box, touch controls, AI

@onready var units_container: Node2D = $Units
@onready var buildings_container: Node2D = $Buildings
@onready var resources_container: Node2D = $Resources
@onready var selection_box: Panel = $CanvasLayer/SelectionBox
@onready var map_gen: MapGenerator = $MapGenerator

var selected_units: Array = []
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO

# Preloads
var unit_scene: PackedScene = preload("res://scenes/units/Unit.tscn")
var building_scene: PackedScene = preload("res://scenes/buildings/Building.tscn")
var resource_scene: PackedScene = preload("res://scenes/ResourceNode.tscn")

func _ready():
	add_to_group("world")
	print("World ready")
	
	# Generate map
	if map_gen:
		map_gen.generate_map(self)
	
	# Connect GameManager signals
	GameManager.building_placed.connect(_on_building_placed)
	
	# Setup camera
	var cam = get_node_or_null("Camera2D")
	if cam:
		cam.position = Vector2(400,400)

func _input(event):
	# Touch / Mouse selection and movement
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(event.position)
	
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position)
	
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position)
		else:
			_end_drag(event.position)
	
	elif event is InputEventScreenDrag and is_dragging:
		_update_drag(event.position)

func _start_drag(screen_pos: Vector2):
	is_dragging = true
	drag_start = screen_pos
	drag_end = screen_pos
	if selection_box:
		selection_box.visible = true
		selection_box.position = drag_start
		selection_box.size = Vector2.ZERO

func _update_drag(screen_pos: Vector2):
	drag_end = screen_pos
	if selection_box:
		var rect = Rect2(drag_start, drag_end - drag_start)
		rect = rect.abs()
		selection_box.position = rect.position
		selection_box.size = rect.size

func _end_drag(screen_pos: Vector2):
	is_dragging = false
	drag_end = screen_pos
	if selection_box:
		selection_box.visible = false
	
	var drag_distance = drag_start.distance_to(drag_end)
	if drag_distance < 10:
		# Single click selection
		_handle_single_click(screen_pos)
	else:
		# Box selection
		_handle_box_selection(drag_start, drag_end)

func _handle_single_click(screen_pos: Vector2):
	var world_pos = _screen_to_world(screen_pos)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var results = space_state.intersect_point(query, 10)
	
	for res in results:
		var collider = res["collider"]
		if collider is BaseUnit and collider.faction == BaseUnit.UnitFaction.PLAYER:
			_select_single_unit(collider)
			return
		elif collider is BaseBuilding and collider.faction == 0:
			_select_single_building(collider)
			return
	
	# Clicked empty - clear selection or move?
	if selected_units.size() > 0:
		_move_selected_units(world_pos)
	else:
		_clear_selection()

func _handle_box_selection(start: Vector2, end: Vector2):
	var rect = Rect2(start, end - start).abs()
	var world_rect_start = _screen_to_world(rect.position)
	var world_rect_end = _screen_to_world(rect.position + rect.size)
	var world_rect = Rect2(world_rect_start, world_rect_end - world_rect_start).abs()
	
	var new_selection = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		if world_rect.has_point(unit.global_position):
			new_selection.append(unit)
	
	if new_selection.size() > 0:
		_select_units(new_selection)

func _handle_right_click(screen_pos: Vector2):
	var world_pos = _screen_to_world(screen_pos)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	var results = space_state.intersect_point(query, 10)
	
	for res in results:
		var collider = res["collider"]
		if collider is BaseUnit and collider.faction != BaseUnit.UnitFaction.PLAYER:
			# Attack enemy
			for u in selected_units:
				if u is BaseUnit:
					u.attack_unit(collider)
			return
		elif collider is ResourceNode:
			# Gather
			for u in selected_units:
				if u is BaseUnit and u.unit_type == "villager":
					u.gather_resource(collider, collider.resource_type)
			return
		elif collider is BaseBuilding and collider.faction != 0:
			# Attack building
			# For simplicity, find nearest enemy unit? Or attack building directly if unit can
			pass
	
	# Move to position
	_move_selected_units(world_pos)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam = get_node_or_null("Camera2D")
	if cam and cam is Camera2D:
		return cam.get_screen_center_position() + (screen_pos - get_viewport_rect().size/2) / cam.zoom
	return screen_pos

func _select_single_unit(unit: BaseUnit):
	_clear_selection()
	unit.select()
	selected_units = [unit]
	GameManager.select_units(selected_units)

func _select_single_building(building: BaseBuilding):
	_clear_selection()
	building.select()
	GameManager.select_buildings([building])

func _select_units(units: Array):
	_clear_selection()
	selected_units = units
	for u in units:
		if u is BaseUnit:
			u.select()
	GameManager.select_units(selected_units)

func _clear_selection():
	for u in selected_units:
		if is_instance_valid(u) and u.has_method("deselect"):
			u.deselect()
	selected_units = []
	GameManager.clear_selection()
	
	# Also deselect buildings
	for b in get_tree().get_nodes_in_group("player_buildings"):
		if is_instance_valid(b) and b.is_selected:
			b.deselect()

func _move_selected_units(world_pos: Vector2):
	if selected_units.size() == 0:
		return
	
	# Formation move
	var count = selected_units.size()
	var cols = int(ceil(sqrt(count)))
	for i in range(count):
		var unit = selected_units[i]
		if not is_instance_valid(unit):
			continue
		var row = i / cols
		var col = i % cols
		var offset = Vector2(col * 32 - (cols*32)/2, row * 32 - (cols*32)/2)
		if unit is BaseUnit:
			unit.move_to(world_pos + offset)

func spawn_unit(unit_type: String, position: Vector2, faction: int = 0) -> BaseUnit:
	if not units_container:
		units_container = $Units
	
	var unit: BaseUnit = unit_scene.instantiate() as BaseUnit
	unit.unit_type = unit_type
	unit.faction = faction as BaseUnit.UnitFaction
	unit.global_position = position
	units_container.add_child(unit)
	
	# If player faction, add to population if not already counted
	# (World spawn for initial doesn't count double)
	return unit

func spawn_building(building_type: String, position: Vector2, faction: int = 0) -> BaseBuilding:
	if not buildings_container:
		buildings_container = $Buildings
	
	var building: BaseBuilding = building_scene.instantiate() as BaseBuilding
	building.building_type = building_type
	building.faction = faction
	building.global_position = position
	buildings_container.add_child(building)
	
	# Connect production signal
	building.unit_produced.connect(_on_unit_produced)
	
	return building

func spawn_resource(res_type: String, position: Vector2) -> ResourceNode:
	if not resources_container:
		resources_container = $Resources
	
	var res: ResourceNode = resource_scene.instantiate() as ResourceNode
	res.resource_type = res_type
	res.global_position = position
	resources_container.add_child(res)
	return res

func _on_building_placed(building_type: String, position: Vector2):
	spawn_building(building_type, position, 0)

func _on_unit_produced(unit_type: String):
	# Already spawned in building, but we can add effects
	pass

# Simple enemy AI - sends units to attack player periodically
var ai_timer: float = 0.0
func _process(delta):
	ai_timer += delta
	if ai_timer > 20.0:
		ai_timer = 0.0
		_do_enemy_ai()

func _do_enemy_ai():
	# Find enemy units and send them to attack player base
	var enemy_units = get_tree().get_nodes_in_group("enemy_units")
	var player_buildings = get_tree().get_nodes_in_group("player_buildings")
	
	if enemy_units.size() == 0 or player_buildings.size() == 0:
		return
	
	var target = player_buildings[randi() % player_buildings.size()]
	for unit in enemy_units:
		if is_instance_valid(unit) and unit is BaseUnit and unit.state == BaseUnit.UnitState.IDLE:
			if randf() < 0.5:
				unit.move_to(target.global_position + Vector2(randf_range(-50,50), randf_range(-50,50)))
