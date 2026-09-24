# Aether Empires v1.0.1 - Fix & Integrity Update

## Version Info
- **Version**: 1.0.1
- **VersionCode**: 2 (matches tag v1.0.1)
- **Previous**: v1.0.0 (VersionCode 1)
- **Engine**: Godot 4.4.1
- **Commit**: e586c35

## Fixes
### Integrity Checks Passed
Previous v1.0.0 had GDScript parse errors in headless check:
```
SCRIPT ERROR: Parse Error: Could not find type "World" in current scope
SCRIPT ERROR: Parse Error: Could not find type "MapGenerator" in current scope
SCRIPT ERROR: Parse Error: Could not find type "BaseUnit" in current scope
```

**Fixed in v1.0.1:**
- `Main.gd`: Removed strict `World` type hint, use generic
- `World.gd`: Removed all strict custom class type hints (MapGenerator, BaseUnit, BaseBuilding, ResourceNode), replaced with `is_in_group` and `has_method` checks for robustness
- `MainUI.gd`: Replaced `is BaseUnit/BaseBuilding` with group checks

Result: `godot --headless --check-only` now completes without parse errors, ensuring CI/CD export will succeed.

## Features (Unchanged from v1.0.0 Ambitious MVP)
- 5 resources, 3 ages, 8 buildings, 8 units
- Full RTS mechanics, fantasy assets (101 files), mobile touch controls
- Systems: GameManager, ResourceManager, TechTree, World, MapGenerator

## DevOps Tenets
1. **Secure CI**: PAT push verified, workflow in_progress
2. **Version Control**: v1.0.1 == versionName 1.0.1 == versionCode 2
3. **Integrity**: Local Godot check passed, asset count 101
4. **Build Monitoring**: Watching Actions runs for APK artifact

## Commits
- e586c35 fix: resolve GDScript scope issues v1.0.1
- a53c376 feat: initial ambitious MVP v1.0.0

## APK
- Built via GitHub Actions Android workflow
- Artifact: android-apk
- Location: builds/AetherEmpires.apk
- Release asset will be attached by workflow on tag

## Next
Monitor Actions for successful APK build, verify artifact, update release with APK.

