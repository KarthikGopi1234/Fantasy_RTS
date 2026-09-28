extends Node2D
class_name MapGenerator

# MapGenerator - Idle Auto-Battler Portrait Edition
# Simple base with resource nodes, no large 2000x2000 map

@export var map_width: int = 1080
@export var map_height: int = 1920
@export var tile_size: int = 64

var noise: FastNoiseLite

func _ready():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02

func generate_map(world_node: Node2D):
	print("Generating idle base map %dx%d portrait" % [map_width, map_height])
	
	# Spawn resource nodes around base (visual, idle gen is via buildings)
	_spawn_resources(world_node)
	
	# Don't spawn bases here - World handles initial base
	# Just decorative
	_spawn_decorations(world_node)
	
	print("Idle map generation complete")

func _spawn_resources(world: Node2D):
	# Spawn decorative resource nodes in base area
	var resource_types = ["wood", "gold", "stone", "mana"]
	var positions = [
		Vector2(200, 600), Vector2(880, 600),
		Vector2(150, 1000), Vector2(930, 1000),
		Vector2(200, 1300), Vector2(880, 1300),
		Vector2(540, 550)
	]
	for i in range(min(positions.size(), 7)):
		var res_type = resource_types[i % resource_types.size()]
		if world.has_method("spawn_resource"):
			world.spawn_resource(res_type, positions[i])

func _spawn_decorations(world: Node2D):
	# Add some forest decorations
	for i in range(8):
		var pos = Vector2(randf_range(50, 1030), randf_range(500, 1400))
		# Avoid center
		if pos.distance_to(Vector2(540, 960)) < 200:
			continue
		if world.has_method("spawn_resource"):
			world.spawn_resource("wood", pos)
