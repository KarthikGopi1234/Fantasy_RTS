extends CharacterBody2D
class_name BaseUnit

# Base Unit - AoE style unit with state machine
# States: IDLE, MOVING, GATHERING, ATTACKING, BUILDING

signal unit_selected(unit)
signal unit_deselected(unit)
signal unit_died(unit)

enum UnitState {
	IDLE,
	MOVING,
	GATHERING,
	ATTACKING,
	BUILDING,
	DEAD
}

enum UnitFaction {
	PLAYER,
	ENEMY,
	NEUTRAL
}

@export var unit_type: String = "villager"
@export var faction: UnitFaction = UnitFaction.PLAYER
@export var team_color: Color = Color(0, 0, 1)

var max_hp: int = 40
var hp: int = 40
var attack_damage: int = 5
var armor: int = 0
var move_speed: float = 90.0
var attack_range: float = 32.0
var gather_rate: float = 1.0
var is_selected: bool = false

var state: UnitState = UnitState.IDLE
var target_position: Vector2 = Vector2.ZERO
var target_unit: BaseUnit = null
var target_building: Node = null
var target_resource: Node = null
var gather_type: String = ""

# Navigation
var navigation_agent: NavigationAgent2D
var last_path_position: Vector2

# Combat
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var is_attacking: bool = false

# Visual
var sprite: Sprite2D
var selection_indicator: Node2D
var health_bar: ProgressBar

func _ready():
	add_to_group("units")
	if faction == UnitFaction.PLAYER:
		add_to_group("player_units")
	else:
		add_to_group("enemy_units")
	
	# Setup from TechTree stats
	if TechTree.unit_stats.has(unit_type):
		var stats = TechTree.unit_stats[unit_type]
		max_hp = stats.get("hp", 40)
		hp = max_hp
		attack_damage = stats.get("attack", 5)
		armor = stats.get("armor", 0)
		move_speed = stats.get("speed", 90)
		attack_range = stats.get("range", 32)
	
	# Create visual components
	_setup_visuals()
	_setup_navigation()
	
	target_position = global_position
	print("Unit spawned: %s at %s" % [unit_type, global_position])

func _setup_visuals():
	# Sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	# Try to load texture
	var tex_path = "res://assets/sprites/units/%s.png" % unit_type
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		# Fallback - create colored rectangle via CanvasItem
		sprite.texture = null
	
	# Selection indicator
	selection_indicator = Node2D.new()
	selection_indicator.name = "Selection"
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	# Draw selection circle
	var sel_sprite = Sprite2D.new()
	sel_sprite.name = "Circle"
	if ResourceLoader.exists("res://assets/ui/selection_circle.png"):
		sel_sprite.texture = load("res://assets/ui/selection_circle.png")
	selection_indicator.add_child(sel_sprite)
	
	# Health bar
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(40, 6)
	health_bar.position = Vector2(-20, -30)
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.show_percentage = false
	health_bar.visible = false
	add_child(health_bar)

func _setup_navigation():
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.name = "NavAgent"
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 8.0
	add_child(navigation_agent)

func _physics_process(delta):
	if state == UnitState.DEAD:
		return
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	match state:
		UnitState.IDLE:
			_process_idle(delta)
		UnitState.MOVING:
			_process_moving(delta)
		UnitState.GATHERING:
			_process_gathering(delta)
		UnitState.ATTACKING:
			_process_attacking(delta)
		UnitState.BUILDING:
			_process_building(delta)
	
	# Update health bar
	if health_bar:
		health_bar.value = hp
		health_bar.visible = hp < max_hp or is_selected

func _process_idle(_delta):
	velocity = Vector2.ZERO
	# Look for nearby enemies if military unit
	if unit_type != "villager" and faction == UnitFaction.PLAYER:
		var enemy = _find_nearest_enemy(200)
		if enemy:
			attack_unit(enemy)

func _process_moving(_delta):
	if navigation_agent.is_navigation_finished():
		state = UnitState.IDLE
		velocity = Vector2.ZERO
		return
	
	var next_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * move_speed
	move_and_slide()
	
	# Update sprite direction
	if velocity.length() > 10:
		_update_facing_direction(velocity)

func _process_gathering(delta):
	if not target_resource or not is_instance_valid(target_resource):
		state = UnitState.IDLE
		return
	
	var dist = global_position.distance_to(target_resource.global_position)
	if dist > 40:
		# Move to resource
		navigation_agent.target_position = target_resource.global_position
		var next_pos = navigation_agent.get_next_path_position()
		var dir = global_position.direction_to(next_pos)
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		# Gather
		if attack_timer <= 0:
			_gather_resource()
			attack_timer = 1.0 / gather_rate

func _process_attacking(_delta):
	if not target_unit or not is_instance_valid(target_unit) or target_unit.state == UnitState.DEAD:
		state = UnitState.IDLE
		target_unit = null
		return
	
	var dist = global_position.distance_to(target_unit.global_position)
	if dist > attack_range + 10:
		# Chase
		navigation_agent.target_position = target_unit.global_position
		var next_pos = navigation_agent.get_next_path_position()
		var dir = global_position.direction_to(next_pos)
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		# Attack
		if attack_timer <= 0:
			_perform_attack()
			attack_timer = attack_cooldown

func _process_building(_delta):
	# Simplified building logic
	if not target_building or not is_instance_valid(target_building):
		state = UnitState.IDLE
		return
	# Move to building site etc.
	pass

func move_to(pos: Vector2):
	target_position = pos
	navigation_agent.target_position = pos
	state = UnitState.MOVING
	target_unit = null
	target_resource = null

func attack_unit(unit: BaseUnit):
	if unit.faction == faction:
		return
	target_unit = unit
	state = UnitState.ATTACKING

func gather_resource(resource_node: Node, res_type: String):
	target_resource = resource_node
	gather_type = res_type
	state = UnitState.GATHERING

func _gather_resource():
	if not target_resource:
		return
	var amount = int(ResourceManager.get_gather_rate(gather_type))
	ResourceManager.add_resource(gather_type, amount)
	# Visual feedback - could spawn floating text
	# print("%s gathered %d %s" % [unit_type, amount, gather_type])

func _perform_attack():
	if not target_unit:
		return
	target_unit.take_damage(attack_damage, self)
	# Play attack animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1,1), 0.1)

func take_damage(amount: int, attacker: BaseUnit = null):
	var actual_damage = max(1, amount - armor)
	hp -= actual_damage
	hp = max(0, hp)
	
	# Flash red
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1,0,0), 0.05)
		tween.tween_property(sprite, "modulate", Color(1,1,1), 0.1)
	
	if hp <= 0:
		die()
	elif attacker and state == UnitState.IDLE and unit_type != "villager":
		# Auto retaliate
		attack_unit(attacker)

func die():
	state = UnitState.DEAD
	emit_signal("unit_died", self)
	
	if faction == UnitFaction.PLAYER:
		GameManager.add_population(-1)
	else:
		GameManager.enemies_defeated += 1
	
	# Death animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(queue_free)
	
	print("%s died" % unit_type)

func select():
	is_selected = true
	if selection_indicator:
		selection_indicator.visible = true
	if health_bar:
		health_bar.visible = true
	emit_signal("unit_selected", self)

func deselect():
	is_selected = false
	if selection_indicator:
		selection_indicator.visible = false
	if health_bar and hp == max_hp:
		health_bar.visible = false
	emit_signal("unit_deselected", self)

func _find_nearest_enemy(radius: float) -> BaseUnit:
	var nearest = null
	var min_dist = radius
	var enemies = get_tree().get_nodes_in_group("enemy_units" if faction == UnitFaction.PLAYER else "player_units")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.state == UnitState.DEAD:
			continue
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _update_facing_direction(dir: Vector2):
	if not sprite:
		return
	# Simple flip based on x
	if dir.x < -5:
		sprite.flip_h = true
	elif dir.x > 5:
		sprite.flip_h = false

func is_military() -> bool:
	return unit_type != "villager"
