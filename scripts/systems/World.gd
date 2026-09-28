extends Node2D

# World - Polished v2.1.0 Portrait 720x1280
# Fixed orientation, better visuals, camera zoom 1.2 for larger buildings

@onready var units_container: Node2D = $Units
@onready var buildings_container: Node2D = $Buildings
@onready var resources_container: Node2D = $Resources
@onready var fx_container: Node2D = $FX
@onready var map_gen = $MapGenerator
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $BackgroundSprite

var lane_count: int = 3
var lane_y_positions: Array = []
var lane_height: float = 180.0
var battle_area_center: Vector2 = Vector2(360, 640) # 720x1280 center
var battle_area_width: float = 720
var battle_area_height: float = 600

var placement_preview: Node2D = null
var building_ghost_sprite: Sprite2D = null

var unit_scene: PackedScene = null
var building_scene: PackedScene = null
var resource_scene: PackedScene = null

func _ready():
	add_to_group("world")
	print("World Polished v2.1.0 - 720x1280 portrait")
	
	lane_y_positions = [battle_area_center.y - lane_height, battle_area_center.y, battle_area_center.y + lane_height]
	
	if ResourceLoader.exists("res://scenes/units/Unit.tscn"):
		unit_scene = load("res://scenes/units/Unit.tscn")
	if ResourceLoader.exists("res://scenes/buildings/Building.tscn"):
		building_scene = load("res://scenes/buildings/Building.tscn")
	if ResourceLoader.exists("res://scenes/ResourceNode.tscn"):
		resource_scene = load("res://scenes/ResourceNode.tscn")
	
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
		fx_container.z_index = 10
	
	# Setup camera for portrait - zoom 1.2 to make buildings larger, centered on base
	if camera:
		camera.position = Vector2(360, 640)
		camera.zoom = Vector2(1.2, 1.2)
		camera.limit_smoothed = true
		camera.position_smoothing_enabled = true
	
	# Setup background texture
	_setup_background()
	
	if map_gen and map_gen.has_method("generate_map"):
		map_gen.generate_map(self)
	else:
		_generate_idle_base()
	
	if GameManager.has_signal("building_placed"):
		GameManager.building_placed.connect(_on_building_placed)
	if GameManager.has_signal("lane_selected"):
		GameManager.lane_selected.connect(_on_lane_selected)
	
	_setup_placement_preview()
	call_deferred("_spawn_initial_base")

func _setup_background():
	# Create a textured background for idle base
	if not background:
		background = Sprite2D.new()
		background.name = "BackgroundSprite"
		background.z_index = -10
		add_child(background)
	# Generate grass texture 720x1280
	var img = Image.create(720, 1280, false, Image.FORMAT_RGBA8)
	# Base grass
	img.fill(Color(0.15, 0.25, 0.15, 1))
	# Add noise
	for _ in range(800):
		var x = randi() % 720
		var y = randi() % 1280
		var s = randi() % 4 + 1
		var col = Color(randf_range(0.1,0.2), randf_range(0.2,0.35), randf_range(0.1,0.2), 0.5)
		for dy in range(s):
			for dx in range(s):
				if x+dx < 720 and y+dy < 1280:
					img.set_pixel(x+dx, y+dy, col)
	# Paths
	for y in range(600, 700, 20):
		for x in range(0, 720, 20):
			if randf() > 0.3:
				img.set_pixel(x, y, Color(0.4, 0.35, 0.25, 0.6))
	var tex = ImageTexture.create_from_image(img)
	if background:
		background.texture = tex
		background.centered = false
		background.position = Vector2(0,0)

func _spawn_initial_base():
	# Spawn town hall in center, larger spacing for 720x1280
	spawn_building("town_hall", Vector2(360, 640), 0)
	spawn_building("house", Vector2(180, 720), 0)
	spawn_building("lumber_camp", Vector2(540, 720), 0)
	spawn_unit("villager", Vector2(360, 800), 0)
	spawn_unit("villager", Vector2(320, 840), 0)
	spawn_unit("swordsman", Vector2(400, 840), 0)

func _generate_idle_base():
	for i in range(6):
		var pos = Vector2(randf_range(80, 640), randf_range(400, 1000))
		var types = ["wood", "gold", "stone", "mana"]
		var t = types[randi() % types.size()]
		spawn_resource(t, pos)

func _setup_placement_preview():
	placement_preview = Node2D.new()
	placement_preview.name = "PlacementPreview"
	placement_preview.visible = false
	placement_preview.z_index = 5
	add_child(placement_preview)
	
	building_ghost_sprite = Sprite2D.new()
	building_ghost_sprite.name = "Ghost"
	building_ghost_sprite.modulate = Color(1,1,1,0.6)
	placement_preview.add_child(building_ghost_sprite)
	
	var label = Label.new()
	label.name = "Label"
	label.position = Vector2(-50, -70)
	label.text = "Tap to place"
	label.add_theme_font_size_override("font_size", 16)
	placement_preview.add_child(label)

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseMotion and GameManager.is_placing_building:
		_update_placement_preview(event.position)

func _handle_tap(screen_pos: Vector2):
	var world_pos = _screen_to_world(screen_pos)
	
	if GameManager.is_placing_building:
		if _is_valid_building_position(world_pos):
			GameManager.place_building_at(world_pos)
			placement_preview.visible = false
		else:
			spawn_floating_text("Invalid!", world_pos, Color(1,0.2,0.2))
		return
	
	var building = _get_building_at(world_pos)
	if building and building.has_method("on_tap"):
		var result = building.on_tap()
		if result.size() > 0:
			for k in result.keys():
				if k == "frenzy":
					spawn_floating_text("FRENZY!", world_pos + Vector2(0,-50), Color(1,0.8,0.2))
				else:
					spawn_floating_text("+%s %s" % [result[k], k], world_pos + Vector2(randf_range(-20,20), -30), _get_resource_color(k))
		return
	
	if GameManager.current_mode == GameManager.GameMode.BATTLE:
		_handle_battle_tap(screen_pos, world_pos)
		return
	
	var im = get_node_or_null("/root/IdleManager")
	if im:
		im.register_tap(world_pos)

func _handle_battle_tap(screen_pos: Vector2, world_pos: Vector2):
	var lane = _get_lane_from_y(world_pos.y)
	GameManager.select_lane(lane)
	
	var unit_type = GameManager.selected_unit_card
	if GameManager.can_deploy_unit(unit_type):
		GameManager.deploy_unit(unit_type, lane)
		spawn_floating_text("Deployed %s!" % unit_type.capitalize(), world_pos, Color(0.2,1,0.2))
	else:
		spawn_floating_text("Not enough!", world_pos, Color(1,0.2,0.2))

func _is_valid_building_position(pos: Vector2) -> bool:
	if pos.y < 300 or pos.y > 1100:
		return false
	if pos.x < 60 or pos.x > 660:
		return false
	for b in get_tree().get_nodes_in_group("player_buildings"):
		if not is_instance_valid(b):
			continue
		if b.global_position.distance_to(pos) < 100:
			return false
	return true

func _get_building_at(world_pos: Vector2) -> Node:
	var closest = null
	var min_dist = 70
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
	
	if building_ghost_sprite and GameManager.building_to_place != "":
		var tex_path = "res://assets/sprites/buildings/%s.png" % GameManager.building_to_place
		if ResourceLoader.exists(tex_path):
			building_ghost_sprite.texture = load(tex_path)
		if _is_valid_building_position(world_pos):
			building_ghost_sprite.modulate = Color(0.5,1,0.5,0.6)
		else:
			building_ghost_sprite.modulate = Color(1,0.3,0.3,0.6)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
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

func _on_lane_selected(_lane: int):
	pass

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
		var script = load("res://scripts/units/BaseUnit.gd")
		unit = CharacterBody2D.new()
		unit.set_script(script)
		unit.set("unit_type", unit_type)
		unit.set("faction", faction)
		unit.global_position = position
	
	units_container.add_child(unit)
	if unit.has_method("_get_lane_y"):
		unit.lane = _get_lane_from_y(position.y)
	
	return unit

func spawn_unit_in_lane(unit_type: String, lane: int, faction: int = 0, custom_pos: Vector2 = Vector2.ZERO) -> Node:
	var y = get_lane_y(lane)
	var x = 80.0 if faction == 0 else 640.0
	if custom_pos != Vector2.ZERO:
		x = custom_pos.x
		y = custom_pos.y if custom_pos.y != 0 else y
	
	var pos = Vector2(x, y + randf_range(-15,15))
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
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	label.add_theme_color_override("font_outline_color", Color(0,0,0,0.8))
	label.add_theme_constant_override("outline_size", 3)
	fx_container.add_child(label)
	
	var tween = create_tween()
	tween.parallel().tween_property(label, "global_position", pos + Vector2(randf_range(-15,15), -60), 0.9)
	tween.parallel().tween_property(label, "modulate", Color(1,1,1,0), 0.9)
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
	for child in units_container.get_children():
		child.queue_free()
	for child in buildings_container.get_children():
		child.queue_free()

func _draw():
	if GameManager.current_mode == GameManager.GameMode.BATTLE:
		for y in lane_y_positions:
			draw_line(Vector2(0, y), Vector2(720, y), Color(1,1,1,0.12), 2.0)
			# Lane markers
			draw_line(Vector2(0, y-1), Vector2(720, y-1), Color(1,1,1,0.05), 1.0)

func _process(_delta):
	queue_redraw()
