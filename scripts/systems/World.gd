extends Node2D

# World - Idle Auto-Battler Edition
# Portrait, 3 lanes, tap to place buildings / deploy units, no drag-box

@onready var units_container: Node2D = $Units
@onready var buildings_container: Node2D = $Buildings
@onready var resources_container: Node2D = $Resources
@onready var fx_container: Node2D = $FX
@onready var map_gen = $MapGenerator

# Lanes
var lane_count: int = 3
var lane_y_positions: Array = [] # world Y for each lane
var lane_height: float = 220.0
var battle_area_center: Vector2 = Vector2(540, 960) # portrait center
var battle_area_width: float = 1080
var battle_area_height: float = 700

# Placement
var placement_preview: Node2D = null
var building_ghost_sprite: Sprite2D = null

# Preloads - try to load existing scenes, fallback to script creation
var unit_scene: PackedScene = null
var building_scene: PackedScene = null
var resource_scene: PackedScene = null

# Floating text scene
var floating_texts: Array = []

func _ready():
	add_to_group("world")
	print("World Idle Auto-Battler ready - portrait 1080x1920")
	
	# Setup lane positions for portrait battle
	# Base mode: buildings in grid
	# Battle mode: 3 horizontal lanes
	lane_y_positions = [battle_area_center.y - lane_height, battle_area_center.y, battle_area_center.y + lane_height]
	
	# Load scenes if exist
	if ResourceLoader.exists("res://scenes/units/Unit.tscn"):
		unit_scene = load("res://scenes/units/Unit.tscn")
	if ResourceLoader.exists("res://scenes/buildings/Building.tscn"):
		building_scene = load("res://scenes/buildings/Building.tscn")
	if ResourceLoader.exists("res://scenes/ResourceNode.tscn"):
		resource_scene = load("res://scenes/ResourceNode.tscn")
	
	# Ensure containers exist
	if not units_container:
		units_container = Node2D.new()
		units_container.name = "Units"
		add_child(units_container)
	if not buildings_container:
		buildings_container = Node2D.new()
		buildings_container.name = "Buildings"
		add_child(buildings_container)
	if not resources_container:
		resources_container = Node2D.new()
		resources_container.name = "Resources"
		add_child(resources_container)
	if not fx_container:
		fx_container = Node2D.new()
		fx_container.name = "FX"
		add_child(fx_container)
	
	# Map generation
	if map_gen and map_gen.has_method("generate_map"):
		map_gen.generate_map(self)
	else:
		_generate_idle_base()
	
	# Connect signals
	if GameManager.has_signal("building_placed"):
		GameManager.building_placed.connect(_on_building_placed)
	if GameManager.has_signal("lane_selected"):
		GameManager.lane_selected.connect(_on_lane_selected)
	
	# Setup placement preview
	_setup_placement_preview()
	
	# Spawn initial town hall
	call_deferred("_spawn_initial_base")

func _spawn_initial_base():
	# Spawn town hall in center of base view
	spawn_building("town_hall", Vector2(540, 800), 0)
	spawn_building("house", Vector2(300, 900), 0)
	spawn_building("lumber_camp", Vector2(800, 900), 0)
	# Spawn initial villagers
	spawn_unit("villager", Vector2(540, 1000), 0)
	spawn_unit("villager", Vector2(500, 1050), 0)
	spawn_unit("swordsman", Vector2(600, 1050), 0)

func _generate_idle_base():
	# Generate resource nodes for idle gathering (visual only, auto gen via buildings)
	for i in range(6):
		var pos = Vector2(randf_range(100, 980), randf_range(600, 1200))
		var types = ["wood", "gold", "stone", "mana"]
		var t = types[randi() % types.size()]
		spawn_resource(t, pos)

func _setup_placement_preview():
	placement_preview = Node2D.new()
	placement_preview.name = "PlacementPreview"
	placement_preview.visible = false
	add_child(placement_preview)
	
	building_ghost_sprite = Sprite2D.new()
	building_ghost_sprite.name = "Ghost"
	building_ghost_sprite.modulate = Color(1,1,1,0.6)
	placement_preview.add_child(building_ghost_sprite)
	
	var label = Label.new()
	label.name = "Label"
	label.position = Vector2(-40, -80)
	label.text = "Tap to place"
	label.add_theme_font_size_override("font_size", 18)
	placement_preview.add_child(label)

func _input(event):
	# Tap handling - simplified for idle
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseMotion and GameManager.is_placing_building:
		_update_placement_preview(event.position)

func _handle_tap(screen_pos: Vector2):
	var world_pos = _screen_to_world(screen_pos)
	
	# Building placement mode
	if GameManager.is_placing_building:
		# Check if valid position (not overlapping, within base area)
		if _is_valid_building_position(world_pos):
			GameManager.place_building_at(world_pos)
			placement_preview.visible = false
		return
	
	# Check tap on buildings (for tap frenzy / collect)
	var building = _get_building_at(world_pos)
	if building and building.has_method("on_tap"):
		var result = building.on_tap()
		# Show floating text for result
		if result.size() > 0:
			for k in result.keys():
				if k == "frenzy":
					spawn_floating_text("FRENZY!", world_pos + Vector2(0,-50), Color(1,0.8,0.2))
				else:
					spawn_floating_text("+%s %s" % [result[k], k], world_pos + Vector2(randf_range(-20,20), -30), _get_resource_color(k))
		return
	
	# Battle mode: deploy unit in lane
	if GameManager.current_mode == GameManager.GameMode.BATTLE:
		_handle_battle_tap(screen_pos, world_pos)
		return
	
	# Base mode: if tapped empty, maybe show build menu? Handled by UI
	# Also register tap for frenzy
	var im = get_node_or_null("/root/IdleManager")
	if im:
		im.register_tap(world_pos)

func _handle_battle_tap(screen_pos: Vector2, world_pos: Vector2):
	# Determine lane from Y
	var lane = _get_lane_from_y(world_pos.y)
	GameManager.select_lane(lane)
	
	# Deploy selected unit card if can afford
	var unit_type = GameManager.selected_unit_card
	if GameManager.can_deploy_unit(unit_type):
		# Spawn at left side in that lane
		var spawn_x = 50 if GameManager.current_state != GameManager.GameState.BATTLE else 100
		# Player spawn left, enemies spawn right
		var spawn_pos = Vector2(spawn_x, get_lane_y(lane))
		if spawn_unit_in_lane(unit_type, lane, 0, spawn_pos):
			# Deduct handled in GameManager.deploy_unit, but we are bypassing that for direct spawn?
			# Use GameManager.deploy_unit for cost check
			pass
		# Actually use deploy method for cost
		GameManager.deploy_unit(unit_type, lane)
	else:
		# Show not enough resources
		spawn_floating_text("Not enough!", world_pos, Color(1,0.2,0.2))

func _is_valid_building_position(pos: Vector2) -> bool:
	# Check within base area (not in battle lanes if in base mode)
	if pos.y < 400 or pos.y > 1400:
		return false
	if pos.x < 80 or pos.x > 1000:
		return false
	# Check not overlapping other buildings
	for b in get_tree().get_nodes_in_group("player_buildings"):
		if not is_instance_valid(b):
			continue
		if b.global_position.distance_to(pos) < 120:
			return false
	return true

func _get_building_at(world_pos: Vector2) -> Node:
	var closest = null
	var min_dist = 80
	for b in get_tree().get_nodes_in_group("player_buildings"):
		if not is_instance_valid(b):
			continue
		var d = b.global_position.distance_to(world_pos)
		if d < min_dist:
			min_dist = d
			closest = b
	return closest

func _update_placement_preview(screen_pos: Vector2):
	if not placement_preview:
		return
	var world_pos = _screen_to_world(screen_pos)
	placement_preview.global_position = world_pos
	placement_preview.visible = true
	
	# Update ghost texture
	if building_ghost_sprite and GameManager.building_to_place != "":
		var tex_path = "res://assets/sprites/buildings/%s.png" % GameManager.building_to_place
		if ResourceLoader.exists(tex_path):
			building_ghost_sprite.texture = load(tex_path)
		# Color based on valid
		if _is_valid_building_position(world_pos):
			building_ghost_sprite.modulate = Color(0.5,1,0.5,0.6)
		else:
			building_ghost_sprite.modulate = Color(1,0.3,0.3,0.6)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# In canvas_items stretch mode, screen pos is roughly world pos for 1080x1920
	# But if camera exists, use it
	var cam = get_node_or_null("Camera2D")
	if cam and cam is Camera2D:
		return cam.get_screen_center_position() + (screen_pos - get_viewport_rect().size/2) / cam.zoom
	return screen_pos

func get_lane_y(lane: int) -> float:
	lane = clamp(lane, 0, 2)
	if lane < lane_y_positions.size():
		return lane_y_positions[lane]
	return battle_area_center.y

func _get_lane_from_y(y: float) -> int:
	var closest = 1
	var min_dist = 99999.0
	for i in range(lane_y_positions.size()):
		var d = abs(y - lane_y_positions[i])
		if d < min_dist:
			min_dist = d
			closest = i
	return closest

func _on_lane_selected(lane: int):
	# Visual feedback for lane selection
	# Could highlight lane
	pass

# --- Spawning ---

func spawn_unit(unit_type: String, position: Vector2, faction: int = 0) -> Node:
	if not units_container:
		units_container = $Units
	
	var unit: Node = null
	if unit_scene:
		unit = unit_scene.instantiate()
		unit.set("unit_type", unit_type)
		unit.set("faction", faction)
		unit.global_position = position
	else:
		# Create from script
		var script = load("res://scripts/units/BaseUnit.gd")
		unit = CharacterBody2D.new()
		unit.set_script(script)
		unit.set("unit_type", unit_type)
		unit.set("faction", faction)
		unit.global_position = position
	
	units_container.add_child(unit)
	# Set lane based on Y
	if unit.has_method("_get_lane_y"):
		unit.lane = _get_lane_from_y(position.y)
	
	return unit

func spawn_unit_in_lane(unit_type: String, lane: int, faction: int = 0, custom_pos: Vector2 = Vector2.ZERO) -> Node:
	var y = get_lane_y(lane)
	var x = 100.0 if faction == 0 else 980.0
	if custom_pos != Vector2.ZERO:
		x = custom_pos.x
		y = custom_pos.y if custom_pos.y != 0 else y
	
	var pos = Vector2(x, y + randf_range(-20,20))
	var unit = spawn_unit(unit_type, pos, faction)
	if unit:
		unit.lane = lane
	return unit

func spawn_building(building_type: String, position: Vector2, faction: int = 0) -> Node:
	if not buildings_container:
		buildings_container = $Buildings
	
	var building: Node = null
	if building_scene:
		building = building_scene.instantiate()
		building.set("building_type", building_type)
		building.set("faction", faction)
		building.global_position = position
	else:
		var script = load("res://scripts/buildings/BaseBuilding.gd")
		building = StaticBody2D.new()
		building.set_script(script)
		building.set("building_type", building_type)
		building.set("faction", faction)
		building.global_position = position
	
	buildings_container.add_child(building)
	
	if building.has_signal("unit_produced"):
		building.unit_produced.connect(_on_unit_produced)
	
	ResourceManager.recalc_building_gen()
	
	return building

func spawn_resource(res_type: String, position: Vector2) -> Node:
	if not resources_container:
		resources_container = $Resources
	
	var res: Node = null
	if resource_scene:
		res = resource_scene.instantiate()
		res.set("resource_type", res_type)
		res.global_position = position
	else:
		# Simple sprite node
		res = Node2D.new()
		var sprite = Sprite2D.new()
		var img = Image.create(48,48,false,Image.FORMAT_RGBA8)
		var col = Color(0.2,0.8,0.2)
		match res_type:
			"wood": col = Color(0.3,0.6,0.2)
			"gold": col = Color(0.9,0.8,0.1)
			"stone": col = Color(0.6,0.6,0.6)
			"mana": col = Color(0.4,0.2,0.9)
		img.fill(col)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
		res.add_child(sprite)
		res.global_position = position
		res.set_meta("resource_type", res_type)
	
	resources_container.add_child(res)
	return res

func spawn_floating_text(text: String, pos: Vector2, color: Color = Color(1,1,1)):
	if not fx_container:
		return
	var label = Label.new()
	label.text = text
	label.global_position = pos
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	# Outline
	label.add_theme_color_override("font_outline_color", Color(0,0,0,0.8))
	label.add_theme_constant_override("outline_size", 4)
	fx_container.add_child(label)
	
	var tween = create_tween()
	tween.parallel().tween_property(label, "global_position", pos + Vector2(randf_range(-20,20), -80), 1.0)
	tween.parallel().tween_property(label, "modulate", Color(1,1,1,0), 1.0)
	tween.tween_callback(label.queue_free)

func _get_resource_color(res_type: String) -> Color:
	match res_type:
		"food": return Color(0.2,0.9,0.2)
		"wood": return Color(0.5,0.3,0.1)
		"gold": return Color(1,0.9,0.2)
		"mana": return Color(0.5,0.2,1)
		"stone": return Color(0.7,0.7,0.7)
		"gems": return Color(0.2,0.9,0.9)
		_: return Color(1,1,1)

func _on_building_placed(building_type: String, position: Vector2):
	spawn_building(building_type, position, 0)

func _on_unit_produced(_unit_type: String):
	pass

func clear_all():
	# Clear for prestige
	for child in units_container.get_children():
		child.queue_free()
	for child in buildings_container.get_children():
		if child.get("building_type") != "town_hall": # keep town hall? Actually clear all for prestige then respawn
			child.queue_free()
	# Will be respawned by GameManager

# Debug draw lanes
func _draw():
	if GameManager.current_mode == GameManager.GameMode.BATTLE:
		# Draw lane lines
		for y in lane_y_positions:
			draw_line(Vector2(0, y - battle_area_center.y + 960), Vector2(1080, y - battle_area_center.y + 960), Color(1,1,1,0.15), 2.0)
			# Actually draw in world coords
			draw_line(Vector2(0, y), Vector2(1080, y), Color(1,1,1,0.1), 2.0)

func _process(_delta):
	queue_redraw()
