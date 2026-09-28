#!/usr/bin/env python3
"""
Idle Assets Generator - extends generate_assets.py
Generates chests, gems, idle UI icons, lane markers, etc.
"""

from PIL import Image, ImageDraw
import os
import random

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
ICONS_DIR = os.path.join(ASSETS_DIR, "icons")
UI_DIR = os.path.join(ASSETS_DIR, "ui")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")

for d in [ICONS_DIR, UI_DIR, SPRITES_DIR, os.path.join(ASSETS_DIR, "sprites/buildings"), os.path.join(ASSETS_DIR, "sprites/units")]:
    os.makedirs(d, exist_ok=True)

def generate_idle_icons():
    # Gems
    for name, color in [("gems", (100, 255, 255)), ("gem_common", (100,255,255)), ("gem_rare", (100,100,255)), ("gem_epic", (200,50,255)), ("gem_mythic", (255,200,50))]:
        img = Image.new('RGBA', (64,64), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        # Gem shape
        draw.polygon([(32,6), (52,24), (48,48), (16,48), (12,24)], fill=color, outline=(0,0,0,255), width=2)
        draw.polygon([(32,6), (32,24), (12,24)], fill=(255,255,255,120))
        draw.ellipse([24,20,40,36], fill=(255,255,255,180))
        img.save(os.path.join(ICONS_DIR, f"{name}.png"))
        print(f"Generated {name}")

    # Chests
    chest_defs = {
        "chest_common": {"base": (160,120,80), "trim": (100,70,40), "gems": 0},
        "chest_rare": {"base": (80,120,200), "trim": (200,200,220), "gems": 1},
        "chest_epic": {"base": (160,60,200), "trim": (220,180,50), "gems": 2},
        "chest_mythic": {"base": (220,180,40), "trim": (255,220,100), "gems": 3},
    }
    for name, spec in chest_defs.items():
        img = Image.new('RGBA', (96,96), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        # Shadow
        draw.ellipse([16,72,80,88], fill=(0,0,0,80))
        # Base
        draw.rectangle([16,40,80,72], fill=spec["base"], outline=(0,0,0,255), width=3)
        # Lid
        draw.rectangle([12,24,84,44], fill=spec["base"], outline=(0,0,0,255), width=3)
        # Trim
        draw.rectangle([12,36,84,44], fill=spec["trim"], outline=(0,0,0,255), width=2)
        # Lock
        draw.rectangle([40,48,56,60], fill=(255,215,0), outline=(0,0,0,255), width=2)
        draw.ellipse([44,52,52,60], fill=(0,0,0,255))
        # Gems on chest for rare+
        if spec["gems"] >=1:
            draw.ellipse([20,28,32,40], fill=(100,200,255), outline=(0,0,0,255), width=1)
        if spec["gems"] >=2:
            draw.ellipse([64,28,76,40], fill=(255,100,255), outline=(0,0,0,255), width=1)
        if spec["gems"] >=3:
            draw.ellipse([40,16,56,28], fill=(255,255,100), outline=(0,0,0,255), width=2)
        # Highlight
        draw.rectangle([20,28,80,32], fill=(255,255,255,60))
        img.save(os.path.join(ICONS_DIR, f"{name}.png"))
        img.save(os.path.join(UI_DIR, f"{name}.png"))
        print(f"Generated {name}")

    # Daily reward icon
    img = Image.new('RGBA', (96,96), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([8,24,88,84], fill=(200,50,50), outline=(0,0,0,255), width=3)
    draw.rectangle([8,8,88,32], fill=(255,220,100), outline=(0,0,0,255), width=3)
    draw.rectangle([36,8,60,84], fill=(255,220,100), outline=(0,0,0,255), width=2)
    draw.rectangle([8,36,88,60], fill=(255,220,100), outline=(0,0,0,255), width=2)
    draw.ellipse([38,38,58,58], fill=(255,50,50), outline=(0,0,0,255), width=2)
    img.save(os.path.join(ICONS_DIR, "daily_reward.png"))
    img.save(os.path.join(UI_DIR, "daily_reward.png"))
    print("Generated daily_reward")

    # Prestige icon
    img = Image.new('RGBA', (96,96), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    # Star / sparkles
    draw.polygon([(48,8), (56,36), (84,36), (62,52), (70,80), (48,64), (26,80), (34,52), (12,36), (40,36)], fill=(200,150,255), outline=(0,0,0,255), width=3)
    draw.ellipse([40,40,56,56], fill=(255,255,200), outline=(0,0,0,255), width=2)
    img.save(os.path.join(ICONS_DIR, "prestige.png"))
    img.save(os.path.join(UI_DIR, "prestige.png"))
    print("Generated prestige")

    # Tap frenzy icon
    img = Image.new('RGBA', (96,96), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    # Hand tapping
    draw.ellipse([24,16,72,64], fill=(255,220,180), outline=(0,0,0,255), width=3)
    # Finger
    draw.ellipse([32,8,56,36], fill=(255,220,180), outline=(0,0,0,255), width=2)
    # Tap effect rings
    draw.ellipse([12,12,84,84], outline=(255,200,50,200), width=3)
    draw.ellipse([4,4,92,92], outline=(255,200,50,120), width=2)
    img.save(os.path.join(ICONS_DIR, "tap_frenzy.png"))
    img.save(os.path.join(UI_DIR, "tap_frenzy.png"))
    print("Generated tap_frenzy")

    # Lane markers
    for i, name in enumerate(["lane_top", "lane_mid", "lane_bottom"]):
        img = Image.new('RGBA', (1080, 20), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        col = [(255,100,100), (100,255,100), (100,100,255)][i]
        draw.rectangle([0,8,1080,12], fill=col + (100,))
        for x in range(0,1080,80):
            draw.rectangle([x,2, x+40,18], fill=col + (150,), outline=(0,0,0,100), width=1)
        img.save(os.path.join(UI_DIR, f"{name}.png"))
        print(f"Generated {name}")

    # Offline earnings popup bg
    img = Image.new('RGBA', (512, 320), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([4,4,508,316], fill=(30,30,50,230), outline=(200,180,100,255), width=4)
    draw.rectangle([12,12,500,308], outline=(255,255,255,30), width=2)
    # Coins flying
    for _ in range(20):
        x = random.randint(20,490)
        y = random.randint(20,300)
        s = random.randint(8,16)
        draw.ellipse([x,y,x+s,y+s], fill=(255,215,0,180), outline=(0,0,0,100), width=1)
    img.save(os.path.join(UI_DIR, "offline_popup.png"))
    print("Generated offline_popup")

    # Floating text bg (for resource)
    img = Image.new('RGBA', (128, 48), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([4,4,124,44], fill=(0,0,0,150), outline=(255,255,255,100), width=2)
    img.save(os.path.join(UI_DIR, "floating_bg.png"))

    # Wave icon
    img = Image.new('RGBA', (64,64), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(12,48), (32,12), (52,48)], fill=(200,50,50), outline=(0,0,0,255), width=2)
    draw.rectangle([28,48,36,56], fill=(139,90,43), outline=(0,0,0,255), width=1)
    # Skulls
    draw.ellipse([20,20,44,44], fill=(240,240,220), outline=(0,0,0,255), width=2)
    draw.ellipse([26,28,32,34], fill=(0,0,0,255))
    draw.ellipse([38,28,44,34], fill=(0,0,0,255))
    img.save(os.path.join(ICONS_DIR, "wave.png"))
    print("Generated wave icon")

    # Build/Upgrade icons
    for name, col in [("upgrade", (100,200,100)), ("build", (200,180,100)), ("battle", (200,80,80))]:
        img = Image.new('RGBA', (64,64), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        draw.ellipse([4,4,60,60], fill=col, outline=(0,0,0,255), width=3)
        if name == "upgrade":
            draw.polygon([(32,12), (52,48), (12,48)], fill=(255,255,255), outline=(0,0,0,255), width=2)
        elif name == "build":
            draw.rectangle([16,28,48,48], fill=(139,90,43), outline=(0,0,0,255), width=2)
            draw.polygon([(12,28), (32,12), (52,28)], fill=(200,50,50), outline=(0,0,0,255), width=2)
        else:
            draw.polygon([(16,16), (48,32), (16,48)], fill=(255,255,255), outline=(0,0,0,255), width=2)
        img.save(os.path.join(ICONS_DIR, f"{name}.png"))
        img.save(os.path.join(UI_DIR, f"{name}.png"))
        print(f"Generated {name}")

if __name__ == "__main__":
    print("=== Idle Assets Generation ===")
    generate_idle_icons()
    print("=== Idle assets done ===")
