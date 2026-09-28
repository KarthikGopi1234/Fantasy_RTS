# Aether Empires v2.0 - Idle Auto-Battler Redesign

## User Feedback
"The game does not work at all in this sense. I think the controls etc are just too complex for a touch screen. Let's maybe redesign it as a mobile focused game. Perhaps idle based?"

## New Direction: Idle Auto-Battler (Portrait)

### Core Concept
Build army, tap to deploy, combat auto-resolves, focus on upgrades & tech tree.
One-hand portrait play, no drag-box, no micro.

### Why Auto-Battler for Mobile?
- **Clash Royale / Plants vs Zombies** style lanes: tap to deploy, units auto-walk and fight
- No drag-box selection, no right-click, no precise movement
- Large touch targets, bottom nav, top resources
- Idle: resources auto-generate, offline earnings, auto-queue

### Game Loop - Full Idle

1. **Base (Idle)**
   - Town Hall auto-generates Food + Gold
   - Resource nodes (Forest, Gold Vein, Mana Crystal, Stone) auto-produce Wood, Gold, Mana, Stone if you have Villagers assigned
   - Villagers auto-gather nearest node (no micro)
   - Buildings produce over time (Barracks produces Swordsmen queue automatically)

2. **Army Building (Portrait Bottom Nav)**
   - Bottom tabs: Base | Army | Battle | Shop | Prestige
   - Base: Tap to build/upgrade buildings (large buttons)
   - Army: See your army, upgrade units, auto-queue training
   - Battle: Tap to deploy units in 3 lanes, auto-battle vs waves

3. **Battle (Auto-Battler)**
   - 3 lanes (top, mid, bottom)
   - Enemies spawn from right, walk left
   - Player taps unit portrait (bottom) then taps lane to deploy (costs Food/Gold/Mana)
   - Units auto-walk right, attack nearest enemy, use abilities auto
   - No selection, no move commands - just deploy and watch
   - Win wave → Gold + Mana + Chests

4. **Idle Systems (Expand)**
   - **Offline Earnings:** Calculate time away, give resources based on buildings/villagers
   - **Auto-Queue:** Barracks etc auto-train if resources available
   - **Tap Frenzy:** Tap Town Hall for burst resources (like Cookie Clicker)
   - **Chests:** Common, Rare, Epic, Mythic - contain Gold, Gems, unit cards
   - **Daily Rewards:** Login streak, daily quests (e.g., "Defeat 10 waves", "Build 2 houses")
   - **Prestige (Mythic Reset):** Reset Village Age → gain permanent Mana crystals + Mythic bonuses
   - **Achievements:** Permanent bonuses

5. **Resources (Keep 5)**
   - Food: Villagers, Swordsmen, Archers
   - Wood: Buildings, Houses, Walls
   - Gold: Knights, upgrades, chests
   - Mana: Mages, Golems, Dragons, prestige
   - Stone: Walls, Golems, defenses
   - **NEW:** Gems (premium, from chests, daily, prestige) for speeding up

6. **Buildings (8) - Idle Producers**
   - Town Hall: Auto Food+Gold, tap frenzy, unlocks ages
   - House: +Pop, auto Food
   - Lumber Mill (was Barracks?): Actually keep Barracks but auto-produces
   - Barracks: Auto-queue Swordsmen (cost Food)
   - Archery Range: Auto-queue Archers (Food+Wood)
   - Stable: Auto-queue Knights (Food+Gold)
   - Mage Tower: Auto-queue Mage/Golem/Dragon (Mana), produces Mana
   - Wall: Passive defense, auto-repairs
   - Market: Converts resources, offline earnings multiplier

7. **Units (8) - Auto-Battler**
   - Villager: Auto-gathers (no combat)
   - Swordsman: Tanky melee, walks, attacks nearest
   - Archer: Ranged, 120 range, glass cannon
   - Knight: Heavy, charge ability auto
   - Healer: Heals nearby allies auto
   - Mage: AoE magic, 140 range
   - Golem: Super tank, 250 HP, slow
   - Dragon: Flying, 400 HP, breathes fire AoE

8. **Tech Tree - Idle Upgrades**
   - Economy: Wheelbarrow (+Food), Double-Bit Axe (+Wood), Gold Mining, Mana Attunement (all % bonuses, idle)
   - Military: Forging (+ATK), Scale Armor (+HP), Fletching (+Range), Bloodlines (+Knight HP), Arcane Mastery (+Mage), Dragon Taming
   - Idle: Offline Earnings +25%, Auto-Queue Speed, Tap Frenzy x2, Chest Luck

### Controls - Mobile First Portrait
- **Portrait 1080x1920** - one-hand
- **No drag-box** - removed
- **Tap to build** - tap building ghost, confirm
- **Tap to deploy** - tap unit card (bottom scroll) then tap lane
- **Tap to collect** - tap resource nodes, Town Hall frenzy, chests
- **Large buttons** - bottom nav 80px tall, resource bar top
- **Auto everything** - villagers auto-gather, buildings auto-produce, combat auto

### UI - Portrait Idle
```
Top: [Food 500] [Wood 400] [Gold 300] [Mana 200] [Stone 200] [Gems 50]
Middle: Game view (base or battle lanes)
  Base: Grid of buildings, resource nodes with floating numbers
  Battle: 3 lanes with units walking, HP bars
Bottom Nav: [Base] [Army] [Battle] [Shop] [Prestige] - large icons
Bottom Action: Scrollable unit cards (Swordsman 40 Food) - tap to deploy
Popups: Chest opening, Daily Reward, Offline Earnings, Prestige confirm
```

### Technical Changes
- project.godot: viewport 1080x1920 portrait, orientation portrait
- export_presets.cfg: portrait, version 2.0.0 code 20
- GameManager: Add idle state, auto-queue, wave manager
- ResourceManager: Add auto-generation per second, offline calc
- NEW IdleManager: Offline earnings, chests, daily, prestige, gems
- World: Rewrite from drag-box to lane auto-battler
- MainUI: Rewrite from RTS HUD to portrait idle UI
- MapGenerator: Simplify to resource nodes + building grid
- BaseUnit: State machine IDLE->MOVING->ATTACKING but auto, no player commands, lane-based
- BaseBuilding: Add production timer, auto-queue

### Versioning
- v2.0.0 - Major redesign, breaking change from RTS to Idle Auto-Battler
- Code 20, Name 2.0.0
- Keep same package com.aetherempires.fantasyrts and keystore for continuity
- Tag v2.0.0

### Assets Needed
- Existing 101 assets kept
- New: Chest icons (common, rare, epic, mythic), Gem icon, Daily reward icon, Prestige icon, Lane markers, Deploy button, Tap effect, Floating numbers, Offline earnings popup
- Generate via tools/generate_assets.py extended

### DevOps
- Keep same repo, same PAT, same keystore secret
- Every milestone commit/push
- Version matches tag
- APK artifact 25MB non-gradle
- Monitor Actions
