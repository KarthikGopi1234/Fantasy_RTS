# Aether Empires - Fantasy RTS

![Version](https://img.shields.io/badge/version-1.0.12-blue)
![Engine](https://img.shields.io/badge/engine-Godot%204.4-green)
![Platform](https://img.shields.io/badge/platform-Android-orange)
![Build](https://github.com/KarthikGopi1234/Fantasy_RTS/actions/workflows/android_build.yml/badge.svg)

**A mobile-first real-time strategy game reminiscent of Age of Empires, with a fantasy mythic twist. Built for Android.**

> **Latest APK:** [v1.0.12 Release](https://github.com/KarthikGopi1234/Fantasy_RTS/releases/latest) - Properly signed, custom logo, installs correctly.

## 🎮 Game Overview

### Fantasy Setting
In the realm of Aetheria, mana flows as a resource alongside traditional materials. Lead Humans vs Orcs (expandable to Elves, Undead) through three ages of empire.

### Core Mechanics - Ambitious MVP

#### Resources (5)
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
- **Town Hall** - Produces villagers, age advancement, +5 pop
- **House** - +5 population cap
- **Barracks** - Swordsmen
- **Archery Range** - Archers
- **Stable** - Knights
- **Mage Tower** - Mage, Golem, Dragon, Healer
- **Wall** - Defense
- **Market** - Trade

#### Units (8)
- **Villager** - Gathers, builds (40 HP)
- **Swordsman** - Basic melee (60 HP, 12 ATK)
- **Archer** - Ranged (45 HP, 8 ATK, 120 range)
- **Knight** - Heavy cavalry (120 HP, 18 ATK)
- **Healer** - Support (50 HP, heals 10)
- **Mage** - Magic damage (55 HP, 25 ATK)
- **Golem** - Tank (250 HP, 30 ATK)
- **Dragon** - Ultimate (400 HP, 45 ATK, flying)

### Controls - Mobile First
- **Landscape only** - Optimized for RTS (AoE mobile style)
- **Drag-box selection** - Select multiple units
- **Tap to move** - Context-sensitive commands
- **Tap resource/enemy** - Gather / Attack
- **Build/Train menus** - Touch UI

## 📱 Installation

### From GitHub Release (Recommended)
1. Go to [Releases](https://github.com/KarthikGopi1234/Fantasy_RTS/releases/latest)
2. Download `AetherEmpires.apk` (105-120 MB)
3. Enable "Install from unknown sources" on Android
4. Install APK - **Signed with persistent keystore, custom fantasy castle logo**

### Build Status
- **v1.0.12** - ✅ Properly signed APK with custom logo, real Godot export, persistent keystore secret
- **v1.0.10** - ⚠️ Signed but used template APK (showed as godot-project-name-en)
- **v1.0.9** - ⚠️ Unsigned fallback, no logo

## 🏗️ Project Structure

```
Fantasy_RTS/
├── assets/               # Procedurally generated (101 files)
│   ├── icons/            # Resource & tech icons (app_icon_512.png custom logo)
│   ├── sprites/
│   │   ├── buildings/    # 8 buildings x 3 ages
│   │   ├── units/        # 8 units x 4 directions
│   │   └── tiles/        # 8 tile types
│   └── ui/               # Buttons, panels, bars
├── scenes/
│   ├── main.tscn         # Main game scene
│   ├── units/Unit.tscn
│   ├── buildings/Building.tscn
│   └── ResourceNode.tscn
├── scripts/
│   ├── autoload/         # GameManager, ResourceManager, TechTree, SaveManager
│   ├── units/BaseUnit.gd # State machine: IDLE, MOVING, GATHERING, ATTACKING
│   ├── buildings/BaseBuilding.gd
│   └── systems/          # World, MapGenerator, MainUI
├── tools/
│   ├── generate_assets.py      # Procedural art via Pillow
│   └── build_release_apk.py    # Real Godot export + zipalign + apksigner
├── .github/workflows/
│   └── android_build.yml       # CI/CD: Java 17, SDK 34, Godot 4.4.1, persistent keystore
├── export_presets.cfg          # Android: com.aetherempires.fantasyrts, landscape, arm64-v8a
├── project.godot               # Godot 4.4, v1.0.12
├── icon.png                    # 512x512 fantasy castle (custom)
└── debug.jks                   # Persistent JKS keystore (also stored as GitHub Secret)
```

## 🚀 DevOps - Four Tenets

### 1. Secure CI - Every Build Pushed via PAT
- All commits pushed via PAT with repo+workflow scopes
- GitHub Actions builds APK on every push to main/tags
- Signing key stored as **GitHub Secret** `ANDROID_KEYSTORE_BASE64` for continuity between versions

### 2. Version Matching - Tag == VersionCode == VersionName
- Git tag `v1.0.12` == `VERSION` file == `project.godot/config/version` == `export_presets.cfg/version/name` == `version/code=12`
- Version only bumped on **successful** build (fixed from v1.0.0-1.0.9 failures)
- Release notes auto-generated

### 3. Integrity Checks - Before/After Push
- Asset generation verified
- Godot headless check
- APK signature verified: `apksigner verify --verbose` must show `v1+v2+v3 true`
- APK contents checked: `META-INF/MANIFEST.MF`, custom mipmap icons, PCK embedded
- No regressions: game still launches

### 4. Monitor Actions - Verify Artifact
- Workflow monitors for APK artifact (100+ MB)
- Artifact uploaded as `android-apk`
- Release created on tag with APK
- Install tested (no more "godot-project-name-en" or "Installation failed")

## 🔧 Technical Details

- **Engine:** Godot 4.4.1 (gl_compatibility for mobile)
- **Language:** GDScript
- **Pathfinding:** NavigationAgent2D
- **AI:** State machine (IDLE, MOVING, GATHERING, ATTACKING)
- **Population:** AoE-style cap via Houses
- **Orientation:** Landscape only (orientation=1)
- **Min SDK:** 21, Target SDK: 34
- **Arch:** arm64-v8a
- **Signing:** JKS keystore, RSA 2048, v1+v2+v3, zipaligned, persistent across versions via Secret

## 🎨 Asset Pipeline

All assets procedurally generated via `tools/generate_assets.py` using Pillow:

- **App Icon:** 512x512 fantasy castle with dragon, fire breath, flags, night sky (replaces Godot default)
- **Resources:** 64x64 circular icons (food, wood, gold, mana, stone)
- **Tiles:** 64x64 with noise (grass, dirt, forest, gold vein, mana crystal, etc.)
- **Buildings:** 128x128 chibi castles with age tints
- **Units:** 64x64 chibi with directional variants, shadows, weapons
- **UI:** Buttons (normal/hover/pressed/disabled), panels, health bars, selection circles

Run locally:
```bash
python tools/generate_assets.py
```

## 🛠️ Local Development

```bash
# Clone
git clone https://github.com/KarthikGopi1234/Fantasy_RTS.git
cd Fantasy_RTS

# Generate assets
pip install pillow
python tools/generate_assets.py

# Run with Godot 4.4
godot --path .

# Export Android (requires Android SDK + templates)
godot --headless --export-release Android builds/AetherEmpires.apk

# Build signed APK (real export + sign)
python tools/build_release_apk.py
```

### Android SDK Setup (for local)
```bash
# Install cmdline-tools, build-tools 34.0.0, platforms android-34
# Set ANDROID_HOME
export ANDROID_HOME=$HOME/android-sdk
```

## 📦 Releases

- **v1.0.12** (code 12) - **CURRENT** - Real Godot export, properly signed with persistent keystore secret, custom logo, package com.aetherempires.fantasyrts, name "Aether Empires", installs correctly
- **v1.0.10** (code 11) - Signed but used template APK only (bug: godot-project-name-en, default icon, install failed)
- **v1.0.9** (code 10) - First successful artifact (122M) but unsigned, no logo, fallback method
- **v1.0.0-1.0.8** - Failed builds (SDK setup, gradle issues, GH001 errors)

## 🔐 Signing & Continuity

- **Keystore:** `debug.jks` (JKS, 2048-bit RSA, validity 10000 days, alias androiddebugkey)
- **Stored:** 
  - In repo (tracked) for local builds
  - As GitHub Secret `ANDROID_KEYSTORE_BASE64` (base64) for CI continuity
  - Passwords as secrets: `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
- **Signing:** `apksigner` with v1+v2+v3, `zipalign -p 4` before signing
- **Verification:** `apksigner verify --verbose` must pass, `META-INF/MANIFEST.MF` present
- **Continuity:** Same keystore used for all versions, enabling Android updates without uninstall

## 🗺️ Roadmap

- **v1.1** - Fog of war, minimap, formations
- **v1.2** - Campaign mode, Elves/Undead factions
- **v1.3** - Multiplayer (local), walls connection
- **v2.0** - Full tech tree, hero units, spells

## 📄 License

MIT - Feel free to expand!

## 👾 Credits

- Engine: Godot 4.4.1
- Design: AoE-inspired, Fantasy twist
- Art: Procedural via Python/Pillow
- DevOps: GitHub Actions CI/CD with persistent signing

---

**Built with ❤️ for mobile RTS fans - Now properly signed and installable!**
