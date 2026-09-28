extends Node

# Tech Tree - Idle Auto-Battler Edition
# 3 Ages + Idle Techs

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

# Building unlocks per age - keep 8 buildings
var building_unlocks: Dictionary = {
	Age.VILLAGE: ["town_hall", "house", "barracks", "lumber_camp"],
	Age.KINGDOM: ["archery", "stable", "market", "wall"],
	Age.MYTHIC: ["mage_tower"]
}

# Unit unlocks per age - keep 8 units
var unit_unlocks: Dictionary = {
	Age.VILLAGE: ["villager", "swordsman"],
	Age.KINGDOM: ["archer", "knight", "healer"],
	Age.MYTHIC: ["mage", "golem", "dragon"]
}

# Tech definitions - Economy + Military + Idle
var techs: Dictionary = {
	# Economy - idle gen
	"wheelbarrow": {"name": "Wheelbarrow", "desc": "Villagers +15% speed, Food +20%", "age": Age.VILLAGE, "cost": {"food": 100, "wood": 50}, "effect": "food_gen+20%", "researched": false, "category": "economy"},
	"double_bit_axe": {"name": "Double-Bit Axe", "desc": "Wood +25% idle", "age": Age.VILLAGE, "cost": {"food": 100, "wood": 100}, "effect": "wood_gather+25%", "researched": false, "category": "economy"},
	"gold_mining": {"name": "Gold Mining", "desc": "Gold +20% idle", "age": Age.VILLAGE, "cost": {"food": 100, "wood": 75}, "effect": "gold_gather+20%", "researched": false, "category": "economy"},
	"stone_quarry": {"name": "Stone Quarry", "desc": "Stone +30% idle", "age": Age.VILLAGE, "cost": {"food": 150, "wood": 100}, "effect": "stone+30%", "researched": false, "category": "economy"},
	"mana_attunement": {"name": "Mana Attunement", "desc": "Mana +30% idle", "age": Age.KINGDOM, "cost": {"gold": 200, "mana": 100}, "effect": "mana_gather+30%", "researched": false, "category": "economy"},
	
	# Military
	"forging": {"name": "Forging", "desc": "Infantry +3 ATK", "age": Age.VILLAGE, "cost": {"food": 150, "gold": 50}, "effect": "infantry_attack+3", "researched": false, "category": "military"},
	"scale_armor": {"name": "Scale Armor", "desc": "Infantry +2 Armor, +20 HP", "age": Age.VILLAGE, "cost": {"food": 100, "gold": 100}, "effect": "infantry_armor+2", "researched": false, "category": "military"},
	"fletching": {"name": "Fletching", "desc": "Archers +3 ATK, +20 Range", "age": Age.KINGDOM, "cost": {"food": 100, "gold": 150}, "effect": "archer_attack+3", "researched": false, "category": "military"},
	"bloodlines": {"name": "Bloodlines", "desc": "Knights +30 HP", "age": Age.KINGDOM, "cost": {"food": 150, "gold": 100}, "effect": "cavalry_hp+30", "researched": false, "category": "military"},
	"arcane_mastery": {"name": "Arcane Mastery", "desc": "Mages +50% DMG", "age": Age.MYTHIC, "cost": {"gold": 300, "mana": 400}, "effect": "mage_damage+50%", "researched": false, "category": "military"},
	"dragon_taming": {"name": "Dragon Taming", "desc": "Unlock Dragon, +25% Dragon HP", "age": Age.MYTHIC, "cost": {"food": 500, "gold": 500, "mana": 600}, "effect": "unlock_dragon", "researched": false, "category": "military"},
	"golem_forging": {"name": "Golem Forging", "desc": "Golems +50 HP +5 ATK", "age": Age.MYTHIC, "cost": {"stone": 300, "mana": 300, "gold": 200}, "effect": "golem+50hp", "researched": false, "category": "military"},
	"healing_light": {"name": "Healing Light", "desc": "Healers heal +50%", "age": Age.KINGDOM, "cost": {"food": 100, "mana": 150, "gold": 100}, "effect": "heal+50%", "researched": false, "category": "military"},
	
	# Idle Techs - NEW
	"offline_earnings": {"name": "Offline Earnings I", "desc": "Offline +25%", "age": Age.VILLAGE, "cost": {"gold": 200, "wood": 100}, "effect": "offline+25%", "researched": false, "category": "idle"},
	"offline_earnings_2": {"name": "Offline Earnings II", "desc": "Offline +50% (total +75%)", "age": Age.KINGDOM, "cost": {"gold": 500, "mana": 100}, "effect": "offline+50%", "researched": false, "category": "idle"},
	"auto_queue": {"name": "Auto-Queue", "desc": "Buildings auto-train units", "age": Age.VILLAGE, "cost": {"food": 200, "gold": 100}, "effect": "auto_queue", "researched": false, "category": "idle"},
	"auto_queue_2": {"name": "Efficient Production", "desc": "Auto-queue 20% faster", "age": Age.KINGDOM, "cost": {"food": 300, "gold": 300, "wood": 200}, "effect": "auto_queue_speed+20%", "researched": false, "category": "idle"},
	"tap_frenzy": {"name": "Tap Frenzy", "desc": "Unlock tap frenzy (25 taps)", "age": Age.VILLAGE, "cost": {"food": 100, "gold": 100}, "effect": "tap_frenzy", "researched": false, "category": "idle"},
	"tap_frenzy_2": {"name": "Frenzy Mastery", "desc": "Tap frenzy x4 instead of x3, +5 sec", "age": Age.KINGDOM, "cost": {"gold": 400, "mana": 200}, "effect": "frenzy+bonus", "researched": false, "category": "idle"},
	"chest_luck": {"name": "Chest Luck", "desc": "+15% rare chest chance", "age": Age.VILLAGE, "cost": {"gold": 300, "gems": 10}, "effect": "chest+15%", "researched": false, "category": "idle"},
	"market_efficiency": {"name": "Market Efficiency", "desc": "Market offline x1.5, gen +20%", "age": Age.KINGDOM, "cost": {"gold": 300, "wood": 200, "stone": 100}, "effect": "market+20%", "researched": false, "category": "idle"},
}

var unit_stats: Dictionary = {
	"villager": {"hp": 40, "attack": 4, "armor": 0, "speed": 90, "cost": {"food": 50}, "role": "gather", "range": 40},
	"swordsman": {"hp": 80, "attack": 15, "armor": 2, "speed": 75, "cost": {"food": 60, "gold": 20}, "role": "melee", "range": 45},
	"archer": {"hp": 50, "attack": 12, "armor": 0, "speed": 80, "cost": {"wood": 25, "gold": 45}, "range": 140, "role": "ranged"},
	"knight": {"hp": 150, "attack": 22, "armor": 3, "speed": 100, "cost": {"food": 60, "gold": 75}, "role": "melee", "range": 50},
	"healer": {"hp": 60, "attack": 0, "armor": 0, "speed": 85, "cost": {"food": 40, "gold": 60, "mana": 20}, "heal": 15, "role": "healer", "range": 120},
	"mage": {"hp": 65, "attack": 30, "armor": 0, "speed": 75, "cost": {"food": 40, "gold": 80, "mana": 60}, "range": 160, "role": "ranged"},
	"golem": {"hp": 300, "attack": 35, "armor": 5, "speed": 50, "cost": {"stone": 100, "mana": 80, "gold": 50}, "role": "tank", "range": 50},
	"dragon": {"hp": 450, "attack": 50, "armor": 4, "speed": 90, "cost": {"food": 200, "gold": 200, "mana": 150}, "range": 120, "role": "flying"},
}

var building_stats: Dictionary = {
	"town_hall": {"hp": 1500, "cost": {"wood": 300, "stone": 100}, "pop": 5, "gen": {"food": 0.8, "gold": 0.5}, "desc": "Heart of empire, tap for frenzy"},
	"house": {"hp": 400, "cost": {"wood": 50}, "pop": 5, "gen": {"food": 0.2}, "desc": "+5 Pop, +Food"},
	"barracks": {"hp": 800, "cost": {"wood": 150}, "pop": 0, "gen": {}, "desc": "Auto Swordsmen"},
	"archery": {"hp": 700, "cost": {"wood": 175}, "pop": 0, "gen": {}, "desc": "Auto Archers"},
	"stable": {"hp": 800, "cost": {"wood": 200, "gold": 50}, "pop": 0, "gen": {}, "desc": "Auto Knights"},
	"mage_tower": {"hp": 1000, "cost": {"wood": 200, "stone": 200, "mana": 100}, "pop": 0, "gen": {"mana": 0.5}, "desc": "Auto Mages + Mana"},
	"wall": {"hp": 800, "cost": {"stone": 30}, "pop": 0, "gen": {}, "desc": "Defense, blocks lane"},
	"market": {"hp": 600, "cost": {"wood": 150, "gold": 50}, "pop": 0, "gen": {"gold": 0.4}, "desc": "Gold + Offline x1.2"},
	"lumber_camp": {"hp": 500, "cost": {"wood": 100}, "pop": 0, "gen": {"wood": 0.6}, "desc": "Wood generation"},
}

func _ready():
	print("TechTree Idle initialized - Age: ", age_names[current_age])

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
			# Special check for dragon
			if unit_id == "dragon" and not techs["dragon_taming"]["researched"]:
				# Still locked until tech? Actually allow at mythic even without tech but weaker
				pass
			return true
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
			ResourceManager.apply_gather_upgrade("food", 1.2)
		"double_bit_axe":
			ResourceManager.apply_gather_upgrade("wood", 1.25)
		"gold_mining":
			ResourceManager.apply_gather_upgrade("gold", 1.2)
		"stone_quarry":
			ResourceManager.apply_gather_upgrade("stone", 1.3)
		"mana_attunement":
			ResourceManager.apply_gather_upgrade("mana", 1.3)
		"forging":
			for unit in ["swordsman", "knight"]:
				if unit_stats.has(unit):
					unit_stats[unit]["attack"] += 3
		"scale_armor":
			for unit in ["swordsman", "knight", "golem"]:
				if unit_stats.has(unit):
					unit_stats[unit]["armor"] += 2
					unit_stats[unit]["hp"] += 20
		"fletching":
			if unit_stats.has("archer"):
				unit_stats["archer"]["attack"] += 3
				unit_stats["archer"]["range"] += 20
		"bloodlines":
			if unit_stats.has("knight"):
				unit_stats["knight"]["hp"] += 30
		"arcane_mastery":
			if unit_stats.has("mage"):
				unit_stats["mage"]["attack"] = int(unit_stats["mage"]["attack"] * 1.5)
		"dragon_taming":
			if unit_stats.has("dragon"):
				unit_stats["dragon"]["hp"] += int(unit_stats["dragon"]["hp"] * 0.25)
		"golem_forging":
			if unit_stats.has("golem"):
				unit_stats["golem"]["hp"] += 50
				unit_stats["golem"]["attack"] += 5
		"healing_light":
			if unit_stats.has("healer"):
				unit_stats["healer"]["heal"] = int(unit_stats["healer"]["heal"] * 1.5)
		"offline_earnings":
			ResourceManager.offline_multiplier += 0.25
		"offline_earnings_2":
			ResourceManager.offline_multiplier += 0.5
		"auto_queue":
			GameManager.set_auto_queue_enabled(true)
		"auto_queue_2":
			# Speed handled via building queue timer multiplier
			pass
		"tap_frenzy":
			GameManager.tap_frenzy_enabled = true
		"tap_frenzy_2":
			if get_node_or_null("/root/IdleManager"):
				get_node("/root/IdleManager").tap_frenzy_threshold = 20
		"chest_luck":
			if get_node_or_null("/root/IdleManager"):
				get_node("/root/IdleManager").chest_chance_bonus += 0.15
		"market_efficiency":
			ResourceManager.offline_multiplier += 0.2
			ResourceManager.apply_gather_upgrade("gold", 1.2)

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
				available.append(unit)
	return available

func get_techs_by_category(cat: String) -> Array:
	var result = []
	for id in techs.keys():
		if techs[id].get("category", "") == cat:
			result.append(id)
	return result

func get_age_progress() -> float:
	return float(current_age) / float(Age.MYTHIC)

func get_unit_cost_string(unit_id: String) -> String:
	if not unit_stats.has(unit_id):
		return ""
	var cost = unit_stats[unit_id].get("cost", {})
	var parts = []
	for k in cost.keys():
		parts.append("%d %s" % [cost[k], k.substr(0,1).to_upper() + k.substr(1)])
	return ", ".join(parts)

func get_building_cost_string(building_id: String) -> String:
	if not building_stats.has(building_id):
		return ""
	var cost = building_stats[building_id].get("cost", {})
	var parts = []
	for k in cost.keys():
		parts.append("%d %s" % [cost[k], k.substr(0,1).to_upper() + k.substr(1)])
	return ", ".join(parts)
