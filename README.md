# Aether Empires - Idle Auto-Battler

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Engine](https://img.shields.io/badge/engine-Godot%204.4-green)
![Platform](https://img.shields.io/badge/platform-Android-orange)
![Build](https://github.com/KarthikGopi1234/Fantasy_RTS/actions/workflows/android_build.yml/badge.svg)
![Orientation](https://img.shields.io/badge/orientation-Portrait-purple)

**A mobile-first idle auto-battler inspired by Age of Empires, redesigned for one-hand portrait play. Build your empire, deploy armies in 3 lanes, and conquer waves!**

> **Latest APK:** [v2.0.0 Release](https://github.com/KarthikGopi1234/Fantasy_RTS/releases/latest) - Idle Auto-Battler Edition, Portrait, Offline Earnings, Chests, Prestige!

## 🔄 v2.0.0 Redesign - Why Idle?

**User Feedback:** *"The game does not work at all in this sense. I think the controls etc are just too complex for a touch screen. Let's maybe redesign it as a mobile focused game. Perhaps idle based?"*

**Solution:** Complete redesign from RTS drag-box micro to idle auto-battler:
- ❌ Removed: Drag-box selection, right-click commands, precise unit movement
- ✅ Added: Tap to deploy, auto-battle lanes, offline earnings, auto-queue, tap frenzy, chests, daily rewards, prestige

## 🎮 Game Overview - Idle Auto-Battler

### Core Concept
**Build army → Tap lane to deploy → Combat auto-resolves → Focus on upgrades & tech**

One-hand portrait play, no micro, large touch targets, bottom nav.

### Game Loop - Full Idle Progression

#### 1. Base (Idle)
- **Town Hall** auto-generates Food + Gold, tap for frenzy bonus
- **Resource buildings** (Lumber Camp, Market, Mage Tower, House) auto-produce Wood, Gold, Mana, Food
- **Villagers** auto-gather (no micro needed)
- **Barracks** etc auto-queue units when resources available

#### 2. Army Building (Portrait Bottom Nav)
- Bottom tabs: **Base | Army | Battle | Shop | Prestige** (80px tall, thumb-friendly)
- **Base:** Tap to build/upgrade buildings (large buttons)
- **Army:** See your army, upgrade units, research tech
- **Battle:** Tap to deploy units in 3 lanes, auto-battle vs waves
- **Shop:** Chests, daily rewards, idle upgrades
- **Prestige:** Mythic reset for permanent bonuses

#### 3. Battle (Auto-Battler - 3 Lanes)
- 3 lanes (top, mid, bottom) - like Clash Royale / Plants vs Zombies
- Enemies spawn from right, walk left
- Player taps unit card (bottom scroll) then taps lane to deploy (costs Food/Gold/Mana)
- Units auto-walk right, attack nearest enemy, use abilities auto
- No selection, no move commands - just deploy and watch!
- Win wave → Gold + Mana + Gems + Chest chance

#### 4. Idle Systems (Full)
- **Offline Earnings:** Calculates time away (up to 12h), gives resources based on buildings
- **Auto-Queue:** Barracks etc auto-train if resources + pop available
- **Tap Frenzy:** Tap Town Hall 25 times → x3 resources for 10s (like Cookie Clicker)
- **Chests:** Common (100 Gold), Rare (400 Gold+10 Gems), Epic (1000 Gold+40 Gems), Mythic (150 Gems) - contain Gold, Gems, resources
- **Daily Rewards:** 7-day streak, daily quests (Defeat 10 waves, Build 3 buildings, etc)
- **Prestige (Mythic Reset):** Reset Village Age → gain Mythic Essence + permanent multipliers (x5% per prestige)
- **Achievements:** First Blood, Builder (10 buildings), Legion (100 units), Veteran (Wave 25), Mythic Slayer (Wave 50), etc

### Resources (5 + Gems)
- **Food** - Villagers, Swordsmen, Archers
- **Wood** - Buildings, Houses, Walls
- **Gold** - Knights, upgrades, chests
- **Mana** - Mages, Golems, Dragons, prestige
- **Stone** - Walls, Golems, defenses
- **Gems (NEW)** - Premium, from chests, daily, prestige, waves - speed up, buy chests

### Buildings (8) - Idle Producers
- **Town Hall** - Auto Food+Gold, tap frenzy, unlocks ages, +5 Pop
- **House** - +5 Pop, +0.2 Food/s
- **Lumber Camp** - +0.6 Wood/s
- **Barracks** - Auto-queue Swordsmen
- **Archery Range** - Auto-queue Archers
- **Stable** - Auto-queue Knights
- **Mage Tower** - Auto-queue Mage/Golem/Dragon, +0.5 Mana/s
- **Wall** - Passive defense (future: blocks lane)
- **Market** - +0.4 Gold/s, offline earnings x1.2

### Units (8) - Auto-Battler
- **Villager** - Auto-gathers (40 HP)
- **Swordsman** - Tanky melee, walks, attacks nearest (80 HP, 15 ATK)
- **Archer** - Ranged, 140 range, glass cannon (50 HP, 12 ATK)
- **Knight** - Heavy, charge auto (150 HP, 22 ATK)
- **Healer** - Heals nearby allies auto (60 HP, heal 15)
- **Mage** - AoE magic, 160 range (65 HP, 30 ATK)
- **Golem** - Super tank, 300 HP, slow
- **Dragon** - Flying, 450 HP, breathes fire AoE (3 targets)

### Tech Tree - Idle Upgrades
- **Economy:** Wheelbarrow (+20% Food), Double-Bit Axe (+25% Wood), Gold Mining (+20% Gold), Stone Quarry (+30% Stone), Mana Attunement (+30% Mana)
- **Military:** Forging (+3 ATK infantry), Scale Armor (+2 Armor +20 HP), Fletching (+3 ATK +20 Range archers), Bloodlines (+30 HP knights), Arcane Mastery (+50% Mage DMG), Dragon Taming (+25% Dragon HP), Golem Forging (+50 HP +5 ATK), Healing Light (+50% heal)
- **Idle:** Offline Earnings I/II (+25%/+50%), Auto-Queue, Efficient Production (20% faster), Tap Frenzy, Frenzy Mastery (x4 +5s), Chest Luck (+15% rare), Market Efficiency (+20% Gold + offline x1.2)

### Prestige Upgrades (Permanent)
- **Eternal Harvest** - Food +10% per level (max 10)
- **Midas Touch** - Gold +10% per level (max 10)
- **Arcane Legacy** - Mana +15% per level (max 10)
- **Master Builder** - Build speed +20% per level (max 5)
- **Warlord Soul** - Unit HP+5% ATK+5% per level (max 10)
- **Offline Mastery** - Offline +25% per level (max 5)
- **Starting Boost** - Start with extra resources per level (max 5)

## 📱 Controls - Mobile First Portrait

- **Portrait 1080x1920** - One-hand play, thumb reachable bottom nav
- **No drag-box** - Removed completely
- **Tap to build** - Tap building card, then tap map to place
- **Tap to deploy** - Tap unit card (bottom scroll) then tap lane (3 lanes)
- **Tap to collect** - Tap resource nodes, Town Hall frenzy, chests
- **Large buttons** - Bottom nav 80px tall, resource bar top, action bar 220px
- **Auto everything** - Villagers auto-gather, buildings auto-produce, combat auto

### UI Layout - Portrait Idle
```
Top: [🍖 Food] [🪵 Wood] [🪙 Gold] [🔮 Mana] [🪨 Stone] [💎 Gems]
     [👥 Pop] [⚔️ Wave] [⏰ Time] [🔥 Frenzy]
Middle: Game view (base or battle lanes)
  Base: Grid of buildings, resource nodes with floating numbers, tap effects
  Battle: 3 lanes with units walking, HP bars, lane highlights
Center: Wave start / victory panel
Action: Scrollable cards (Build, Units, Shop, Prestige) - horizontal scroll
Bottom Nav: [🏠 Base] [⚔️ Army] [🔥 Battle] [🛒 Shop] [✨ Prestige] - large icons
Popups: Chest opening, Daily Reward, Offline Earnings, Prestige confirm, Tap Frenzy
```

## 📱 Installation

### From GitHub Release (Recommended)
1. Go to [Releases](https://github.com/KarthikGopi1234/Fantasy_RTS/releases/latest)
2. Download `AetherEmpires.apk` (~25 MB, non-gradle legacy build)
3. Enable "Install from unknown sources" on Android
4. Install APK - **Signed with persistent keystore, custom castle logo, portrait**

### Build Status
- **v2.0.0** - 🆕 Idle Auto-Battler redesign, portrait, offline, chests, prestige, full idle loop
- **v1.0.12** - ✅ Properly signed APK with custom logo, real Godot export (25 MB, not 105 MB template)
- **v1.0.11** - ✅ Same as 1.0.12 but version code 12
- **v1.0.10** - ⚠️ Signed but used template APK (showed as godot-project-name-en)
- **v1.0.9** - ⚠️ Unsigned fallback

## 🏗️ Project Structure

```
Fantasy_RTS/
├── assets/               # Procedurally generated (120+ files)
│   ├── icons/            # Resource icons + idle icons (chests, gems, daily, prestige, tap frenzy)
│   ├── sprites/
│   │   ├── buildings/    # 8 buildings x 3 ages
│   │   ├── units/        # 8 units x 4 directions
│   │   └── tiles/        # 8 tile types
│   └── ui/               # Buttons, panels, bars + lane markers, offline popup
├── scenes/
│   ├── main.tscn         # Portrait 1080x1920 idle scene
│   ├── units/Unit.tscn   # Auto-battler unit
│   ├── buildings/Building.tscn # Idle producer building
│   └── ResourceNode.tscn # Tap to collect
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd      # Idle state, waves, lanes, auto-queue
│   │   ├── ResourceManager.gd  # Auto-gen, offline calc, frenzy, fractional buffer
│   │   ├── TechTree.gd         # 3 ages + idle techs + building/unit stats
│   │   ├── SaveManager.gd      # v2 save with wave + timestamp
│   │   └── IdleManager.gd      # NEW: Offline, chests, daily, quests, prestige, achievements
│   ├── units/BaseUnit.gd       # Auto lane movement, no micro, dragon breath AoE
│   ├── buildings/BaseBuilding.gd # Idle gen, auto-queue, tap bonus, upgrade
│   └── systems/
│   │   ├── World.gd            # Lane auto-battler, tap handling, floating text
│   │   ├── MapGenerator.gd     # Simple base decoration
│   │   └── MainUI.gd           # Portrait idle UI, bottom nav, action bar, popups
│   ├── Main.gd                 # Entry, save on pause
├── tools/
│   ├── generate_assets.py      # Original fantasy assets
│   ├── generate_idle_assets.py # NEW: Chests, gems, daily, prestige, lanes
│   └── build_release_apk.py    # Real Godot export + zipalign + apksigner
├── .github/workflows/
│   └── android_build.yml       # CI/CD: Java 17, SDK 34, Godot 4.4.1, non-gradle, persistent keystore
├── export_presets.cfg          # Android: com.aetherempires.fantasyrts, portrait, arm64-v8a, v2.0.0 code 20
├── project.godot               # Godot 4.4, viewport 1080x1920 portrait, 5 autoloads
├── icon.png                    # 512x512 fantasy castle (custom)
├── VERSION                     # 2.0.0
└── debug.jks                   # Persistent JKS keystore (also stored as GitHub Secret)
```

## 🔧 DevOps & Build

### Versioning Tenets (Strict)
- **Tag == VERSION == project.godot == export_presets.cfg** - Must match exactly
- **v2.0.0** = versionCode 20, versionName 2.0.0, portrait orientation
- **APK Integrity:** apksigner verify v1+v2+v3 true, aapt2 dump badging package com.aetherempires.fantasyrts, label Aether Empires, custom icon
- **CI/CD:** Every milestone push to main + tag via PAT, monitor Actions for success (~1 min non-gradle)
- **Keystore Continuity:** Same debug.jks stored as ANDROID_KEYSTORE_BASE64 secret for updates

### Local Build
```bash
# Generate assets
python3 tools/generate_assets.py
python3 tools/generate_idle_assets.py

# Export APK (requires Godot 4.4 headless)
godot --headless --export-release Android builds/AetherEmpires.apk

# Verify
apksigner verify --verbose builds/AetherEmpires.apk
aapt2 dump badging builds/AetherEmpires.apk | grep -E "package|label|icon"
```

## 🎯 Roadmap - Idle Expansion

### v2.0 Done
- [x] Portrait 1080x1920
- [x] 3-lane auto-battler
- [x] Offline earnings (12h cap)
- [x] Auto-queue
- [x] Tap frenzy (25 taps → x3 10s)
- [x] Chests (Common, Rare, Epic, Mythic)
- [x] Daily rewards (7-day streak)
- [x] Daily quests (3 random)
- [x] Prestige (Mythic reset) + 7 permanent upgrades
- [x] Achievements (8)
- [x] Full idle tech tree (Economy, Military, Idle)

### v2.1 Planned
- [ ] More prestige upgrades (10+)
- [ ] Seasonal events
- [ ] Guild / leaderboard (offline)
- [ ] More chest types (Seasonal)
- [ ] Unit skins (cosmetic gems)
- [ ] Cloud save

## 📄 License
MIT - Feel free to fork and expand!

## 🙏 Credits
- **Engine:** Godot 4.4
- **Art:** Procedural via Pillow (no external assets)
- **Design:** Inspired by Age of Empires + Clash Royale + Cookie Clicker + Idle Miner
- **Redesign Feedback:** Touch controls too complex → Idle Auto-Battler portrait

---

**Aether Empires v2.0.0 - Idle Auto-Battler - Built for one-hand portrait play! 🏰⚔️💎**
