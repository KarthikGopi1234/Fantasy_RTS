extends Control

# Main Menu - Polished v2.1.0
# Play, Continue, Settings, with fantasy background

@onready var bg: TextureRect = $Background
@onready var title: Label = $Title
@onready var play_button: Button = $VBox/PlayButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready():
	print("Main Menu v2.1.0")
	if bg and ResourceLoader.exists("res://assets/splash/splash_720x1280.png"):
		bg.texture = load("res://assets/splash/splash_720x1280.png")
		bg.modulate = Color(0.5,0.5,0.6,1) # Darken for menu
	
	# Check save
	if continue_button:
		continue_button.disabled = not SaveManager.has_save()
		if continue_button.disabled:
			continue_button.modulate = Color(1,1,1,0.5)
	
	# Connect buttons
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Animate title
	if title:
		title.modulate = Color(1,1,1,0)
		var tween = create_tween()
		tween.tween_property(title, "modulate", Color(1,1,1,1), 0.8)
		tween.parallel().tween_property(title, "scale", Vector2(1.05,1.05), 0.8).set_trans(Tween.TRANS_SINE)
		tween.tween_property(title, "scale", Vector2(1,1), 0.4)

func _on_play_pressed():
	print("New Game")
	# Delete save for new game? Actually keep but reset
	SaveManager.delete_save()
	IdleManager.save_idle_data() # Reset? Actually keep prestige
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_continue_pressed():
	print("Continue Game")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed():
	# Simple settings popup - toggle sound, etc.
	var popup = $SettingsPopup
	if popup:
		popup.visible = not popup.visible

func _on_quit_pressed():
	get_tree().quit()
