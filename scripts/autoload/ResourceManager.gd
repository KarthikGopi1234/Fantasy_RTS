extends Node

# Resource Manager - AoE style with Fantasy twist
# 4 Resources: Food, Wood, Gold, Mana + Stone (5 total for ambitious)
# Emits signals on resource change

signal resource_changed(resource_type: String, amount: int)
signal resource_warning(resource_type: String)

var resources: Dictionary = {
	"food": 500,
	"wood": 400,
	"gold": 300,
	"mana": 200,
	"stone": 200
}

var resource_caps: Dictionary = {
	"food": 10000,
	"wood": 10000,
	"gold": 10000,
	"mana": 5000,
	"stone": 10000
}

var gather_rates: Dictionary = {
	"food": 8,
	"wood": 6,
	"gold": 5,
	"mana": 4,
	"stone": 5
}

# Tech modifiers
var gather_modifiers: Dictionary = {
	"food": 1.0,
	"wood": 1.0,
	"gold": 1.0,
	"mana": 1.0,
	"stone": 1.0
}

func _ready():
	print("ResourceManager initialized: ", resources)

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
	return gather_rates.get(type, 5) * gather_modifiers.get(type, 1.0)

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
