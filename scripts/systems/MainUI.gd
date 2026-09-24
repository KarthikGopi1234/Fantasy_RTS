extends CanvasLayer

# Main UI - Fantasy AoE style HUD

@onready var resource_labels: Dictionary = {}
@onready var population_label: Label
@onready var age_label: Label
@onready var time_label: Label
@onready var selection_panel: Panel
@onready var selection_label: Label
@onready var build_menu: GridContainer
@onready var unit_menu: GridContainer
@onready var minimap: TextureRect

var build_buttons: Dictionary = {}
var unit_buttons: Dictionary = {}

func _ready():
	_setup_ui()
	
	# Connect signals
	ResourceManager.resource_changed.connect(_on_resource_changed)
	GameManager.selection_changed.connect(_on_selection_changed)
	TechTree.age_advanced.connect(_on_age_advanced)
	
	_update_all_resources()
	_update_age_label()
	_update_population()

func _setup_ui():
	# Top bar - resources
	var top_bar = get_node_or_null("TopBar")
	if not top_bar:
		return
	
	population_label = get_node_or_null("TopBar/PopulationLabel")
	age_label = get_node_or_null("TopBar/AgeLabel")
	time_label = get_node_or_null("TopBar/TimeLabel")
	
	for res in ["food", "wood", "gold", "mana", "stone"]:
		var label = get_node_or_null("TopBar/%sLabel" % res.capitalize())
		if label:
			resource_labels[res] = label
	
	selection_panel = get_node_or_null("SelectionPanel")
	selection_label = get_node_or_null("SelectionPanel/SelectionLabel")
	build_menu = get_node_or_null("BuildMenu/Grid")
	unit_menu = get_node_or_null("UnitMenu/Grid")
	minimap = get_node_or_null("MinimapPanel/Minimap")
	
	# Build menu buttons
	_setup_build_menu()
	_setup_unit_menu()
	
	# Age up button
	var age_btn = get_node_or_null("TopBar/AgeUpButton")
	if age_btn:
		age_btn.pressed.connect(_on_age_up_pressed)

func _setup_build_menu():
	if not build_menu:
		return
	
	# Clear existing
	for child in build_menu.get_children():
		child.queue_free()
	
	var buildings = ["town_hall", "house", "barracks", "archery", "stable", "mage_tower", "wall", "market"]
	for b_type in buildings:
		var btn = Button.new()
		btn.text = b_type.capitalize()
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(_on_build_button_pressed.bind(b_type))
		build_menu.add_child(btn)
		build_buttons[b_type] = btn

func _setup_unit_menu():
	if not unit_menu:
		return
	
	for child in unit_menu.get_children():
		child.queue_free()
	
	var units = ["villager", "swordsman", "archer", "knight", "healer", "mage", "golem", "dragon"]
	for u_type in units:
		var btn = Button.new()
		btn.text = u_type.capitalize()
		btn.custom_minimum_size = Vector2(90, 35)
		btn.pressed.connect(_on_unit_button_pressed.bind(u_type))
		unit_menu.add_child(btn)
		unit_buttons[u_type] = btn

func _process(_delta):
	_update_time()
	_update_build_buttons()
	_update_unit_buttons()
	_update_population()

func _update_all_resources():
	for res_type in resource_labels.keys():
		_on_resource_changed(res_type, ResourceManager.get_resource(res_type))

func _on_resource_changed(type: String, amount: int):
	if resource_labels.has(type):
		resource_labels[type].text = "%s: %d" % [type.capitalize(), amount]

func _on_selection_changed(selected: Array):
	if not selection_panel or not selection_label:
		return
	
	if selected.size() == 0:
		selection_panel.visible = false
		return
	
	selection_panel.visible = true
	if selected.size() == 1:
		var obj = selected[0]
		if obj is BaseUnit:
			selection_label.text = "%s\nHP: %d/%d\nATK: %d" % [obj.unit_type.capitalize(), obj.hp, obj.max_hp, obj.attack_damage]
		elif obj is BaseBuilding:
			selection_label.text = "%s\nHP: %d/%d" % [obj.building_type.capitalize(), obj.hp, obj.max_hp]
			if obj.production_queue.size() > 0:
				selection_label.text += "\nQueue: %s" % ", ".join(obj.production_queue)
	else:
		selection_label.text = "%d units selected" % selected.size()

func _on_age_advanced(new_age: int):
	_update_age_label()

func _update_age_label():
	if age_label:
		age_label.text = TechTree.age_names[TechTree.current_age]

func _update_time():
	if time_label:
		time_label.text = GameManager.get_game_time_string()

func _update_population():
	if population_label:
		population_label.text = "Pop: %s" % GameManager.get_population_string()

func _update_build_buttons():
	for b_type in build_buttons.keys():
		var btn = build_buttons[b_type]
		if not btn:
			continue
		var unlocked = TechTree.is_building_unlocked(b_type)
		var cost = TechTree.building_stats.get(b_type, {}).get("cost", {})
		var can_afford = ResourceManager.can_afford(cost)
		btn.disabled = not unlocked or not can_afford
		btn.modulate = Color(1,1,1,1) if unlocked else Color(1,1,1,0.4)

func _update_unit_buttons():
	for u_type in unit_buttons.keys():
		var btn = unit_buttons[u_type]
		if not btn:
			continue
		var unlocked = TechTree.is_unit_unlocked(u_type)
		var cost = TechTree.unit_stats.get(u_type, {}).get("cost", {})
		var can_afford = ResourceManager.can_afford(cost)
		var has_building_selected = false
		for b in GameManager.selected_buildings:
			if is_instance_valid(b) and b is BaseBuilding:
				has_building_selected = true
				break
		
		# If no building selected, disable all
		if GameManager.selected_buildings.size() == 0 and GameManager.selected_units.size() == 0:
			# Allow town hall production from UI even without selection? Disable for now
			pass
		
		btn.disabled = not unlocked or not can_afford
		btn.modulate = Color(1,1,1,1) if unlocked else Color(1,1,1,0.4)

func _on_build_button_pressed(building_type: String):
	print("Build button: ", building_type)
	GameManager.start_building_placement(building_type)

func _on_unit_button_pressed(unit_type: String):
	print("Unit button: ", unit_type)
	# If building selected, queue in that building
	if GameManager.selected_buildings.size() > 0:
		for b in GameManager.selected_buildings:
			if is_instance_valid(b) and b is BaseBuilding:
				b.queue_unit(unit_type)
				break
	else:
		# Find town hall and queue there
		var town_halls = get_tree().get_nodes_in_group("player_buildings")
		for bh in town_halls:
			if is_instance_valid(bh) and bh.building_type == "town_hall":
				if bh.queue_unit(unit_type):
					break

func _on_age_up_pressed():
	if TechTree.can_advance_age():
		if TechTree.advance_age():
			print("Age advanced!")
		else:
			print("Failed to advance age")
	else:
		print("Cannot advance age - need resources")
