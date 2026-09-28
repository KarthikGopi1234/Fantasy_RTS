extends Node2D

# Main - Idle Auto-Battler Edition
# Portrait, simple, no drag-box

@onready var world = $World
@onready var ui: CanvasLayer = $MainUI

func _ready():
	print("=== Aether Empires - Idle Auto-Battler v2.0.0 ===")
	print("Portrait 1080x1920 - One-hand idle gameplay")
	print("Initializing idle systems...")
	
	# Start game
	GameManager.start_game()
	
	# Load save if exists
	if SaveManager.has_save():
		print("Save found, loading...")
		SaveManager.load_game()
	
	# Check idle offline earnings
	IdleManager._check_offline_earnings()
	
	# Setup
	set_process(true)
	set_process_input(true)
	
	print("Game ready! Tap Town Hall for resources, build base, battle waves!")

func _process(_delta):
	# Auto-save every 30 seconds
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_all()

func _save_all():
	SaveManager.save_game()
	IdleManager.save_idle_data()
	print("Game saved on pause/close")

# Handle Android back button
func _input(event):
	if event.is_action_pressed("escape"):
		if GameManager.is_placing_building:
			GameManager.cancel_building_placement()
			if world and world.placement_preview:
				world.placement_preview.visible = false
		elif GameManager.current_mode != GameManager.GameMode.BASE:
			GameManager.switch_mode(GameManager.GameMode.BASE)
		else:
			# Show quit confirm? For now save and maybe quit
			_save_all()
