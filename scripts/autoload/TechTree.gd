extends Node

# Tech Tree - Fantasy AoE progression
# 3 Ages: Village -> Kingdom -> Mythic
# Each age unlocks buildings, units, and upgrades

signal age_advanced(new_age: int)
signal tech_researched(tech_id: String)

enum Age {
	VILLAGE = 0,
	KINGDOM = 1,
	MYTHIC = 2
}

var current_age: int = Age.VILLAGE

var age_names: Dictionary = {
	Age.VILLAGE: "Village Age",
	Age.KINGDOM: "Kingdom Age",
	Age.MYTHIC: "Mythic Age"
}

var age_costs: Dictionary = {
	Age.KINGDOM: {"food": 500, "gold": 300, "mana": 100},
	Age.MYTHIC: {"food": 1000, "gold": 800, "mana": 500, "stone": 400}
}

# Building unlocks per age
var building_unlocks: Dictionary = {
	Age.VILLAGE: ["town_hall", "house", "barracks", "lumber_camp"],
	Age.KINGDOM: ["archery", "stable", "market", "wall"],
	Age.MYTHIC: ["mage_tower"]
}

# Unit unlocks per age
var unit_unlocks: Dictionary = {
	Age.VILLAGE: ["villager", "swordsman"],
	Age.KINGDOM: ["archer", "knight", "healer"],
	Age.MYTHIC: ["mage", "golem", "dragon"]
}

# Tech definitions
var techs: Dictionary = {
	# Economy
	"wheelbarrow": {"name": "Wheelbarrow", "age": Age.VILLAGE, "cost": {"food": 100, "wood": 50}, "effect": "villager_speed+15%", "researched": false},
	"double_bit_axe": {"name": "Double-Bit Axe", "age": Age.VILLAGE, "cost": {"food": 100, "wood": 100}, "effect": "wood_gather+20%", "researched": false},
	"gold_mining": {"name": "Gold Mining", "age": Age.VILLAGE, "cost": {"food": 100, "wood": 75}, "effect": "gold_gather+15%", "researched": false},
	"mana_attunement": {"name": "Mana Attunement", "age": Age.KINGDOM, "cost": {"gold": 200, "mana": 100}, "effect": "mana_gather+25%", "researched": false},
	
	# Military
	"forging": {"name": "Forging", "age": Age.VILLAGE, "cost": {"food": 150, "gold": 50}, "effect": "infantry_attack+2", "researched": false},
	"scale_armor": {"name": "Scale Armor", "age": Age.VILLAGE, "cost": {"food": 100, "gold": 100}, "effect": "infantry_armor+1", "researched": false},
	"fletching": {"name": "Fletching", "age": Age.KINGDOM, "cost": {"food": 100, "gold": 150}, "effect": "archer_attack+2", "researched": false},
	"bloodlines": {"name": "Bloodlines", "age": Age.KINGDOM, "cost": {"food": 150, "gold": 100}, "effect": "cavalry_hp+20", "researched": false},
	"arcane_mastery": {"name": "Arcane Mastery", "age": Age.MYTHIC, "cost": {"gold": 300, "mana": 400}, "effect": "mage_damage+50%", "researched": false},
	"dragon_taming": {"name": "Dragon Taming", "age": Age.MYTHIC, "cost": {"food": 500, "gold": 500, "mana": 600}, "effect": "unlock_dragon", "researched": false},
}

var unit_stats: Dictionary = {
	"villager": {"hp": 40, "attack": 4, "armor": 0, "speed": 90, "cost": {"food": 50}},
	"swordsman": {"hp": 60, "attack": 12, "armor": 1, "speed": 85, "cost": {"food": 60, "gold": 20}},
	"archer": {"hp": 45, "attack": 8, "armor": 0, "speed": 90, "cost": {"wood": 25, "gold": 45}, "range": 120},
	"knight": {"hp": 120, "attack": 18, "armor": 2, "speed": 110, "cost": {"food": 60, "gold": 75}},
	"healer": {"hp": 50, "attack": -10, "armor": 0, "speed": 85, "cost": {"food": 40, "gold": 60, "mana": 20}, "heal": 10},
	"mage": {"hp": 55, "attack": 25, "armor": 0, "speed": 80, "cost": {"food": 40, "gold": 80, "mana": 60}, "range": 140},
	"golem": {"hp": 250, "attack": 30, "armor": 4, "speed": 60, "cost": {"stone": 100, "mana": 80, "gold": 50}},
	"dragon": {"hp": 400, "attack": 45, "armor": 3, "speed": 100, "cost": {"food": 200, "gold": 200, "mana": 150}, "range": 100},
}

var building_stats: Dictionary = {
	"town_hall": {"hp": 1500, "cost": {"wood": 300, "stone": 100}, "pop": 5},
	"house": {"hp": 400, "cost": {"wood": 50}, "pop": 5},
	"barracks": {"hp": 800, "cost": {"wood": 150}, "pop": 0},
	"archery": {"hp": 700, "cost": {"wood": 175}, "pop": 0},
	"stable": {"hp": 800, "cost": {"wood": 200, "gold": 50}, "pop": 0},
	"mage_tower": {"hp": 1000, "cost": {"wood": 200, "stone": 200, "mana": 100}, "pop": 0},
	"wall": {"hp": 600, "cost": {"stone": 20}, "pop": 0},
	"market": {"hp": 600, "cost": {"wood": 150, "gold": 50}, "pop": 0},
	"lumber_camp": {"hp": 500, "cost": {"wood": 100}, "pop": 0},
}

func _ready():
	print("TechTree initialized - Age: ", age_names[current_age])

func can_advance_age() -> bool:
	var next_age = current_age + 1
	if next_age > Age.MYTHIC:
		return false
	if not age_costs.has(next_age):
		return false
	return ResourceManager.can_afford(age_costs[next_age])

func advance_age() -> bool:
	var next_age = current_age + 1
	if next_age > Age.MYTHIC:
		return false
	if not ResourceManager.spend_resources(age_costs[next_age]):
		return false
	
	current_age = next_age
	emit_signal("age_advanced", current_age)
	print("Advanced to ", age_names[current_age])
	return true

func is_building_unlocked(building_id: String) -> bool:
	for age in range(current_age + 1):
		if building_unlocks.has(age) and building_id in building_unlocks[age]:
			return true
	return false

func is_unit_unlocked(unit_id: String) -> bool:
	for age in range(current_age + 1):
		if unit_unlocks.has(age) and unit_id in unit_unlocks[age]:
			return true
	# Check if special tech unlocks it
	if unit_id == "dragon" and not techs["dragon_taming"]["researched"]:
		return false
	return false

func can_research(tech_id: String) -> bool:
	if not techs.has(tech_id):
		return false
	var tech = techs[tech_id]
	if tech["researched"]:
		return false
	if tech["age"] > current_age:
		return false
	return ResourceManager.can_afford(tech["cost"])

func research_tech(tech_id: String) -> bool:
	if not can_research(tech_id):
		return false
	
	var tech = techs[tech_id]
	if not ResourceManager.spend_resources(tech["cost"]):
		return false
	
	tech["researched"] = true
	_apply_tech_effect(tech_id)
	emit_signal("tech_researched", tech_id)
	print("Researched: ", tech["name"])
	return true

func _apply_tech_effect(tech_id: String):
	match tech_id:
		"wheelbarrow":
			# Villager speed handled in unit
			pass
		"double_bit_axe":
			ResourceManager.apply_gather_upgrade("wood", 1.2)
		"gold_mining":
			ResourceManager.apply_gather_upgrade("gold", 1.15)
		"mana_attunement":
			ResourceManager.apply_gather_upgrade("mana", 1.25)
		"forging":
			for unit in ["swordsman", "knight"]:
				if unit_stats.has(unit):
					unit_stats[unit]["attack"] += 2
		"scale_armor":
			for unit in ["swordsman", "knight"]:
				if unit_stats.has(unit):
					unit_stats[unit]["armor"] += 1
		"fletching":
			if unit_stats.has("archer"):
				unit_stats["archer"]["attack"] += 2
		"bloodlines":
			if unit_stats.has("knight"):
				unit_stats["knight"]["hp"] += 20
		"arcane_mastery":
			if unit_stats.has("mage"):
				unit_stats["mage"]["attack"] = int(unit_stats["mage"]["attack"] * 1.5)

func get_available_buildings() -> Array:
	var available = []
	for age in range(current_age + 1):
		if building_unlocks.has(age):
			available.append_array(building_unlocks[age])
	return available

func get_available_units() -> Array:
	var available = []
	for age in range(current_age + 1):
		if unit_unlocks.has(age):
			for unit in unit_unlocks[age]:
				if is_unit_unlocked(unit):
					available.append(unit)
	return available

func get_age_progress() -> float:
	return float(current_age) / float(Age.MYTHIC)
