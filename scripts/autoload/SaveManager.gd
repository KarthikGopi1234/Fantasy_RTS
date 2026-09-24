extends Node

# Simple save system using JSON
var save_path: String = "user://savegame.json"

func save_game():
	var data = {
		"resources": ResourceManager.get_all_resources(),
		"age": TechTree.current_age,
		"techs": TechTree.techs,
		"population": {"current": GameManager.current_population, "max": GameManager.max_population},
		"game_time": GameManager.game_time,
		"stats": {
			"enemies_defeated": GameManager.enemies_defeated,
			"buildings_built": GameManager.buildings_built,
			"units_trained": GameManager.units_trained
		}
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Game saved to ", save_path)
		return true
	return false

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
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
		ResourceManager.resources = data["resources"]
	if data.has("age"):
		TechTree.current_age = data["age"]
	if data.has("techs"):
		TechTree.techs = data["techs"]
	if data.has("population"):
		GameManager.current_population = data["population"]["current"]
		GameManager.max_population = data["population"]["max"]
	if data.has("game_time"):
		GameManager.game_time = data["game_time"]
	
	print("Game loaded")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(save_path)
