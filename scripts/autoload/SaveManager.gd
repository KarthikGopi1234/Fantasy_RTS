extends Node

# SaveManager - Idle Auto-Battler Edition
# Saves resources, age, techs, wave, buildings, prestige handled by IdleManager

var save_path: String = "user://savegame_v2.json"

func save_game():
	var data = {
		"version": "2.0.0",
		"resources": ResourceManager.get_all_resources(),
		"age": TechTree.current_age,
		"techs": TechTree.techs,
		"population": {"current": GameManager.current_population, "max": GameManager.max_population},
		"game_time": GameManager.game_time,
		"wave": GameManager.wave,
		"stats": {
			"enemies_defeated": GameManager.enemies_defeated,
			"buildings_built": GameManager.buildings_built,
			"units_trained": GameManager.units_trained
		},
		"timestamp": int(Time.get_unix_time_from_system())
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Game saved to ", save_path, " wave ", GameManager.wave)
		# Also save idle data
		var im = get_node_or_null("/root/IdleManager")
		if im and im.has_method("save_idle_data"):
			im.save_idle_data()
		return true
	return false

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		# Try old save path for migration
		if FileAccess.file_exists("user://savegame.json"):
			save_path = "user://savegame.json"
		else:
			print("No save file found")
			return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		print("Failed to parse save file")
		return false
	
	var data = json.data
	if data.has("resources"):
		# Merge to keep new resources like gems
		var loaded_res = data["resources"]
		for k in loaded_res.keys():
			if ResourceManager.resources.has(k):
				ResourceManager.resources[k] = loaded_res[k]
	if data.has("age"):
		TechTree.current_age = data["age"]
	if data.has("techs"):
		# Merge techs to keep new ones
		var loaded_techs = data["techs"]
		for tech_id in loaded_techs.keys():
			if TechTree.techs.has(tech_id):
				TechTree.techs[tech_id] = loaded_techs[tech_id]
	if data.has("population"):
		GameManager.current_population = data["population"]["current"]
		GameManager.max_population = data["population"]["max"]
	if data.has("game_time"):
		GameManager.game_time = data["game_time"]
	if data.has("wave"):
		GameManager.wave = data["wave"]
	if data.has("stats"):
		if data["stats"].has("enemies_defeated"):
			GameManager.enemies_defeated = data["stats"]["enemies_defeated"]
		if data["stats"].has("buildings_built"):
			GameManager.buildings_built = data["stats"]["buildings_built"]
		if data["stats"].has("units_trained"):
			GameManager.units_trained = data["stats"]["units_trained"]
	
	# Load idle data
	var im = get_node_or_null("/root/IdleManager")
	if im and im.has_method("load_idle_data"):
		im.load_idle_data()
	
	print("Game loaded - wave %d, age %d" % [GameManager.wave, TechTree.current_age])
	return true

func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists("user://savegame.json") or FileAccess.file_exists("user://idle_data.json")

func delete_save():
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if FileAccess.file_exists("user://idle_data.json"):
		DirAccess.remove_absolute("user://idle_data.json")
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute("user://savegame.json")
	print("Save deleted")
