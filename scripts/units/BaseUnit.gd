extends CharacterBody2D
class_name BaseUnit

# BaseUnit - Idle Auto-Battler Edition
# No player micro - auto walks in lane, attacks nearest enemy, abilities auto

signal unit_died(unit)
signal unit_selected(unit)
signal unit_deselected(unit)

enum UnitState { IDLE, MOVING, ATTACKING, DEAD }
enum UnitFaction { PLAYER = 0, ENEMY = 1 }

@export var unit_type: String = "swordsman"
@export var faction: UnitFaction = UnitFaction.PLAYER

var max_hp: int = 60
var hp: int = 60
var attack_damage: int = 10
var armor: int = 1
var move_speed: float = 75.0
var attack_range: float = 45.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var state: UnitState = UnitState.IDLE
var is_selected: bool = false

# Auto-battler lane system
var lane: int = 1 # 0 top, 1 mid, 2 bottom
var move_direction: int = 1 # 1 = player goes right, -1 = enemy goes left
var target_unit: BaseUnit = null
var target_building: Node = null
var heal_amount: int = 0
var is_healer: bool = false
var is_flying: bool = false

# Visuals
var sprite: Sprite2D
var shadow: Sprite2D
var health_bar: ProgressBar
var selection_indicator: Node2D
var attack_effect: Node2D

func _ready():
	add_to_group("units")
	if faction == UnitFaction.PLAYER:
		add_to_group("player_units")
	else:
		add_to_group("enemy_units")
	
	# Load stats from TechTree
	if TechTree.unit_stats.has(unit_type):
		var stats = TechTree.unit_stats[unit_type]
		max_hp = stats.get("hp", 60)
		# Apply prestige warlord bonus
		var im = get_node_or_null("/root/IdleManager")
		if im:
			var lvl = im.get_prestige_upgrade_level("warlord_soul")
			max_hp = int(max_hp * (1.0 + lvl * 0.05))
			attack_damage = int(stats.get("attack", 10) * (1.0 + lvl * 0.05))
		else:
			attack_damage = stats.get("attack", 10)
		armor = stats.get("armor", 1)
		move_speed = float(stats.get("speed", 75))
		attack_range = float(stats.get("range", 45))
		heal_amount = stats.get("heal", 0)
		is_healer = heal_amount > 0
		is_flying = unit_type == "dragon"
	
	hp = max_hp
	
	_setup_visuals()
	
	# Set direction based on faction
	move_direction = 1 if faction == UnitFaction.PLAYER else -1
	
	state = UnitState.MOVING
	print("Unit spawned: %s lane %d faction %d at %s" % [unit_type, lane, faction, global_position])

func _setup_visuals():
	# Shadow
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.position = Vector2(0, 20)
	shadow.scale = Vector2(0.8, 0.4)
	shadow.modulate = Color(0,0,0,0.3)
	# Create simple shadow texture procedurally
	var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,1))
	var tex = ImageTexture.create_from_image(img)
	shadow.texture = tex
	add_child(shadow)
	
	# Main sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	var tex_path = "res://assets/sprites/units/%s.png" % unit_type
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		# Fallback colored rect
		var fimg = Image.create(48, 48, false, Image.FORMAT_RGBA8)
		var col = Color(0.8, 0.2, 0.2) if faction == UnitFaction.ENEMY else Color(0.2, 0.6, 0.9)
		match unit_type:
			"archer": col = Color(0.2, 0.8, 0.2)
			"knight": col = Color(0.8, 0.8, 0.2)
			"mage": col = Color(0.6, 0.2, 0.9)
			"golem": col = Color(0.5, 0.5, 0.5)
			"dragon": col = Color(0.9, 0.2, 0.2)
			"healer": col = Color(0.9, 0.9, 0.5)
		fimg.fill(col)
		var ftex = ImageTexture.create_from_image(fimg)
		sprite.texture = ftex
	
	sprite.scale = Vector2(1.2, 1.2) if unit_type in ["golem", "dragon", "knight"] else Vector2(1.0, 1.0)
	
	# Selection indicator (not used in idle but keep)
	selection_indicator = Node2D.new()
	selection_indicator.name = "Selection"
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	# Health bar
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(50, 6)
	health_bar.position = Vector2(-25, -38)
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.show_percentage = false
	# Style
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0,0,0,0.5)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2
	style_bg.corner_radius_bottom_right = 2
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.2, 0.9, 0.2) if faction == UnitFaction.PLAYER else Color(0.9, 0.2, 0.2)
	style_fg.corner_radius_top_left = 2
	style_fg.corner_radius_top_right = 2
	style_fg.corner_radius_bottom_left = 2
	style_fg.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", style_bg)
	health_bar.add_theme_stylebox_override("fill", style_fg)
	add_child(health_bar)

func _physics_process(delta):
	if state == UnitState.DEAD:
		return
	
	if attack_timer > 0:
		attack_timer -= delta
	
	match state:
		UnitState.IDLE:
			_process_idle(delta)
		UnitState.MOVING:
			_process_moving(delta)
		UnitState.ATTACKING:
			_process_attacking(delta)
	
	# Update health bar
	if health_bar:
		health_bar.value = hp
		health_bar.visible = hp < max_hp

func _process_idle(_delta):
	# Look for enemies
	var enemy = _find_nearest_enemy(attack_range + 150)
	if enemy:
		if enemy.global_position.distance_to(global_position) <= attack_range:
			target_unit = enemy
			state = UnitState.ATTACKING
		else:
			state = UnitState.MOVING
	else:
		state = UnitState.MOVING

func _process_moving(delta):
	# Find target
	var enemy = _find_nearest_enemy(300)
	
	if enemy:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_range:
			target_unit = enemy
			state = UnitState.ATTACKING
			velocity = Vector2.ZERO
			return
		# Move towards enemy if in same lane roughly
		if abs(enemy.global_position.y - global_position.y) < 80:
			var dir = global_position.direction_to(enemy.global_position)
			velocity = dir * move_speed
			_update_facing(dir)
			move_and_slide()
			return
	
	# No enemy nearby, move in lane direction
	velocity = Vector2(move_direction * move_speed, 0)
	move_and_slide()
	
	# Keep in lane (soft Y correction)
	var target_y = _get_lane_y(lane)
	var y_diff = target_y - global_position.y
	if abs(y_diff) > 5:
		velocity.y = clamp(y_diff * 2.0, -move_speed*0.5, move_speed*0.5)
		move_and_slide()
	
	# Despawn if out of bounds (reached end)
	if faction == UnitFaction.PLAYER and global_position.x > 1200:
		# Reached enemy base - damage base? For now just despawn and give reward if enemy
		queue_free()
		GameManager.add_population(-1)
	elif faction == UnitFaction.ENEMY and global_position.x < -200:
		# Reached player base - player takes damage? Simplified: despawn
		queue_free()
		# Could damage town hall

func _process_attacking(_delta):
	if is_healer:
		_process_healer()
		return
	
	if not target_unit or not is_instance_valid(target_unit) or target_unit.state == UnitState.DEAD:
		# Find new target
		var enemy = _find_nearest_enemy(attack_range + 10)
		if enemy:
			target_unit = enemy
		else:
			state = UnitState.MOVING
			target_unit = null
			return
	
	if not target_unit:
		state = UnitState.MOVING
		return
	
	var dist = global_position.distance_to(target_unit.global_position)
	if dist > attack_range + 15:
		# Chase
		var dir = global_position.direction_to(target_unit.global_position)
		velocity = dir * move_speed
		_update_facing(dir)
		move_and_slide()
		# If too far, go back to moving
		if dist > attack_range + 100:
			state = UnitState.MOVING
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			_perform_attack()
			attack_timer = attack_cooldown

func _process_healer():
	# Find injured ally
	var allies = get_tree().get_nodes_in_group("player_units" if faction == UnitFaction.PLAYER else "enemy_units")
	var injured = null
	var min_hp_ratio = 1.0
	for ally in allies:
		if not is_instance_valid(ally):
			continue
		if ally == self:
			continue
		if ally.state == UnitState.DEAD:
			continue
		if global_position.distance_to(ally.global_position) > attack_range:
			continue
		var ratio = float(ally.hp) / float(ally.max_hp)
		if ratio < 0.8 and ratio < min_hp_ratio:
			min_hp_ratio = ratio
			injured = ally
	
	if injured:
		if attack_timer <= 0:
			_heal_ally(injured)
			attack_timer = attack_cooldown * 1.5
	else:
		# No one to heal, behave like normal but stay back
		var enemy = _find_nearest_enemy(attack_range)
		if enemy:
			target_unit = enemy
			state = UnitState.ATTACKING
		else:
			state = UnitState.MOVING

func _heal_ally(ally: BaseUnit):
	ally.hp = min(ally.max_hp, ally.hp + heal_amount)
	# Heal effect
	if ally.sprite:
		var tween = create_tween()
		tween.tween_property(ally.sprite, "modulate", Color(0.5,1,0.5), 0.1)
		tween.tween_property(ally.sprite, "modulate", Color(1,1,1), 0.2)
	# Floating text
	_spawn_floating_text("+%d" % heal_amount, Color(0.2, 1, 0.2))

func _find_nearest_enemy(radius: float) -> BaseUnit:
	var nearest = null
	var min_dist = radius
	var enemies = get_tree().get_nodes_in_group("enemy_units" if faction == UnitFaction.PLAYER else "player_units")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.state == UnitState.DEAD:
			continue
		# Check lane proximity - prefer same lane
		if abs(e.lane - lane) > 1 and radius < 400:
			continue
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _get_lane_y(lane_idx: int) -> float:
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("get_lane_y"):
		return world.get_lane_y(lane_idx)
	# Fallback
	match lane_idx:
		0: return -180
		1: return 0
		2: return 180
		_: return 0

func _update_facing(dir: Vector2):
	if not sprite:
		return
	if dir.x < -5:
		sprite.flip_h = true
	elif dir.x > 5:
		sprite.flip_h = false

func _perform_attack():
	if not target_unit or not is_instance_valid(target_unit):
		return
	
	# Dragon breath AoE
	if unit_type == "dragon":
		_dragon_breath()
	else:
		target_unit.take_damage(attack_damage, self)
	
	# Attack anim
	if sprite:
		var orig_scale = sprite.scale
		var tween = create_tween()
		tween.tween_property(sprite, "scale", orig_scale * Vector2(1.3, 0.7), 0.08)
		tween.tween_property(sprite, "scale", orig_scale, 0.12)

func _dragon_breath():
	var enemies = get_tree().get_nodes_in_group("enemy_units" if faction == UnitFaction.PLAYER else "player_units")
	var hit_count = 0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.state == UnitState.DEAD:
			continue
		if global_position.distance_to(e.global_position) < 120:
			e.take_damage(int(attack_damage * 0.7), self)
			hit_count += 1
			if hit_count >= 3:
				break
	# Still damage main target full
	if target_unit and is_instance_valid(target_unit):
		target_unit.take_damage(attack_damage, self)

func take_damage(amount: int, attacker: BaseUnit = null):
	var actual_damage = max(1, amount - armor)
	hp -= actual_damage
	hp = max(0, hp)
	
	_spawn_floating_text("-%d" % actual_damage, Color(1, 0.2, 0.2))
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1,0.3,0.3), 0.05)
		tween.tween_property(sprite, "modulate", Color(1,1,1), 0.1)
	
	if hp <= 0:
		die()
	elif attacker and state == UnitState.MOVING:
		# Aggro
		if global_position.distance_to(attacker.global_position) < 200:
			target_unit = attacker
			state = UnitState.ATTACKING

func _spawn_floating_text(text: String, color: Color):
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("spawn_floating_text"):
		world.spawn_floating_text(text, global_position + Vector2(0, -40), color)

func die():
	state = UnitState.DEAD
	emit_signal("unit_died", self)
	
	if faction == UnitFaction.PLAYER:
		GameManager.add_population(-1)
	else:
		GameManager.enemies_defeated += 1
		GameManager.enemies_remaining -= 1
		# Small gold reward on kill
		ResourceManager.add_resource("gold", 2 + int(GameManager.wave * 0.5))
	
	# Death animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,0), 0.4)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.1,0.1), 0.4)
	tween.tween_callback(queue_free)
	
	#print("%s died" % unit_type)

# Compatibility methods (old RTS API - no longer used but keep to avoid errors)
func select():
	is_selected = true
	if selection_indicator:
		selection_indicator.visible = true
	emit_signal("unit_selected", self)

func deselect():
	is_selected = false
	if selection_indicator:
		selection_indicator.visible = false
	emit_signal("unit_deselected", self)

func move_to(_pos: Vector2):
	# Deprecated in idle mode - units auto move
	pass

func attack_unit(unit: BaseUnit):
	target_unit = unit
	state = UnitState.ATTACKING

func gather_resource(_resource_node: Node, _res_type: String):
	# Villagers auto-gather in idle mode via building gen
	pass

func is_military() -> bool:
	return unit_type != "villager"
