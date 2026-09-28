extends Node2D

# Main - Polished v2.1.0 Idle Auto-Battler
# Portrait 720x1280, fixed orientation, splash handled separately

@onready var world = $World
@onready var ui: CanvasLayer = $MainUI

func _ready():
	print("=== Aether Empires - Idle Auto-Battler v2.1.0 ===")
	print("Portrait 720x1280 - Polished - Splash + Menu + Fixed UI")
	
	GameManager.start_game()
	
	if SaveManager.has_save():
		print("Save found, loading...")
		SaveManager.load_game()
	
	IdleManager._check_offline_earnings()
	
	set_process(true)
	set_process_input(true)
	
	print("Game ready! Tap Town Hall, build base, battle waves!")

func _process(_delta):
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_all()

func _save_all():
	SaveManager.save_game()
	IdleManager.save_idle_data()
	print("Saved on pause/close")

func _input(event):
	if event.is_action_pressed("escape"):
		if GameManager.is_placing_building:
			GameManager.cancel_building_placement()
			if world and world.placement_preview:
				world.placement_preview.visible = false
		elif GameManager.current_mode != GameManager.GameMode.BASE:
			GameManager.switch_mode(GameManager.GameMode.BASE)
		else:
			# Go to menu instead of quit
			_save_all()
			get_tree().change_scene_to_file("res://scenes/Menu.tscn")
