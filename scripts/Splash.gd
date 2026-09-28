extends Control

# Splash Screen - Polished v2.1.0
# Shows logo, title, loading, tap to start, with animations

@onready var bg: TextureRect = $Background
@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var tap_label: Label = $TapLabel
@onready var version_label: Label = $VersionLabel
@onready var loading_bar: ProgressBar = $LoadingBar

var time: float = 0.0
var can_tap: bool = false

func _ready():
	print("Splash screen v2.1.0")
	# Setup
	if bg and ResourceLoader.exists("res://assets/splash/splash_720x1280.png"):
		bg.texture = load("res://assets/splash/splash_720x1280.png")
	
	# Animate in
	modulate = Color(1,1,1,0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,1), 0.8)
	
	# Loading simulation
	if loading_bar:
		loading_bar.value = 0
		loading_bar.visible = true
	
	# Tap label pulse
	if tap_label:
		tap_label.visible = false
	
	# Start loading
	_start_loading()

func _start_loading():
	# Simulate loading resources
	if loading_bar:
		var tween = create_tween()
		tween.tween_property(loading_bar, "value", 100, 1.5).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(_on_loading_complete)

func _on_loading_complete():
	if loading_bar:
		loading_bar.visible = false
	if tap_label:
		tap_label.visible = true
		# Pulse animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(tap_label, "modulate", Color(1,1,1,0.3), 0.8)
		tween.tween_property(tap_label, "modulate", Color(1,1,1,1), 0.8)
	can_tap = true
	print("Splash loading complete, tap to continue")

func _process(delta):
	time += delta
	# Subtle title float
	if title_label:
		title_label.position.y = 280 + sin(time*1.5)*4

func _input(event):
	if not can_tap:
		return
	if event is InputEventScreenTouch and event.pressed:
		_go_to_menu()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_to_menu()
	elif event is InputEventKey and event.pressed:
		_go_to_menu()

func _go_to_menu():
	if not can_tap:
		return
	can_tap = false
	print("Going to menu")
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Menu.tscn"))
