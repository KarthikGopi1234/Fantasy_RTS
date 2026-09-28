extends Node2D
class_name MapGenerator

# MapGenerator - Polished v2.1.0 720x1280 portrait

@export var map_width: int = 720
@export var map_height: int = 1280
@export var tile_size: int = 64

var noise: FastNoiseLite

func _ready():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02

func generate_map(world_node: Node2D):
	print("Generating idle base map %dx%d polished" % [map_width, map_height])
	_spawn_resources(world_node)
	_spawn_decorations(world_node)
	print("Idle map polished complete")

func _spawn_resources(world: Node2D):
	var resource_types = ["wood", "gold", "stone", "mana"]
	var positions = [
		Vector2(120, 400), Vector2(600, 400),
		Vector2(80, 700), Vector2(640, 700),
		Vector2(120, 900), Vector2(600, 900),
		Vector2(360, 350)
	]
	for i in range(min(positions.size(), 7)):
		var res_type = resource_types[i % resource_types.size()]
		if world.has_method("spawn_resource"):
			world.spawn_resource(res_type, positions[i])

func _spawn_decorations(world: Node2D):
	for i in range(6):
		var pos = Vector2(randf_range(40, 680), randf_range(300, 1000))
		if pos.distance_to(Vector2(360, 640)) < 150:
			continue
		if world.has_method("spawn_resource"):
			world.spawn_resource("wood", pos)
