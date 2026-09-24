extends Node2D
class_name MapGenerator

# Procedural map generation for fantasy RTS
# Generates resource nodes, obstacles, starting bases

@export var map_width: int = 2000
@export var map_height: int = 2000
@export var tile_size: int = 64

var noise: FastNoiseLite

func _ready():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02

func generate_map(world_node: Node2D):
	print("Generating fantasy map %dx%d" % [map_width, map_height])
	
	# Generate ground tiles - visual only for now
	# In a full implementation, would create TileMapLayer
	# For MVP, we use a simple colored background + resource nodes
	
	# Spawn resource nodes
	_spawn_resources(world_node)
	
	# Spawn player starting base
	_spawn_starting_base(world_node, Vector2(400, 400), 0)
	
	# Spawn enemy base
	_spawn_starting_base(world_node, Vector2(map_width - 400, map_height - 400), 1)
	
	# Spawn neutral obstacles / forests
	_spawn_forests(world_node)
	
	print("Map generation complete")

func _spawn_resources(world: Node2D):
	var resource_types = ["wood", "gold", "stone", "mana"]
	var resource_counts = {"wood": 8, "gold": 6, "stone": 5, "mana": 4}
	
	for res_type in resource_types:
		var count = resource_counts.get(res_type, 4)
		for i in range(count):
			var pos = Vector2(
				randf_range(200, map_width - 200),
				randf_range(200, map_height - 200)
			)
			# Avoid starting areas
			if pos.distance_to(Vector2(400,400)) < 300: continue
			if pos.distance_to(Vector2(map_width-400, map_height-400)) < 300: continue
			
			if world.has_method("spawn_resource"):
				world.spawn_resource(res_type, pos)

func _spawn_starting_base(world: Node2D, center: Vector2, faction: int):
	# Town Hall
	if world.has_method("spawn_building"):
		world.spawn_building("town_hall", center, faction)
		# Houses
		world.spawn_building("house", center + Vector2(120, 0), faction)
		world.spawn_building("house", center + Vector2(0, 120), faction)
		# Barracks
		world.spawn_building("barracks", center + Vector2(150, 100), faction)
	
	# Starting villagers
	if world.has_method("spawn_unit"):
		for i in range(3):
			var offset = Vector2(randf_range(-60,60), randf_range(-60,60))
			world.spawn_unit("villager", center + offset + Vector2(60,60), faction)

func _spawn_forests(world: Node2D):
	for i in range(15):
		var pos = Vector2(
			randf_range(0, map_width),
			randf_range(0, map_height)
		)
		if pos.distance_to(Vector2(400,400)) < 250: continue
		if pos.distance_to(Vector2(map_width-400, map_height-400)) < 250: continue
		
		if world.has_method("spawn_resource"):
			world.spawn_resource("wood", pos)
