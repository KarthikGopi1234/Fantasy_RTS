extends CanvasLayer

# MainUI - Idle Auto-Battler Portrait Edition
# Top resource bar, middle game view, bottom nav + unit cards, popups

@onready var top_bar: Panel = $TopBar
@onready var food_label: Label = $TopBar/FoodLabel
@onready var wood_label: Label = $TopBar/WoodLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var mana_label: Label = $TopBar/ManaLabel
@onready var stone_label: Label = $TopBar/StoneLabel
@onready var gems_label: Label = $TopBar/GemsLabel
@onready var pop_label: Label = $TopBar/PopulationLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var time_label: Label = $TopBar/TimeLabel

@onready var bottom_nav: Panel = $BottomNav
@onready var base_button: Button = $BottomNav/BaseButton
@onready var army_button: Button = $BottomNav/ArmyButton
@onready var battle_button: Button = $BottomNav/BattleButton
@onready var shop_button: Button = $BottomNav/ShopButton
@onready var prestige_button: Button = $BottomNav/PrestigeButton

@onready var action_bar: Panel = $ActionBar
@onready var action_scroll: ScrollContainer = $ActionBar/Scroll
@onready var action_grid: HBoxContainer = $ActionBar/Scroll/Grid

@onready var center_panel: Panel = $CenterPanel
@onready var center_label: Label = $CenterPanel/CenterLabel
@onready var wave_progress: ProgressBar = $CenterPanel/WaveProgress
@onready var start_wave_button: Button = $CenterPanel/StartWaveButton

@onready var popup_panel: Panel = $PopupPanel
@onready var popup_label: Label = $PopupPanel/PopupLabel
@onready var popup_button: Button = $PopupPanel/PopupButton

@onready var build_menu: Panel = $BuildMenu
@onready var quest_panel: Panel = $QuestPanel

var floating_labels: Array = []
var unit_cards: Dictionary = {}

func _ready():
	print("MainUI Idle Portrait ready")
	
	# Connect resource signals
	ResourceManager.resource_changed.connect(_on_resource_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_mode_changed.connect(_on_mode_changed)
	IdleManager.offline_earnings_ready.connect(_on_offline_earnings)
	IdleManager.chest_opened.connect(_on_chest_opened)
	IdleManager.daily_reward_claimed.connect(_on_daily_claimed)
	IdleManager.tap_frenzy_started.connect(_on_frenzy_started)
	
	# Setup UI for portrait
	_setup_portrait_ui()
	
	# Initial update
	_update_all_resources()
	_update_wave_label()
	_refresh_action_bar()
	
	# Hide popup initially
	if popup_panel:
		popup_panel.visible = false

func _setup_portrait_ui():
	# Ensure top bar shows gems
	if gems_label:
		gems_label.text = "Gems: 50"
	
	# Bottom nav connections
	if base_button:
		base_button.pressed.connect(func(): GameManager.switch_mode(GameManager.GameMode.BASE))
	if army_button:
		army_button.pressed.connect(func(): GameManager.switch_mode(GameManager.GameMode.ARMY))
	if battle_button:
		battle_button.pressed.connect(func(): GameManager.switch_mode(GameManager.GameMode.BATTLE))
	if shop_button:
		shop_button.pressed.connect(func(): GameManager.switch_mode(GameManager.GameMode.SHOP))
	if prestige_button:
		prestige_button.pressed.connect(func(): GameManager.switch_mode(GameManager.GameMode.PRESTIGE))
	
	if start_wave_button:
		start_wave_button.pressed.connect(_on_start_wave_pressed)
	if popup_button:
		popup_button.pressed.connect(func(): popup_panel.visible = false)

func _process(delta):
	_update_time_label()
	_update_wave_progress()
	_update_frenzy_ui()

func _update_all_resources():
	_on_resource_changed("food", ResourceManager.get_resource("food"))
	_on_resource_changed("wood", ResourceManager.get_resource("wood"))
	_on_resource_changed("gold", ResourceManager.get_resource("gold"))
	_on_resource_changed("mana", ResourceManager.get_resource("mana"))
	_on_resource_changed("stone", ResourceManager.get_resource("stone"))
	_on_resource_changed("gems", ResourceManager.get_resource("gems"))
	_update_pop_label()

func _on_resource_changed(type: String, amount: int):
	match type:
		"food":
			if food_label:
				food_label.text = "🍖 %d" % amount
		"wood":
			if wood_label:
				wood_label.text = "🪵 %d" % amount
		"gold":
			if gold_label:
				gold_label.text = "🪙 %d" % amount
		"mana":
			if mana_label:
				mana_label.text = "🔮 %d" % amount
		"stone":
			if stone_label:
				stone_label.text = "🪨 %d" % amount
		"gems":
			if gems_label:
				gems_label.text = "💎 %d" % amount
	_update_pop_label()

func _update_pop_label():
	if pop_label:
		pop_label.text = "👥 %s" % GameManager.get_population_string()

func _update_time_label():
	if time_label:
		time_label.text = GameManager.get_game_time_string()

func _update_wave_label():
	if wave_label:
		if GameManager.is_wave_active:
			wave_label.text = "⚔️ Wave %d (%d left)" % [GameManager.wave, GameManager.enemies_remaining]
		else:
			wave_label.text = "⚔️ Wave %d Ready" % [GameManager.wave + 1]

func _update_wave_progress():
	if wave_progress:
		if GameManager.is_wave_active:
			wave_progress.visible = true
			var enemy_total = GameManager.enemies_in_wave
			var enemy_left = GameManager.enemies_remaining
			if enemy_total > 0:
				wave_progress.value = float(enemy_total - enemy_left) / float(enemy_total) * 100.0
		else:
			wave_progress.visible = false
	_update_wave_label()

func _update_frenzy_ui():
	if ResourceManager.is_frenzy_active():
		if center_label and GameManager.current_mode == GameManager.GameMode.BASE:
			center_label.text = "🔥 FRENZY x%.1f %.1fs 🔥\nTap Town Hall!" % [ResourceManager.tap_frenzy_multiplier, ResourceManager.get_frenzy_time_left()]

# --- Action Bar (Unit Cards for Idle Auto-Battler) ---
func _refresh_action_bar():
	if not action_grid:
		return
	# Clear
	for child in action_grid.get_children():
		child.queue_free()
	unit_cards.clear()
	
	var mode = GameManager.current_mode
	match mode:
		GameManager.GameMode.BASE:
			_refresh_build_cards()
		GameManager.GameMode.BATTLE:
			_refresh_unit_cards()
		GameManager.GameMode.ARMY:
			_refresh_army_cards()
		GameManager.GameMode.SHOP:
			_refresh_shop_cards()
		GameManager.GameMode.PRESTIGE:
			_refresh_prestige_cards()

func _refresh_build_cards():
	if not action_grid:
		return
	var buildings = TechTree.get_available_buildings()
	for b_id in buildings:
		var btn = _create_build_card(b_id)
		action_grid.add_child(btn)
	# Age up button
	var age_btn = Button.new()
	age_btn.text = "Age Up\n%s" % TechTree.age_names[TechTree.current_age]
	age_btn.custom_minimum_size = Vector2(140, 100)
	age_btn.pressed.connect(_on_age_up_pressed)
	action_grid.add_child(age_btn)

func _create_build_card(building_id: String) -> Button:
	var btn = Button.new()
	var cost_str = TechTree.get_building_cost_string(building_id)
	var stats = TechTree.building_stats.get(building_id, {})
	var gen_str = ""
	if stats.has("gen"):
		for k in stats["gen"].keys():
			gen_str += "%s +%.1f/s " % [k, stats["gen"][k]]
	var name_pretty = building_id.capitalize().replace("_", " ")
	btn.text = "%s\n%s\n%s" % [name_pretty, cost_str, gen_str]
	btn.custom_minimum_size = Vector2(160, 110)
	btn.add_theme_font_size_override("font_size", 12)
	# Color based on can afford
	var cost = stats.get("cost", {})
	if ResourceManager.can_afford(cost):
		btn.modulate = Color(1,1,1,1)
	else:
		btn.modulate = Color(1,1,1,0.5)
	btn.pressed.connect(func(): _on_build_card_pressed(building_id))
	return btn

func _refresh_unit_cards():
	if not action_grid:
		return
	var units = TechTree.get_available_units()
	for u_id in units:
		var btn = _create_unit_card(u_id)
		action_grid.add_child(btn)

func _create_unit_card(unit_id: String) -> Button:
	var btn = Button.new()
	var stats = TechTree.unit_stats.get(unit_id, {})
	var cost_str = TechTree.get_unit_cost_string(unit_id)
	var hp = stats.get("hp", 0)
	var atk = stats.get("attack", 0)
	var role = stats.get("role", "melee")
	var icon = "⚔️"
	match unit_id:
		"villager": icon = "👨‍🌾"
		"swordsman": icon = "🗡️"
		"archer": icon = "🏹"
		"knight": icon = "🐴"
		"healer": icon = "💚"
		"mage": icon = "🧙"
		"golem": icon = "🗿"
		"dragon": icon = "🐉"
	
	btn.text = "%s %s\nHP:%d ATK:%d\n%s" % [icon, unit_id.capitalize(), hp, atk, cost_str]
	btn.custom_minimum_size = Vector2(160, 110)
	btn.add_theme_font_size_override("font_size", 11)
	
	# Highlight selected
	if GameManager.selected_unit_card == unit_id:
		btn.add_theme_color_override("font_color", Color(1,1,0.2))
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3,0.5,0.8,0.8)
		btn.add_theme_stylebox_override("normal", style)
	
	# Afford check
	if not GameManager.can_deploy_unit(unit_id):
		btn.modulate = Color(1,1,1,0.5)
	
	btn.pressed.connect(func(): _on_unit_card_pressed(unit_id))
	return btn

func _refresh_army_cards():
	if not action_grid:
		return
	# Show army stats + upgrade buttons
	var player_units = get_tree().get_nodes_in_group("player_units")
	var count_by_type = {}
	for u in player_units:
		if not is_instance_valid(u):
			continue
		var t = u.get("unit_type")
		count_by_type[t] = count_by_type.get(t, 0) + 1
	
	for unit_id in TechTree.get_available_units():
		var count = count_by_type.get(unit_id, 0)
		var btn = Button.new()
		btn.text = "%s x%d\nTap to upgrade" % [unit_id.capitalize(), count]
		btn.custom_minimum_size = Vector2(150, 80)
		btn.pressed.connect(func(): _show_unit_info(unit_id))
		action_grid.add_child(btn)
	
	# Techs
	var techs = TechTree.get_techs_by_category("military") + TechTree.get_techs_by_category("economy")
	for tech_id in techs:
		if TechTree.techs[tech_id]["researched"]:
			continue
		var tech = TechTree.techs[tech_id]
		var btn = Button.new()
		btn.text = "%s\n%s" % [tech["name"], _cost_dict_to_string(tech["cost"])]
		btn.custom_minimum_size = Vector2(160, 80)
		btn.add_theme_font_size_override("font_size", 11)
		if not ResourceManager.can_afford(tech["cost"]):
			btn.modulate = Color(1,1,1,0.5)
		btn.pressed.connect(func(): _on_research_pressed(tech_id))
		action_grid.add_child(btn)

func _refresh_shop_cards():
	if not action_grid:
		return
	# Chests
	var chest_types = [0,1,2,3] # common to mythic
	var chest_names = ["Common Chest", "Rare Chest", "Epic Chest", "Mythic Chest"]
	var chest_icons = ["📦", "🎁", "💰", "👑"]
	for i in range(chest_types.size()):
		var btn = Button.new()
		var cost_str = IdleManager.get_chest_cost_str(i)
		btn.text = "%s %s\n%s" % [chest_icons[i], chest_names[i], cost_str]
		btn.custom_minimum_size = Vector2(160, 100)
		if not IdleManager.can_open_chest(i):
			btn.modulate = Color(1,1,1,0.5)
		btn.pressed.connect(func(): _on_chest_pressed(i))
		action_grid.add_child(btn)
	
	# Daily reward
	var daily_btn = Button.new()
	if IdleManager.can_claim_daily():
		var rew = IdleManager.get_next_daily_reward()
		daily_btn.text = "🎉 Daily\n%s\nCLAIM!" % _cost_dict_to_string(rew)
		daily_btn.modulate = Color(1,1,0.5)
	else:
		daily_btn.text = "🎉 Daily\nClaimed!\nStreak: %d" % IdleManager.daily_streak
		daily_btn.modulate = Color(1,1,1,0.5)
	daily_btn.custom_minimum_size = Vector2(160, 100)
	daily_btn.pressed.connect(_on_daily_pressed)
	action_grid.add_child(daily_btn)
	
	# Idle techs
	for tech_id in TechTree.get_techs_by_category("idle"):
		if TechTree.techs[tech_id]["researched"]:
			continue
		var tech = TechTree.techs[tech_id]
		var btn = Button.new()
		btn.text = "💡 %s\n%s" % [tech["name"], _cost_dict_to_string(tech["cost"])]
		btn.custom_minimum_size = Vector2(160, 80)
		btn.add_theme_font_size_override("font_size", 11)
		if not ResourceManager.can_afford(tech["cost"]):
			btn.modulate = Color(1,1,1,0.5)
		btn.pressed.connect(func(): _on_research_pressed(tech_id))
		action_grid.add_child(btn)

func _refresh_prestige_cards():
	if not action_grid:
		return
	var prestige_btn = Button.new()
	if IdleManager.can_prestige():
		var gain = IdleManager.calculate_prestige_gain()
		prestige_btn.text = "✨ PRESTIGE\nGain %d points\nGold: %d/%d" % [gain, ResourceManager.get_resource("gold"), IdleManager.prestige_threshold_gold]
		prestige_btn.modulate = Color(0.8,0.5,1,1)
	else:
		prestige_btn.text = "✨ Prestige\nNeed Wave 10+\nGold %d/%d" % [ResourceManager.get_resource("gold"), IdleManager.prestige_threshold_gold]
		prestige_btn.modulate = Color(1,1,1,0.5)
	prestige_btn.custom_minimum_size = Vector2(200, 100)
	prestige_btn.pressed.connect(_on_prestige_pressed)
	action_grid.add_child(prestige_btn)
	
	# Prestige upgrades
	for up_id in IdleManager.prestige_upgrades.keys():
		var up = IdleManager.prestige_upgrades[up_id]
		var btn = Button.new()
		btn.text = "%s Lv%d/%d\nCost %d pts\n%s" % [up["name"], up["level"], up["max"], up["cost"], up["effect"]]
		btn.custom_minimum_size = Vector2(180, 100)
		btn.add_theme_font_size_override("font_size", 11)
		if up["level"] >= up["max"] or IdleManager.prestige_points < up["cost"]:
			btn.modulate = Color(1,1,1,0.5)
		btn.pressed.connect(func(): _on_prestige_upgrade_pressed(up_id))
		action_grid.add_child(btn)

func _cost_dict_to_string(cost: Dictionary) -> String:
	var parts = []
	for k in cost.keys():
		parts.append("%d %s" % [cost[k], k])
	return ", ".join(parts)

# --- Handlers ---
func _on_build_card_pressed(building_id: String):
	GameManager.start_building_placement(building_id)
	_show_popup("Tap map to place %s\n%s" % [building_id.capitalize(), TechTree.get_building_cost_string(building_id)], "Place")

func _on_unit_card_pressed(unit_id: String):
	GameManager.select_unit_card(unit_id)
	_refresh_action_bar()
	if GameManager.current_mode == GameManager.GameMode.BATTLE:
		_show_popup("Tap lane to deploy %s" % unit_id.capitalize(), "Deploy")

func _on_age_up_pressed():
	if TechTree.can_advance_age():
		if TechTree.advance_age():
			_show_popup("Advanced to %s!" % TechTree.age_names[TechTree.current_age], "Age Up!")
			_refresh_action_bar()
		else:
			_show_popup("Not enough resources!", "Age Up Failed")
	else:
		var next_age = TechTree.current_age + 1
		if TechTree.age_costs.has(next_age):
			_show_popup("Need: %s" % _cost_dict_to_string(TechTree.age_costs[next_age]), "Cannot Age Up")
		else:
			_show_popup("Max age reached!", "Age Up")

func _on_research_pressed(tech_id: String):
	if TechTree.can_research(tech_id):
		if TechTree.research_tech(tech_id):
			_show_popup("Researched %s!" % TechTree.techs[tech_id]["name"], "Research!")
			_refresh_action_bar()
		else:
			_show_popup("Failed to research!", "Error")
	else:
		_show_popup("Cannot research %s\nNeed: %s" % [tech_id, _cost_dict_to_string(TechTree.techs[tech_id]["cost"])], "Research")

func _on_chest_pressed(chest_type: int):
	if IdleManager.can_open_chest(chest_type):
		var rewards = IdleManager.open_chest(chest_type)
		_show_popup("Opened chest!\n%s" % _cost_dict_to_string(rewards), "Chest!")
		_refresh_action_bar()
	else:
		_show_popup("Cannot afford chest!\nNeed: %s" % IdleManager.get_chest_cost_str(chest_type), "Chest")

func _on_daily_pressed():
	if IdleManager.can_claim_daily():
		var rew = IdleManager.claim_daily_reward()
		_show_popup("Daily Day %d!\n%s" % [IdleManager.daily_streak, _cost_dict_to_string(rew)], "Daily Reward!")
		_refresh_action_bar()
	else:
		_show_popup("Come back in %d hours!\nStreak: %d" % [20, IdleManager.daily_streak], "Daily")

func _on_prestige_pressed():
	if IdleManager.can_prestige():
		_show_confirm_popup("Prestige will reset your base and wave but give permanent bonuses! Gain %d points. Continue?" % IdleManager.calculate_prestige_gain(), "Prestige", func(): _do_prestige())
	else:
		_show_popup("Need Wave 10+ and %d Gold!" % IdleManager.prestige_threshold_gold, "Prestige")

func _do_prestige():
	var gain = IdleManager.do_prestige()
	GameManager.reset_for_prestige()
	_show_popup("Prestiged! Gained %d points! Total: %d\nMultiplier: x%.2f" % [gain, IdleManager.total_prestige_earned, IdleManager.prestige_multiplier], "Prestige!")
	_refresh_action_bar()

func _on_prestige_upgrade_pressed(up_id: String):
	if IdleManager.buy_prestige_upgrade(up_id):
		_show_popup("Upgraded %s to Lv%d!" % [IdleManager.prestige_upgrades[up_id]["name"], IdleManager.prestige_upgrades[up_id]["level"]], "Prestige Upgrade")
		_refresh_action_bar()
	else:
		_show_popup("Need %d prestige points!" % IdleManager.prestige_upgrades[up_id]["cost"], "Prestige")

func _on_start_wave_pressed():
	if not GameManager.is_wave_active:
		GameManager.start_next_wave()
		if center_panel:
			center_panel.visible = false

func _show_unit_info(unit_id: String):
	var stats = TechTree.unit_stats.get(unit_id, {})
	_show_popup("%s\nHP:%d ATK:%d Armor:%d Speed:%d\nCost: %s\nRole: %s" % [unit_id.capitalize(), stats.get("hp",0), stats.get("attack",0), stats.get("armor",0), stats.get("speed",0), TechTree.get_unit_cost_string(unit_id), stats.get("role","")], "Unit Info")

func _show_popup(text: String, title: String = "Info"):
	if popup_panel and popup_label:
		popup_label.text = "%s\n\n%s" % [title, text]
		popup_panel.visible = true
		# Auto hide after 3 sec if not important
		await get_tree().create_timer(3.0).timeout
		if popup_panel.visible and title != "Prestige" and title != "Daily Reward!":
			# Don't auto-hide important popups if user hasn't closed? Actually auto-hide all for idle flow
			pass

func _show_confirm_popup(text: String, title: String, callback: Callable):
	if popup_panel and popup_label and popup_button:
		popup_label.text = "%s\n\n%s" % [title, text]
		popup_panel.visible = true
		# Disconnect previous
		for conn in popup_button.pressed.get_connections():
			popup_button.pressed.disconnect(conn["callable"])
		popup_button.pressed.connect(func():
			popup_panel.visible = false
			callback.call()
			# Reconnect default close
			await get_tree().create_timer(0.1).timeout
			for conn in popup_button.pressed.get_connections():
				popup_button.pressed.disconnect(conn["callable"])
			popup_button.pressed.connect(func(): popup_panel.visible = false)
		)
		popup_button.text = "CONFIRM"

# --- Events ---
func _on_wave_started(wave: int):
	_show_popup("Wave %d Started!\n%d enemies incoming!" % [wave, GameManager.enemies_in_wave], "Battle!")
	_update_wave_label()

func _on_wave_completed(wave: int, rewards: Dictionary):
	_show_popup("Wave %d Complete!\nRewards: %s" % [wave, _cost_dict_to_string(rewards)], "Victory!")
	_update_wave_label()
	_refresh_action_bar()
	# Show center panel for next wave
	if center_panel:
		center_panel.visible = true
		if center_label:
			center_label.text = "Wave %d Complete!\nTap to start Wave %d" % [wave, wave+1]

func _on_mode_changed(mode: String):
	print("UI Mode changed to: ", mode)
	_refresh_action_bar()
	if center_panel:
		match mode:
			"battle":
				center_panel.visible = not GameManager.is_wave_active
				if center_label:
					center_label.text = "Tap START to begin Wave %d\nSelect unit card then tap lane to deploy!" % [GameManager.wave+1]
			"base":
				center_panel.visible = false
			"army":
				center_panel.visible = false
			"shop":
				center_panel.visible = false
			"prestige":
				center_panel.visible = false

func _on_offline_earnings(earnings: Dictionary, seconds: int):
	var text = "Welcome back!\nOffline for %s\nEarnings:\n%s" % [_format_time(seconds), _cost_dict_to_string(earnings)]
	_show_popup(text, "Offline Earnings!")
	ResourceManager.apply_offline_earnings(earnings)

func _format_time(seconds: int) -> String:
	var h = seconds / 3600
	var m = (seconds % 3600) / 60
	if h > 0:
		return "%dh %dm" % [h, m]
	else:
		return "%dm" % m

func _on_chest_opened(chest_type: String, rewards: Dictionary):
	_show_popup("Opened %s Chest!\n%s" % [chest_type, _cost_dict_to_string(rewards)], "Chest!")
	_refresh_action_bar()

func _on_daily_claimed(day: int, rewards: Dictionary):
	_show_popup("Daily Day %d claimed!\n%s\nStreak: %d" % [day, _cost_dict_to_string(rewards), day], "Daily Reward!")
	_refresh_action_bar()

func _on_frenzy_started(multiplier: float, duration: float):
	_show_popup("TAP FRENZY!\n x%.1f for %.1fs!\nKeep tapping Town Hall!" % [multiplier, duration], "Frenzy!")
