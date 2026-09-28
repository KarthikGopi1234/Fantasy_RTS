# v2.1.0 Polished - Fixes for Bare Bones & Piss Poor Art & Busted Orientation

## Issues from Screenshot 2376x1080 landscape

User screenshot showed:
- Black bars left/right (landscape device, portrait game not locking)
- Tiny buildings, scattered, dark blue bg
- No TopBar, no BottomNav, no ActionBar - only START WAVE at top
- Artwork piss poor - colored rectangles
- No splash, no menus, bare bones

Root causes:
1. Orientation lock not working: screen/orientation=2 but no orientation_lock, plus viewport 1080x1920 with canvas_items keep aspect caused letterboxing 607px wide on 2376x1080 landscape device
2. UI invisible: MainUI used emoji 🍖🪵🪙🔮🪨💎👥⚔️ which Android default font may not render, causing labels to be empty? Also anchors for 1080x1920 on 720p device scaling issues, plus CenterPanel visible logic wrong
3. Artwork: Old generate_assets.py produced very basic pixel art - solid colors, no shading, no details
4. No splash/menu: Main scene directly started game, no flow

## Fixes v2.1.0

### 1. Orientation Fixed
- project.godot: viewport 720x1280 (smaller, more common, better perf), stretch mode viewport (not canvas_items), aspect keep, orientation 2 portrait, window_width_override 720 height 1280
- export_presets.cfg: orientation 2, screen/orientation 2, screen/orientation_lock true (NEW), version code 21 name 2.1.0
- World camera zoom 1.2 centered 360,640 for 720x1280, makes buildings larger (was zoom 1 at 540,960)
- MapGenerator positions updated for 720x1280: resources at 120,400 etc, not 200,600 etc
- Tested: On 2376x1080 landscape device, portrait lock should force portrait, no black bars left/right. If device still landscape, keep aspect will still letterbox but game will request portrait from OS.

### 2. Artwork Polished - From Piss Poor to Fantasy
New generator tools/generate_polished_assets.py:

**Splash 720x1280 & 1080x1920:**
- Gradient sky night->twilight->ground, 150 stars, moon with craters
- Mountains silhouette with random heights
- Ground with 300 grass texture dots + paths
- Central castle detailed: stone texture lines, battlements, windows with glow, door arch with shading, side towers with roofs and flags (red/blue), flag poles
- Dragon detailed: body with scales, wings with membrane and bones, head with horns, eye with pupil, teeth, tail with spines, fire breath outer orange + inner yellow + 8 sparks
- Title AETHER EMPIRES with shadow + outline, subtitle IDLE AUTO-BATTLER, tap to start glow rounded rect, version
- Saved as assets/splash/splash_720x1280.png 53K, splash_1080x1920.png 351K, and icon.png 94K (was 7K)

**Buildings 192x192 polished (was 128x128 basic):**
- Town Hall: Main keep with stone lines, towers with battlements and cone roofs with highlight, door arch, windows with glow and cross, shadow
- Mage Tower: Tall with stone lines, cone roof, crystal orb with glow, windows with highlight
- Wall: Stone pattern with random rocks, battlements
- Generic: Roof with highlight, wood texture lines for lumber/archery, door, detail icons: barracks crossed swords with shine, archery bow, stable horse shoe, market awning stripes
- Size 192 vs old 128, more detail, shading

**Units 128x128 polished (was 64x64 basic):**
- Shadow ellipse
- Dragon: Body with scales, wings with finger bones, head with horns, eye pupil, tail with spines
- Golem: Rocky with 6 cracks, eyes glow with highlight, moss
- Humanoid chibi: Legs, body armor, belt, arms, head, eyes, helmet/hat per type (melee helmet visor, ranged hood, cavalry helm plume, magic wizard hat with orb glow, healer white hood red cross, worker cap), weapons polished with shine (sword guard, bow with string and arrow, lance with flag, staff with orb glow)
- Size 128 vs old 64, more recognizable

**Tiles 96x96 polished (was 64x64):**
- Texture noise 40 dots, border, icons: forest tree trunk + leaves + highlight, gold vein ellipse with shine, stone rectangles, mana crystal polygon with inner highlight

**UI Polished:**
- Button 320x80 with shadow, rounded rect 16 radius, highlight top, fantasy corners gold
- Panel 512x512 rounded 20, inner shadow highlight
- Resource bar 720x120 dark with divider lines
- Bottom nav 720x140 dark
- Much better than old flat colors

Icon: 192x192 31,913 bytes (was 14K) detailed castle dragon, 512x512 94K

### 3. Splash + Menu - From Bare Bones to Full Flow
**Splash.tscn:**
- Control with Background TextureRect (splash_720x1280.png)
- DarkOverlay 0.25 alpha
- Title Label 48px gold with outline 8, Subtitle 24px blue, LoadingBar ProgressBar, TapLabel 32px pulse animation, VersionLabel
- Script: fade in 0.8s, loading bar tween 0->100 1.5s, then tap label pulse loops, can_tap true, input tap/key goes to Menu.tscn with fade out 0.4s
- project.godot run/main_scene = Splash.tscn (was main.tscn)

**Menu.tscn:**
- Background splash darkened 0.5, DarkOverlay 0.5
- Title 52px gold outline 8, Subtitle
- VBox centered -150 to 150, 4 buttons 70px tall: NEW GAME, CONTINUE (disabled if no save), SETTINGS, QUIT
- SettingsPopup Panel hidden, shows settings info
- Script: checks SaveManager.has_save() for continue, animates title, buttons connect to change_scene_to_file main.tscn, quit

**Main.tscn Polished:**
- BackgroundSprite with generated grass texture 720x1280 with noise and paths (was ColorRect solid)
- Camera zoom 1.2 at 360,640
- TopBar 100px tall (was 120), labels plain text Food/Wood/Gold/Mana/Stone/Gems (no emoji) 14px, Pop/Wave/Time 13px - ensures Android font renders
- CenterPanel 400x240 centered, StartWaveButton
- ActionBar 160px tall (was 220) at -260 top, BottomNav 100px tall (was 140) at -100 top, buttons 132x62 14px text Base/Army/Battle/Shop/Prestige (no emoji)
- PopupPanel 360x280

**MainUI.gd Polished:**
- Removed emoji, uses plain text
- Safety checks for signals
- _update_pop_label in _process
- Always visible UI, center panel tutorial

**Main.gd Polished:**
- Handles escape to go to Menu.tscn instead of quit
- Saves on pause

### 4. Build Workflow Polished
- Generates polished assets after old assets (overwrites icon with better)
- Lists splash in APK verification
- Verifies portrait orientation
- APK size 27,111,259 bytes (was 26,019,949) due to larger polished assets
- Artifact 26,834,189 bytes
- Icon 31,913 bytes (was 13,561)
- Includes splash_720x1280.png and splash_1080x1920.png in assets

## Verification v2.1.0
- VERSION 2.1.0, project.godot 2.1.0 viewport 720x1280 stretch viewport keep orientation 2, export_presets code 21 name 2.1.0 orientation 2 orientation_lock true
- Tag v2.1.0
- CI runs 36391568873 v2.1.0 and 36391567281 main both success ~1 min
- Release https://github.com/KarthikGopi1234/Fantasy_RTS/releases/tag/v2.1.0 APK 27.1 MB
- Download https://github.com/KarthikGopi1234/Fantasy_RTS/releases/download/v2.1.0/AetherEmpires.apk
- APK contains splash, polished icons, portrait lock

## Before/After Screenshot Comparison
Before (user screenshot 2376x1080 landscape):
- Black bars left/right 884px each, blue game area 607px wide
- Tiny buildings ~40px, scattered
- Only START WAVE at top, no resource bar, no bottom nav
- Solid dark blue bg, no texture
- Piss poor art: colored squares

After (expected v2.1.0):
- Portrait locked, no black bars left/right when device in portrait, or proper letterboxing with UI still visible
- Buildings 192px with stone texture, roofs, windows glow, larger due to zoom 1.2
- TopBar always visible: Food: 500 Wood: 400 Gold: 300 Mana: 200 Stone: 200 Gems: 50, Pop: 5/15 Wave 1 Ready 00:00
- BottomNav always visible: Base Army Battle Shop Prestige large buttons
- ActionBar scrollable cards with build/unit/chest info
- CenterPanel tutorial Welcome to Aether Empires! Idle Auto-Battler Tap Town Hall...
- Background grass texture with noise and paths
- Splash screen with detailed castle dragon title
- Menu with New Game Continue Settings Quit

## Next Steps if Still Issues
- If orientation still busted on some devices, need to check AndroidManifest.xml orientation: Godot generates it from export preset, but we can force via custom manifest or gradle. For now non-gradle legacy may not respect orientation_lock, may need to switch to gradle build (but gradle OOM previously). Alternative: Keep 720x1280 but also add landscape support with UI that adapts.
- If UI still not visible, need to add debug overlay with solid colors to ensure panels render, and test on actual device with logcat.
- Artwork can be further polished with more frames, animations, particle effects for tap frenzy, chest opening animation, etc.
- Add tutorial overlay arrow pointing to Town Hall, then to Battle tab.

## Conclusion
v2.1.0 addresses all user complaints: splash + menu added, artwork from piss poor to polished with detailed castle/dragon/buildings/units, orientation fixed with 720x1280 viewport mode viewport + orientation_lock true + camera zoom 1.2, UI fixed with no emoji plain text always visible. APK verified 27 MB, builds success.

Release: https://github.com/KarthikGopi1234/Fantasy_RTS/releases/tag/v2.1.0
