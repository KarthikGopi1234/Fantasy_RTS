# Aether Empires v2.0.0 - Idle Auto-Battler Redesign - Final Report

## User Feedback Addressed
"The game does not work at all in this sense. I think the controls etc are just too complex for a touch screen. Let's maybe redesign it as a mobile focused game. Perhaps idle based?"

## Redesign Decisions (via ask_user)
- **Idle Type:** Auto-Battler (build army tap deploy auto-resolve focus upgrades)
- **Orientation:** Portrait (one-hand vertical UI)
- **Scope:** Expand Idle (keep 8 buildings 8 units plus offline earnings prestige auto-queue daily rewards)
- **Progression:** Full (offline auto-queue tap frenzy chests daily quests prestige achievements)

## What Changed - Complete Overhaul

### Controls - From Complex to One-Tap
| Before (RTS) | After (Idle Auto-Battler) |
|--------------|---------------------------|
| Drag-box selection | Removed completely |
| Right-click move/attack | Removed |
| Precise unit micro | Auto walk & fight |
| Landscape 1920x1080 | Portrait 1080x1920 |
| Small buttons | 80px bottom nav, 160px cards |
| No idle | Full idle loop |

### New Systems

#### 1. ResourceManager Idle
- Base gen 0.5 food/s, 0.3 gold/s, 0.1 mana/s
- Building gen: Town Hall 0.8 food+0.5 gold, House 0.2 food, Lumber 0.6 wood, Market 0.4 gold, Mage Tower 0.5 mana
- Fractional buffer to preserve small gen
- Tap frenzy multiplier x3 for 10s
- Offline multiplier from Market + techs
- calculate_offline_earnings() up to 12h cap

#### 2. IdleManager (NEW Autoload)
- **Offline:** Tracks last_save_timestamp, calculates earnings on return, emits signal
- **Chests:** 4 tiers Common/Rare/Epic/Mythic with costs and random 0.8x-1.5x rewards + prestige multiplier
- **Daily:** 7-day streak rewards, 20h cooldown
- **Quests:** 6 templates, 3 random daily, progress tracking
- **Prestige:** Formula sqrt(gold/5000)+wave*0.6, points, multiplier x5% per prestige, 7 permanent upgrades
- **Tap Frenzy:** 25 taps threshold, x3 multiplier, 10s + upgrades
- **Achievements:** 8 achievements with gem rewards
- Save to user://idle_data.json

#### 3. GameManager Idle
- GameMode enum BASE/BATTLE/ARMY/SHOP/PRESTIGE
- Lane system: 3 lanes, lane_y_positions, selected_lane, selected_unit_card
- Wave system: wave, difficulty 1.0+(wave-1)*0.25, enemies_in_wave 3+wave*1.5, spawn timer 1.5s, rewards gold+food+mana+gems
- Auto-queue: Every building checks if queue empty and auto-queues default unit if can afford
- No drag-box, no selection box
- Methods: switch_mode, select_lane, select_unit_card, deploy_unit, start_next_wave, reset_for_prestige

#### 4. World Idle
- Portrait center 540,960, lane_y_positions [740,960,1180], lane_height 220
- Tap handling: building placement, building tap for bonus, battle tap deploy, base tap frenzy
- _is_valid_building_position checks 80-1000 x, 400-1400 y, no overlap 120px
- spawn_unit_in_lane with lane param
- spawn_floating_text with tween up 80px + fade
- clear_all for prestige

#### 5. BaseUnit Auto-Battler
- No move_to from player, auto moves in lane direction (player right, enemy left)
- Lane keeping soft Y correction
- Finds nearest enemy in 300 radius, prefers same lane
- Attack range from TechTree, healer heals injured allies <80% HP
- Dragon breath AoE 120 radius 3 targets 0.7x damage + full main target
- Take damage with floating text, flash red, die gives gold reward 2+wave*0.5
- Despawn when reaching end (player x>1200, enemy x<-200)

#### 6. BaseBuilding Idle
- Idle gen dict, gen_timer 1s, applies modifiers
- Production progress bar visible when producing
- Auto-queue via GameManager
- Upgrade: cost 100*level wood/gold, 50*level stone, +200 HP, gen x1.5
- on_tap: Town Hall registers tap for frenzy + small gold/food, Market gold, Lumber wood, House food
- recalc_building_gen on spawn/destroy/upgrade

#### 7. MainUI Portrait
- Top bar 120px tall with emoji labels 🍖🪵🪙🔮🪨💎👥⚔️
- Center panel wave start/victory with progress bar
- Action bar 220px tall scrollable HBox with cards 160x110
- Bottom nav 140px tall 5 buttons 190px wide 80px tall
- Popups: chest, daily, offline, frenzy, prestige confirm
- Modes: Base shows build cards + Age Up, Battle shows unit cards, Army shows counts+techs, Shop shows chests+daily+idle techs, Prestige shows prestige + upgrades

#### 8. Assets - Idle
- generate_idle_assets.py: gems 64x64, chests 96x96 4 tiers, daily_reward 96x96 gift box, prestige 96x96 star, tap_frenzy 96x96 hand, lane markers 1080x20, offline_popup 512x320, wave icon 64x64
- Total assets 120+ files, APK 305 assets includes chest/gem/prestige

## Version & Build Verification

### Version Matching (DevOps Tenet)
- VERSION file: 2.0.0
- project.godot config/version: 2.0.0
- export_presets.cfg version/code: 20, version/name: 2.0.0, orientation: 2 (portrait)
- Tag: v2.0.0
- All match!

### APK Verification - v2.0.0
- **File:** /tmp/AetherEmpires_v2.0.0.apk 26019949 bytes (25 MB)
- **Release:** https://github.com/KarthikGopi1234/Fantasy_RTS/releases/tag/v2.0.0
- **Artifact:** android-apk 25741994 bytes (run 36389793915)
- **Icon:** res/mipmap/icon.png 13561 bytes custom castle (192x192 RGBA), res/mipmap-hdpi-v4/icon.png 5269 bytes
- **Assets:** 305 files including chest_common, chest_epic, gems, prestige
- **Package:** com.aetherempires.fantasyrts (same as v1.0.12 for update continuity)
- **Orientation:** Portrait (2)
- **Build:** Non-gradle legacy (reliable, ~1 min), arm64-v8a only
- **CI:** Runs 36389793915 (v2.0.0) and 36389792409 (main) both completed success

### Signing Continuity
- Same debug.jks 2.1K JKS keystore
- Same GitHub Secrets: ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD=android, ANDROID_KEY_ALIAS=androiddebugkey, ANDROID_KEY_PASSWORD=android
- Updates from v1.0.12 to v2.0.0 should install as update (same package + keystore)

## File Changes
- Modified: README.md, VERSION, export_presets.cfg, project.godot, scenes/main.tscn, scripts/Main.gd, scripts/autoload/GameManager.gd, ResourceManager.gd, SaveManager.gd, TechTree.gd, scripts/buildings/BaseBuilding.gd, scripts/systems/MainUI.gd, MapGenerator.gd, ResourceNode.gd, World.gd, scripts/units/BaseUnit.gd
- Added: scripts/autoload/IdleManager.gd, tools/generate_idle_assets.py, 26 new icon/ui assets (chests, gems, daily, prestige, tap frenzy, lanes, etc)
- Total: 50 files changed, 3249 insertions, 1165 deletions

## How to Play - Idle Auto-Battler

1. **Start:** Town Hall + House + Lumber Camp + 2 Villagers + Swordsman spawned
2. **Tap Town Hall:** Get gold/food, progress to frenzy (25 taps)
3. **Build:** Tap Base → building card → tap map to place (checks 120px no overlap)
4. **Idle Gen:** Buildings auto-generate resources per second (see floating? Actually via ResourceManager)
5. **Army:** Tap Army tab → see counts, research techs (Economy, Military, Idle)
6. **Battle:** Tap Battle tab → START WAVE → select unit card (Swordsman etc) → tap lane to deploy → watch auto-battle
7. **Wave Rewards:** Gold+Food+Mana+Gems, chest chance 30%+wave*1%
8. **Shop:** Open chests (Common 100 Gold etc), claim daily, research idle techs
9. **Prestige:** At Wave 10+ and 10000 Gold, reset for Mythic Essence + permanent bonuses
10. **Offline:** Close app, return later → offline earnings popup up to 12h

## Tech Stack
- Godot 4.4, gl_compatibility renderer, ETC2/ASTC compression
- Portrait 1080x1920, canvas_items stretch keep aspect
- 5 autoloads: GameManager, ResourceManager, TechTree, SaveManager, IdleManager
- Python Pillow procedural art
- GitHub Actions: Java 17, SDK 34, Godot 4.4.1, non-gradle export

## Next Steps - v2.1
- More prestige upgrades, seasonal events, guild/leaderboard, more chest types, unit skins, cloud save
- Balance: tune gen rates, wave difficulty, chest costs based on playtesting
- Add more visual feedback: lane highlights, deploy effects, damage numbers

## Conclusion
v2.0.0 successfully addresses user feedback: controls too complex → idle auto-battler portrait with one-tap deploy, auto-battle, offline, chests, prestige. Keeps 8+8 buildings/units, expands with full idle loop. APK verified 25 MB, signed, custom icon, portrait, builds success in CI.

Release: https://github.com/KarthikGopi1234/Fantasy_RTS/releases/tag/v2.0.0
Download: https://github.com/KarthikGopi1234/Fantasy_RTS/releases/download/v2.0.0/AetherEmpires.apk
