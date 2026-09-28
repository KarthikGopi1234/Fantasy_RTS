extends Node

# Resource Manager - Idle Auto-Battler Edition
# 5 Resources + Gems (premium) + auto generation + offline
signal resource_changed(resource_type: String, amount: int)
signal resource_warning(resource_type: String)
signal resource_floating(resource_type: String, amount: int, world_pos: Vector2)

var resources: Dictionary = {
	"food": 500,
	"wood": 400,
	"gold": 300,
	"mana": 200,
	"stone": 200,
	"gems": 50
}

var resource_caps: Dictionary = {
	"food": 10000,
	"wood": 10000,
	"gold": 10000,
	"mana": 5000,
	"stone": 10000,
	"gems": 999999
}

# Idle generation per second (base)
var base_gen_per_sec: Dictionary = {
	"food": 0.5,
	"wood": 0.0,
	"gold": 0.3,
	"mana": 0.1,
	"stone": 0.0,
	"gems": 0.0
}

# From buildings / villagers
var building_gen: Dictionary = {
	"food": 0.0,
	"wood": 0.0,
	"gold": 0.0,
	"mana": 0.0,
	"stone": 0.0,
	"gems": 0.0
}

var gather_modifiers: Dictionary = {
	"food": 1.0,
	"wood": 1.0,
	"gold": 1.0,
	"mana": 1.0,
	"stone": 1.0,
	"gems": 1.0
}

# Tap frenzy multiplier
var tap_frenzy_multiplier: float = 1.0
var tap_frenzy_timer: float = 0.0

# Offline multiplier (from Market etc)
var offline_multiplier: float = 1.0

func _ready():
	print("ResourceManager Idle initialized: ", resources)
	set_process(true)

func _process(delta):
	# Idle generation
	var total_gen: Dictionary = {}
	for res_type in base_gen_per_sec.keys():
		var gen = base_gen_per_sec[res_type] + building_gen.get(res_type, 0.0)
		gen *= gather_modifiers.get(res_type, 1.0)
		gen *= offline_multiplier if res_type != "gems" else 1.0
		if tap_frenzy_timer > 0:
			gen *= tap_frenzy_multiplier
		total_gen[res_type] = gen

	# Apply per second, but scaled to delta
	for res_type in total_gen.keys():
		if total_gen[res_type] > 0:
			var add = total_gen[res_type] * delta
			# Accumulate fractional via internal buffer - simplify to add when >=1 or keep float?
			# Use integer adding with fractional accumulator
			_add_fractional(res_type, add)

	if tap_frenzy_timer > 0:
		tap_frenzy_timer -= delta
		if tap_frenzy_timer <= 0:
			tap_frenzy_multiplier = 1.0
			tap_frenzy_timer = 0.0

# Fractional accumulator to avoid losing small gen
var _frac_buffer: Dictionary = {
	"food": 0.0, "wood": 0.0, "gold": 0.0, "mana": 0.0, "stone": 0.0, "gems": 0.0
}

func _add_fractional(type: String, amount: float):
	_frac_buffer[type] += amount
	var int_part = int(_frac_buffer[type])
	if int_part > 0:
		_frac_buffer[type] -= int_part
		add_resource(type, int_part)

func get_resource(type: String) -> int:
	return resources.get(type, 0)

func add_resource(type: String, amount: int) -> int:
	if not resources.has(type):
		return 0
	var new_amount = resources[type] + amount
	new_amount = clamp(new_amount, 0, resource_caps[type])
	var added = new_amount - resources[type]
	resources[type] = new_amount
	emit_signal("resource_changed", type, resources[type])
	return added

func add_resource_with_fx(type: String, amount: int, world_pos: Vector2 = Vector2.ZERO):
	var added = add_resource(type, amount)
	if added > 0 and world_pos != Vector2.ZERO:
		emit_signal("resource_floating", type, added, world_pos)
	return added

func can_afford(cost: Dictionary) -> bool:
	for res_type in cost.keys():
		if get_resource(res_type) < cost[res_type]:
			return false
	return true

func spend_resources(cost: Dictionary) -> bool:
	if not can_afford(cost):
		for res_type in cost.keys():
			if get_resource(res_type) < cost[res_type]:
				emit_signal("resource_warning", res_type)
		return false
	for res_type in cost.keys():
		resources[res_type] -= cost[res_type]
		emit_signal("resource_changed", res_type, resources[res_type])
	return true

func get_gather_rate(type: String) -> float:
	return gather_modifiers.get(type, 1.0)

func apply_gather_upgrade(type: String, multiplier: float):
	gather_modifiers[type] *= multiplier
	print("Gather upgrade: %s x%.2f" % [type, gather_modifiers[type]])

func get_all_resources() -> Dictionary:
	return resources.duplicate()

func get_total_resources() -> int:
	var total = 0
	for v in resources.values():
		total += v
	return total

func set_building_generation(res_type: String, amount_per_sec: float):
	building_gen[res_type] = amount_per_sec

func add_building_generation(res_type: String, amount_per_sec: float):
	building_gen[res_type] += amount_per_sec

func recalc_building_gen():
	# Recalculate based on buildings in world
	var new_gen = {"food":0.0,"wood":0.0,"gold":0.0,"mana":0.0,"stone":0.0,"gems":0.0}
	var buildings = get_tree().get_nodes_in_group("player_buildings")
	for b in buildings:
		if not is_instance_valid(b):
			continue
		if b.has_method("get_idle_generation"):
			var gen = b.get_idle_generation()
			for k in gen.keys():
				if new_gen.has(k):
					new_gen[k] += gen[k]
	# Town Hall base
	new_gen["food"] += 0.5
	new_gen["gold"] += 0.3
	building_gen = new_gen

func get_gen_per_sec(type: String) -> float:
	return (base_gen_per_sec.get(type,0.0) + building_gen.get(type,0.0)) * gather_modifiers.get(type,1.0)

func get_all_gen_per_sec() -> Dictionary:
	var result = {}
	for k in base_gen_per_sec.keys():
		result[k] = get_gen_per_sec(k)
	return result

func trigger_tap_frenzy(multiplier: float, duration: float):
	tap_frenzy_multiplier = multiplier
	tap_frenzy_timer = duration
	print("Tap Frenzy x%.1f for %.1fs" % [multiplier, duration])

func is_frenzy_active() -> bool:
	return tap_frenzy_timer > 0.0

func get_frenzy_time_left() -> float:
	return tap_frenzy_timer

# Offline earnings calculation
func calculate_offline_earnings(seconds: float) -> Dictionary:
	var earnings = {}
	var per_sec = get_all_gen_per_sec()
	for res_type in per_sec.keys():
		if res_type == "gems":
			continue
		var amount = int(per_sec[res_type] * seconds * offline_multiplier)
		# Cap at 12 hours
		amount = min(amount, int(per_sec[res_type] * 43200))
		if amount > 0:
			earnings[res_type] = amount
	return earnings

func apply_offline_earnings(earnings: Dictionary) -> int:
	var total = 0
	for res_type in earnings.keys():
		add_resource(res_type, earnings[res_type])
		total += earnings[res_type]
	return total
