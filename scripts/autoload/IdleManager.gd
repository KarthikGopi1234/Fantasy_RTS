extends Node

# IdleManager - Handles offline, chests, daily rewards, prestige, auto-queue, tap frenzy

signal offline_earnings_ready(earnings: Dictionary, seconds: int)
signal chest_opened(chest_type: String, rewards: Dictionary)
signal daily_reward_claimed(day: int, rewards: Dictionary)
signal prestige_ready(prestige_points: int)
signal quest_completed(quest_id: String)
signal tap_frenzy_started(multiplier: float, duration: float)

# --- Offline ---
var last_save_timestamp: int = 0
var offline_cap_seconds: int = 43200 # 12 hours

# --- Chests ---
enum ChestType { COMMON, RARE, EPIC, MYTHIC }
var chest_names = ["Common", "Rare", "Epic", "Mythic"]
var chest_costs = {
	ChestType.COMMON: {"gold": 100},
	ChestType.RARE: {"gold": 400, "gems": 10},
	ChestType.EPIC: {"gold": 1000, "gems": 40},
	ChestType.MYTHIC: {"gems": 150}
}
var chest_rewards_base = {
	ChestType.COMMON: {"gold": 150, "food": 100, "wood": 80},
	ChestType.RARE: {"gold": 600, "mana": 100, "gems": 15, "wood": 200},
	ChestType.EPIC: {"gold": 1500, "mana": 300, "gems": 50, "stone": 300},
	ChestType.MYTHIC: {"gems": 200, "mana": 800, "gold": 3000}
}
var chest_chance_bonus: float = 0.0 # from techs

# --- Daily Rewards ---
var daily_streak: int = 0
var last_daily_claim_timestamp: int = 0
var daily_rewards = [
	{"gold": 200, "food": 200},
	{"gold": 400, "wood": 200},
	{"gold": 600, "gems": 10},
	{"gold": 800, "mana": 150},
	{"gold": 1000, "gems": 25, "stone": 200},
	{"gold": 1500, "gems": 40, "mana": 300},
	{"gems": 100, "gold": 2000, "mana": 500} # day 7 mega
]

# --- Daily Quests ---
var daily_quests: Array = []
var quest_templates = [
	{"id": "defeat_waves", "name": "Defeat 10 Waves", "target": 10, "reward": {"gold": 300, "gems": 10}},
	{"id": "build_buildings", "name": "Build 3 Buildings", "target": 3, "reward": {"wood": 200, "gold": 200}},
	{"id": "train_units", "name": "Train 20 Units", "target": 20, "reward": {"food": 300, "gems": 5}},
	{"id": "collect_gold", "name": "Collect 1000 Gold", "target": 1000, "reward": {"gems": 10}},
	{"id": "tap_frenzy", "name": "Trigger Tap Frenzy 3x", "target": 3, "reward": {"mana": 200, "gold": 400}},
	{"id": "open_chests", "name": "Open 2 Chests", "target": 2, "reward": {"gems": 15, "gold": 500}}
]

# --- Prestige ---
var prestige_points: int = 0
var total_prestige_earned: int = 0
var prestige_multiplier: float = 1.0
var prestige_threshold_gold: int = 10000
var mythic_essence: int = 0

# Prestige upgrades (permanent)
var prestige_upgrades: Dictionary = {
	"eternal_harvest": {"name": "Eternal Harvest", "level": 0, "max": 10, "cost": 1, "effect": "food+10% per level"},
	"midas_touch": {"name": "Midas Touch", "level": 0, "max": 10, "cost": 1, "effect": "gold+10%"},
	"arcane_legacy": {"name": "Arcane Legacy", "level": 0, "max": 10, "cost": 2, "effect": "mana+15%"},
	"master_builder": {"name": "Master Builder", "level": 0, "max": 5, "cost": 3, "effect": "build speed+20%"},
	"warlord_soul": {"name": "Warlord Soul", "level": 0, "max": 10, "cost": 2, "effect": "unit HP+5% ATK+5%"},
	"offline_mastery": {"name": "Offline Mastery", "level": 0, "max": 5, "cost": 3, "effect": "offline +25%"},
	"starting_boost": {"name": "Starting Boost", "level": 0, "max": 5, "cost": 2, "effect": "start with extra resources"}
}

# --- Tap Frenzy ---
var tap_count: int = 0
var tap_frenzy_threshold: int = 25
var tap_frenzy_active: bool = false

# --- Achievements ---
var achievements: Dictionary = {
	"first_blood": {"name": "First Blood", "desc": "Defeat first wave", "done": false, "reward": {"gems": 10}},
	"builder": {"name": "Builder", "desc": "Build 10 buildings", "done": false, "reward": {"gems": 20, "gold": 500}},
	"army_100": {"name": "Legion", "desc": "Train 100 units", "done": false, "reward": {"gems": 30}},
	"wave_25": {"name": "Veteran", "desc": "Reach wave 25", "done": false, "reward": {"gems": 50, "mana": 500}},
	"wave_50": {"name": "Mythic Slayer", "desc": "Reach wave 50", "done": false, "reward": {"gems": 100}},
	"prestige_1": {"name": "Reborn", "desc": "Prestige once", "done": false, "reward": {"gems": 100}},
	"tap_1000": {"name": "Tapping Master", "desc": "Tap 1000 times", "done": false, "reward": {"gems": 20}},
	"chest_10": {"name": "Treasure Hunter", "desc": "Open 10 chests", "done": false, "reward": {"gems": 30}}
}
var stats_taps: int = 0
var stats_chests_opened: int = 0

func _ready():
	print("IdleManager initialized - Full idle progression")
	_generate_daily_quests()
	load_idle_data()
	# Check offline on start (will be called after SaveManager loads too)
	_check_offline_earnings.call_deferred()

func _check_offline_earnings():
	var now = int(Time.get_unix_time_from_system())
	if last_save_timestamp > 0:
		var diff = now - last_save_timestamp
		if diff > 30: # at least 30 sec away
			diff = min(diff, offline_cap_seconds)
			var earnings = ResourceManager.calculate_offline_earnings(float(diff))
			if earnings.size() > 0:
				print("Offline for %d sec, earnings: %s" % [diff, earnings])
				emit_signal("offline_earnings_ready", earnings, diff)

func save_idle_data():
	var data = {
		"last_save_timestamp": int(Time.get_unix_time_from_system()),
		"daily_streak": daily_streak,
		"last_daily_claim": last_daily_claim_timestamp,
		"daily_quests": daily_quests,
		"prestige_points": prestige_points,
		"total_prestige": total_prestige_earned,
		"prestige_multiplier": prestige_multiplier,
		"mythic_essence": mythic_essence,
		"prestige_upgrades": prestige_upgrades,
		"achievements": achievements,
		"stats_taps": stats_taps,
		"stats_chests": stats_chests_opened,
		"chest_bonus": chest_chance_bonus
	}
	var file = FileAccess.open("user://idle_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_idle_data():
	if not FileAccess.file_exists("user://idle_data.json"):
		return
	var file = FileAccess.open("user://idle_data.json", FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data = json.data
	file.close()
	last_save_timestamp = data.get("last_save_timestamp", 0)
	daily_streak = data.get("daily_streak", 0)
	last_daily_claim_timestamp = data.get("last_daily_claim", 0)
	if data.has("daily_quests"):
		daily_quests = data["daily_quests"]
	prestige_points = data.get("prestige_points", 0)
	total_prestige_earned = data.get("total_prestige", 0)
	prestige_multiplier = data.get("prestige_multiplier", 1.0)
	mythic_essence = data.get("mythic_essence", 0)
	if data.has("prestige_upgrades"):
		# merge to keep new upgrades
		for k in data["prestige_upgrades"].keys():
			if prestige_upgrades.has(k):
				prestige_upgrades[k] = data["prestige_upgrades"][k]
	if data.has("achievements"):
		for k in data["achievements"].keys():
			if achievements.has(k):
				achievements[k] = data["achievements"][k]
	stats_taps = data.get("stats_taps", 0)
	stats_chests_opened = data.get("stats_chests", 0)
	chest_chance_bonus = data.get("chest_bonus", 0.0)
	print("Idle data loaded, streak %d, prestige %d" % [daily_streak, prestige_points])

# --- Chests ---
func can_open_chest(chest_type: int) -> bool:
	var cost = chest_costs.get(chest_type, {})
	return ResourceManager.can_afford(cost)

func open_chest(chest_type: int) -> Dictionary:
	if not can_open_chest(chest_type):
		return {}
	var cost = chest_costs[chest_type]
	ResourceManager.spend_resources(cost)
	var base = chest_rewards_base[chest_type].duplicate()
	# Apply bonuses and randomness
	var rewards = {}
	for k in base.keys():
		var amt = base[k]
		# Random 0.8x to 1.5x
		amt = int(amt * randf_range(0.8, 1.5) * prestige_multiplier)
		rewards[k] = amt
	# Rare bonus chance for gems
	if chest_type >= ChestType.RARE and randf() < (0.15 + chest_chance_bonus):
		rewards["gems"] = rewards.get("gems", 0) + randi_range(5, 20)

	# Give rewards
	for k in rewards.keys():
		ResourceManager.add_resource(k, rewards[k])

	stats_chests_opened += 1
	_update_quest("open_chests", 1)
	_check_achievement("chest_10", stats_chests_opened >= 10)

	emit_signal("chest_opened", chest_names[chest_type], rewards)
	print("Opened %s chest: %s" % [chest_names[chest_type], rewards])
	save_idle_data()
	return rewards

func get_chest_cost_str(chest_type: int) -> String:
	var cost = chest_costs.get(chest_type, {})
	var parts = []
	for k in cost.keys():
		parts.append("%d %s" % [cost[k], k])
	return ", ".join(parts)

# --- Daily ---
func can_claim_daily() -> bool:
	var now = int(Time.get_unix_time_from_system())
	var last = last_daily_claim_timestamp
	# 20 hours cooldown to allow some slack
	return (now - last) >= 20*3600

func claim_daily_reward() -> Dictionary:
	if not can_claim_daily():
		return {}
	var day_index = daily_streak % daily_rewards.size()
	var rewards = daily_rewards[day_index].duplicate()
	# Give
	for k in rewards.keys():
		ResourceManager.add_resource(k, rewards[k])

	daily_streak += 1
	last_daily_claim_timestamp = int(Time.get_unix_time_from_system())
	emit_signal("daily_reward_claimed", daily_streak, rewards)
	print("Daily day %d claimed: %s" % [daily_streak, rewards])
	save_idle_data()
	return rewards

func get_next_daily_reward() -> Dictionary:
	var day_index = daily_streak % daily_rewards.size()
	return daily_rewards[day_index]

# --- Quests ---
func _generate_daily_quests():
	if daily_quests.size() > 0:
		# Check if still same day - for now always regenerate if empty or all done
		var all_done = true
		for q in daily_quests:
			if not q.get("completed", false):
				all_done = false
				break
		if not all_done:
			return
	# Generate 3 random quests
	daily_quests = []
	var templates = quest_templates.duplicate()
	templates.shuffle()
	for i in range(min(3, templates.size())):
		var t = templates[i].duplicate(true)
		t["progress"] = 0
		t["completed"] = false
		daily_quests.append(t)
	print("Generated daily quests: ", daily_quests)

func _update_quest(quest_id: String, amount: int = 1):
	for q in daily_quests:
		if q["id"] == quest_id and not q["completed"]:
			q["progress"] += amount
			if q["progress"] >= q["target"]:
				q["progress"] = q["target"]
				q["completed"] = true
				# Give reward
				for k in q["reward"].keys():
					ResourceManager.add_resource(k, q["reward"][k])
				emit_signal("quest_completed", quest_id)
				print("Quest completed: %s reward %s" % [quest_id, q["reward"]])
			break
	save_idle_data()

func update_quest_progress(quest_id: String, amount: int = 1):
	_update_quest(quest_id, amount)

func get_quests() -> Array:
	return daily_quests

# --- Tap Frenzy ---
func register_tap(world_pos: Vector2 = Vector2.ZERO) -> bool:
	stats_taps += 1
	tap_count += 1
	_update_quest("tap_frenzy", 0) # handled via frenzy trigger not tap
	_check_achievement("tap_1000", stats_taps >= 1000)

	# Small resource on each tap (Town Hall)
	if randf() < 0.3:
		ResourceManager.add_resource_with_fx("gold", randi_range(1,3), world_pos)
	if randf() < 0.2:
		ResourceManager.add_resource_with_fx("food", randi_range(1,2), world_pos)

	if tap_count >= tap_frenzy_threshold:
		tap_count = 0
		trigger_frenzy()
		return true
	return false

func trigger_frenzy():
	var multiplier = 3.0 + prestige_upgrades["eternal_harvest"]["level"] * 0.5
	var duration = 10.0 + prestige_upgrades["offline_mastery"]["level"] * 2.0
	ResourceManager.trigger_tap_frenzy(multiplier, duration)
	emit_signal("tap_frenzy_started", multiplier, duration)
	_update_quest("tap_frenzy", 1)
	print("TAP FRENZY x%.1f for %.1fs!" % [multiplier, duration])

func get_tap_progress() -> float:
	return float(tap_count) / float(tap_frenzy_threshold)

# --- Prestige ---
func can_prestige() -> bool:
	return ResourceManager.get_resource("gold") >= prestige_threshold_gold and GameManager.wave >= 10

func calculate_prestige_gain() -> int:
	var gold = ResourceManager.get_resource("gold")
	var wave = GameManager.wave
	# Formula: sqrt(gold / 5000) + wave/2
	var gain = int(sqrt(float(gold) / 5000.0) + float(wave) * 0.6)
	return max(1, gain)

func do_prestige() -> int:
	if not can_prestige():
		return 0
	var gain = calculate_prestige_gain()
	prestige_points += gain
	total_prestige_earned += gain
	mythic_essence += gain
	prestige_multiplier = 1.0 + total_prestige_earned * 0.05

	# Reset progress (keep prestige upgrades and achievements)
	ResourceManager.resources = {
		"food": 500 + prestige_upgrades["starting_boost"]["level"] * 200,
		"wood": 400 + prestige_upgrades["starting_boost"]["level"] * 150,
		"gold": 300 + prestige_upgrades["starting_boost"]["level"] * 200,
		"mana": 200 + prestige_upgrades["starting_boost"]["level"] * 100,
		"stone": 200,
		"gems": ResourceManager.get_resource("gems") # keep gems
	}
	# Reset other managers via signals
	emit_signal("prestige_ready", gain)
	print("PRESTIGE! Gained %d points, total %d, mult x%.2f" % [gain, total_prestige_earned, prestige_multiplier])
	_check_achievement("prestige_1", total_prestige_earned >= 1)
	save_idle_data()
	return gain

func buy_prestige_upgrade(upgrade_id: String) -> bool:
	if not prestige_upgrades.has(upgrade_id):
		return false
	var up = prestige_upgrades[upgrade_id]
	if up["level"] >= up["max"]:
		return false
	if prestige_points < up["cost"]:
		return false
	prestige_points -= up["cost"]
	up["level"] += 1
	# Apply effect immediately where possible
	match upgrade_id:
		"eternal_harvest":
			ResourceManager.apply_gather_upgrade("food", 1.10)
		"midas_touch":
			ResourceManager.apply_gather_upgrade("gold", 1.10)
		"arcane_legacy":
			ResourceManager.apply_gather_upgrade("mana", 1.15)
		"offline_mastery":
			ResourceManager.offline_multiplier += 0.25
		"warlord_soul":
			pass # applied in unit stats
		"starting_boost":
			pass
		"master_builder":
			pass
	save_idle_data()
	return true

func get_prestige_upgrade_level(id: String) -> int:
	if prestige_upgrades.has(id):
		return prestige_upgrades[id]["level"]
	return 0

# --- Achievements ---
func _check_achievement(id: String, condition: bool):
	if not achievements.has(id):
		return
	if achievements[id]["done"]:
		return
	if condition:
		achievements[id]["done"] = true
		for k in achievements[id]["reward"].keys():
			ResourceManager.add_resource(k, achievements[id]["reward"][k])
		print("Achievement unlocked: %s" % achievements[id]["name"])
		save_idle_data()

func check_achievements_triggers(wave: int, buildings_built: int, units_trained: int):
	_check_achievement("first_blood", wave >= 1)
	_check_achievement("wave_25", wave >= 25)
	_check_achievement("wave_50", wave >= 50)
	_check_achievement("builder", buildings_built >= 10)
	_check_achievement("army_100", units_trained >= 100)

func get_achievements() -> Dictionary:
	return achievements
