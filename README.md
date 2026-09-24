# Aether Empires - Fantasy RTS

**A mobile-first real-time strategy game reminiscent of Age of Empires, with a fantasy mythic twist.**

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Engine](https://img.shields.io/badge/engine-Godot%204.4-green)
![Platform](https://img.shields.io/badge/platform-Android-orange)

## 🎮 Game Overview

Aether Empires is a standalone mobile RTS optimized for Android, featuring:

### Fantasy Setting
- **Factions**: Humans vs Orcs (expandable to Elves, Undead)
- **Lore**: In the realm of Aetheria, mana flows as a resource alongside traditional materials

### Core Mechanics (Ambitious MVP)

#### Resources (4+1)
- **Food** - Villagers, infantry
- **Wood** - Buildings, archers
- **Gold** - Advanced units, tech
- **Mana** - Magic units, mythic age
- **Stone** - Defenses, golems

#### Ages (3)
1. **Village Age** - Basic economy, villagers, swordsmen
2. **Kingdom Age** - Archers, knights, healers, markets, walls
3. **Mythic Age** - Mages, golems, dragons, arcane tech

#### Buildings (8)
- Town Hall (TC) - Produces villagers, age advancement, +5 pop
- House - +5 population cap
- Barracks - Swordsmen
- Archery Range - Archers
- Stable - Knights
- Mage Tower - Mage, Golem, Dragon, Healer
- Wall - Defense
- Market - Trade (future)

#### Units (8)
- **Villager** - Gathers, builds (40 HP, 4 ATK)
- **Swordsman** - Basic melee (60 HP, 12 ATK)
- **Archer** - Ranged (45 HP, 8 ATK, 120 range)
- **Knight** - Heavy cavalry (120 HP, 18 ATK)
- **Healer** - Support (50 HP, heals 10)
- **Mage** - Magic damage (55 HP, 25 ATK, 140 range)
- **Golem** - Tank (250 HP, 30 ATK, 4 armor)
- **Dragon** - Ultimate (400 HP, 45 ATK, flying)

#### Tech Tree
- **Economy**: Wheelbarrow, Double-Bit Axe, Gold Mining, Mana Attunement
- **Military**: Forging, Scale Armor, Fletching, Bloodlines, Arcane Mastery, Dragon Taming

### Controls (Mobile-First)
- **Landscape only** - Optimized for RTS
- **Drag-box selection** - Select multiple units
- **Tap to move** - Right-click equivalent
- **Tap resource/enemy** - Context actions (gather/attack)
- **Build menu** - Place buildings
- **Train menu** - Queue units

## 🏗️ Architecture

```
Fantasy_RTS/
├── assets/               # Procedurally generated sprites
│   ├── icons/            # Resource & tech icons
│   ├── sprites/
│   │   ├── buildings/    # 8 buildings x 3 age variants
│   │   ├── units/        # 8 units x 4 directions
│   │   └── tiles/        # 8 tile types
│   └── ui/               # Buttons, panels, bars
├── scenes/
│   ├── main.tscn         # Main game scene
│   ├── units/Unit.tscn
│   ├── buildings/Building.tscn
│   └── ResourceNode.tscn
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd      # Core state, selection, pop
│   │   ├── ResourceManager.gd  # 4 resources + caps
│   │   ├── TechTree.gd         # Ages, unlocks, stats
│   │   └── SaveManager.gd      # JSON save
│   ├── units/BaseUnit.gd       # State machine AI
│   ├── buildings/BaseBuilding.gd
│   └── systems/
│       ├── World.gd            # Spawning, input, AI
│       ├── MapGenerator.gd     # Procedural map
│       ├── ResourceNode.gd
│       └── MainUI.gd           # HUD
├── tools/
│   └── generate_assets.py      # Procedural asset pipeline
├── .github/workflows/
│   └── android_build.yml       # CI/CD pipeline
├── export_presets.cfg          # Android export
├── project.godot               # Godot 4.4 config
└── icon.png                    # App icon (512x512)
```

## 🚀 DevOps & CI/CD

### Tenets Implemented
1. **Secure CI**: Every commit pushed via PAT, GitHub Actions builds APK
2. **Version Control**: Git tag v1.0.0 == versionCode 1 & versionName 1.0.0
3. **Integrity Checks**: Local verification, Godot check-only, asset generation
4. **Build Monitoring**: Workflow watches for APK artifact, release creation

### Local Development
```bash
# Generate assets
python tools/generate_assets.py

# Run with Godot 4.4
godot --path . 

# Export Android (requires templates)
godot --headless --export-release Android builds/AetherEmpires.apk
```

### GitHub Actions
- Triggers on push to main, tags v*, PRs, manual dispatch
- Downloads Godot 4.4.1 + export templates
- Generates assets
- Exports APK (release & debug fallback)
- Uploads artifact
- Creates GitHub Release on tag with APK + auto notes

## 📦 Releases

- **v1.0.0** - Initial Ambitious MVP
  - All 8 buildings, 8 units, 3 ages
  - Resource gathering, combat, building placement
  - Fantasy procedural assets
  - Mobile touch controls
  - Android APK via CI/CD

## 🎨 Asset Pipeline

All assets are procedurally generated via `tools/generate_assets.py` using Pillow:
- **App Icon**: 512x512 fantasy castle with dragon, fire breath
- **Resources**: 64x64 circular icons with type-specific drawings
- **Tiles**: 64x64 with noise, specific details (forest, gold vein, mana crystal)
- **Buildings**: 128x128 chibi castles with age variants (tint overlay)
- **Units**: 64x64 chibi style with directional markers, shadow, weapon
- **UI**: Buttons (normal/hover/pressed/disabled), panels, health bars, selection circles

If external generation fails, placeholders are used.

## 🔧 Technical Details

- **Engine**: Godot 4.4.1 (gl_compatibility renderer for mobile)
- **Language**: GDScript
- **Pathfinding**: NavigationAgent2D (built-in)
- **AI**: Simple state machine (IDLE, MOVING, GATHERING, ATTACKING)
- **Population**: Cap system like AoE (houses increase cap)
- **Orientation**: Landscape only (package/orientation=1)
- **Min SDK**: Default Godot (21+)
- **Arch**: arm64-v8a

## 📱 Android Build

APK is built automatically via GitHub Actions:
1. Go to Actions tab
2. Latest workflow run -> Artifacts -> android-apk
3. Or download from Releases page

Local APK at `builds/AetherEmpires.apk` (after export)

## 🗺️ Roadmap

- **v1.1**: Fog of war, minimap, formations
- **v1.2**: Campaign mode, 2 more factions
- **v1.3**: Multiplayer (local), walls connection logic
- **v2.0**: Full tech tree, hero units, spells

## 📄 License

MIT - Feel free to expand!

## 👾 Credits

- **Engine**: Godot 4.4
- **Design**: AoE-inspired, Fantasy twist
- **Art**: Procedural via Python/Pillow
- **DevOps**: GitHub Actions CI/CD

---

**Built with ❤️ for mobile RTS fans**
