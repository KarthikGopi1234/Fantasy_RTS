extends Node2D

# Main scene controller

@onready var world: World = $World
@onready var ui: CanvasLayer = $MainUI

func _ready():
	print("=== Aether Empires - Fantasy RTS v1.0.0 ===")
	print("Initializing game...")
	
	# Start game after a short delay
	GameManager.start_game()
	
	# Setup input for building placement preview
	set_process_input(true)

func _input(event):
	# Handle building placement
	if GameManager.is_placing_building and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos = _screen_to_world(event.position)
			if GameManager.place_building_at(world_pos):
				print("Building placed at ", world_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			GameManager.cancel_building_placement()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam = get_node_or_null("World/Camera2D")
	if cam:
		return cam.get_screen_center_position() + (screen_pos - get_viewport_rect().size/2) / cam.zoom
	return screen_pos

func _process(_delta):
	# Update building placement preview
	if GameManager.is_placing_building:
		var preview = get_node_or_null("PlacementPreview")
		if not preview:
			preview = Sprite2D.new()
			preview.name = "PlacementPreview"
			preview.modulate = Color(0,1,0,0.5)
			add_child(preview)
		
		var mouse_pos = get_viewport().get_mouse_position()
		preview.global_position = _screen_to_world(mouse_pos)
		
		var tex_path = "res://assets/sprites/buildings/%s.png" % GameManager.building_to_place
		if ResourceLoader.exists(tex_path):
			preview.texture = load(tex_path)
	else:
		var preview = get_node_or_null("PlacementPreview")
		if preview:
			preview.queue_free()
