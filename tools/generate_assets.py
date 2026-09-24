#!/usr/bin/env python3
"""
Fantasy RTS - Procedural Asset Generator
Generates all game sprites, UI, and icons using PIL
Theme: Fantasy Mythic (AoE style)
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math
import random

# Ensure directories exist
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
SPRITES_UNITS = os.path.join(ASSETS_DIR, "sprites/units")
SPRITES_BUILDINGS = os.path.join(ASSETS_DIR, "sprites/buildings")
SPRITES_TILES = os.path.join(ASSETS_DIR, "sprites/tiles")
UI_DIR = os.path.join(ASSETS_DIR, "ui")
ICONS_DIR = os.path.join(ASSETS_DIR, "icons")

for d in [SPRITES_UNITS, SPRITES_BUILDINGS, SPRITES_TILES, UI_DIR, ICONS_DIR, os.path.join(ASSETS_DIR, "sprites")]:
    os.makedirs(d, exist_ok=True)

random.seed(42)

def create_gradient_background(size, color_top, color_bottom):
    img = Image.new('RGBA', size, (0,0,0,0))
    draw = ImageDraw.Draw(img)
    for y in range(size[1]):
        ratio = y / size[1]
        r = int(color_top[0] * (1-ratio) + color_bottom[0] * ratio)
        g = int(color_top[1] * (1-ratio) + color_bottom[1] * ratio)
        b = int(color_top[2] * (1-ratio) + color_bottom[2] * ratio)
        draw.line([(0,y), (size[0], y)], fill=(r,g,b,255))
    return img

def draw_pixel_border(img, border_color=(0,0,0,255), border_width=2):
    draw = ImageDraw.Draw(img)
    w,h = img.size
    for i in range(border_width):
        draw.rectangle([i,i,w-1-i,h-1-i], outline=border_color)
    return img

# 1. APP LOGO / ICON - 512x512 fantasy castle with dragon
def generate_app_icon():
    size = (512,512)
    img = Image.new('RGBA', size, (20, 15, 35, 255))
    draw = ImageDraw.Draw(img)
    
    # Gradient sky
    for y in range(size[1]):
        ratio = y / size[1]
        # night to purple
        r = int(20 + ratio*60)
        g = int(15 + ratio*30)
        b = int(35 + ratio*80)
        draw.line([(0,y), (size[0], y)], fill=(r,g,b,255))
    
    # Stars
    for _ in range(80):
        x = random.randint(0,512)
        y = random.randint(0,250)
        s = random.randint(1,3)
        draw.ellipse([x,y,x+s,y+s], fill=(255,255,200,200))
    
    # Ground
    draw.rectangle([0, 380, 512, 512], fill=(30, 80, 40, 255))
    draw.rectangle([0, 380, 512, 390], fill=(90, 60, 30, 255))
    
    # Castle - central keep
    # Main tower
    draw.rectangle([206, 180, 306, 380], fill=(180, 175, 160, 255), outline=(0,0,0,255), width=3)
    # Battlements
    for x in range(206, 306, 20):
        draw.rectangle([x, 170, x+12, 185], fill=(180,175,160,255), outline=(0,0,0,255), width=2)
    # Door
    draw.rectangle([236, 330, 276, 380], fill=(60, 30, 10, 255), outline=(0,0,0,255), width=2)
    draw.rectangle([236, 330, 276, 345], fill=(120, 90, 60, 255))
    # Windows
    draw.rectangle([226, 220, 246, 250], fill=(255, 220, 100, 255), outline=(0,0,0,255), width=2)
    draw.rectangle([266, 220, 286, 250], fill=(255, 220, 100, 255), outline=(0,0,0,255), width=2)
    draw.rectangle([236, 270, 276, 300], fill=(255, 220, 100, 255), outline=(0,0,0,255), width=2)
    
    # Side towers
    draw.rectangle([150, 220, 200, 380], fill=(160, 155, 140, 255), outline=(0,0,0,255), width=3)
    draw.rectangle([312, 220, 362, 380], fill=(160, 155, 140, 255), outline=(0,0,0,255), width=3)
    # Side tower tops
    draw.polygon([(140, 220), (175, 180), (210, 220)], fill=(120, 30, 30, 255), outline=(0,0,0,255), width=3)
    draw.polygon([(302, 220), (337, 180), (372, 220)], fill=(120, 30, 30, 255), outline=(0,0,0,255), width=3)
    
    # Flags
    draw.rectangle([175, 140, 178, 180], fill=(80,80,80,255))
    draw.polygon([(178,140), (178,160), (200,150)], fill=(200,50,50,255), outline=(0,0,0,255), width=2)
    draw.rectangle([337, 140, 340, 180], fill=(80,80,80,255))
    draw.polygon([(340,140), (340,160), (362,150)], fill=(50,50,200,255), outline=(0,0,0,255), width=2)
    
    # Dragon silhouette flying
    # Simple dragon shape
    dragon_color = (180, 50, 30, 255)
    # Body
    draw.ellipse([80, 90, 160, 130], fill=dragon_color, outline=(0,0,0,255), width=2)
    # Wings
    draw.polygon([(90,100), (40,70), (50,110), (85,115)], fill=(140,30,20,255), outline=(0,0,0,255), width=2)
    draw.polygon([(150,100), (200,70), (190,110), (155,115)], fill=(140,30,20,255), outline=(0,0,0,255), width=2)
    # Head
    draw.ellipse([160, 95, 185, 120], fill=dragon_color, outline=(0,0,0,255), width=2)
    # Tail
    draw.polygon([(80,110), (30,130), (35,120), (85,105)], fill=dragon_color, outline=(0,0,0,255), width=2)
    # Fire breath
    draw.polygon([(185,105), (230,100), (225,115), (185,110)], fill=(255,150,20,255), outline=(255,200,50,255), width=2)
    draw.polygon([(230,100), (250,98), (245,112), (225,115)], fill=(255,220,100,255))
    
    # Glow effect around castle
    for i in range(3):
        draw.rectangle([206-i, 180-i, 306+i, 380+i], outline=(255,220,100, 60//(i+1)), width=1)
    
    img.save(os.path.join(BASE_DIR, "icon.png"), "PNG")
    img.save(os.path.join(ASSETS_DIR, "icons/app_icon_512.png"), "PNG")
    # 192 for android adaptive
    img.resize((192,192), Image.LANCZOS).save(os.path.join(ASSETS_DIR, "icons/app_icon_192.png"), "PNG")
    print("Generated app icon")
    return img

# 2. RESOURCE ICONS - 64x64
def generate_resource_icons():
    resources = {
        "food": {"color": (220, 180, 80), "symbol": "W", "bg": (100, 70, 20)},
        "wood": {"color": (139, 90, 43), "symbol": "W", "bg": (60, 40, 15)},
        "gold": {"color": (255, 215, 0), "symbol": "G", "bg": (120, 90, 0)},
        "mana": {"color": (100, 150, 255), "symbol": "M", "bg": (30, 20, 80)},
        "stone": {"color": (150, 150, 160), "symbol": "S", "bg": (70, 70, 75)},
    }
    
    for name, data in resources.items():
        img = Image.new('RGBA', (64,64), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        # Circle bg
        draw.ellipse([2,2,62,62], fill=data["bg"], outline=(0,0,0,255), width=3)
        draw.ellipse([6,6,58,58], fill=data["color"], outline=(0,0,0,255), width=2)
        # Inner highlight
        draw.ellipse([12,12,28,28], fill=(255,255,255,100))
        
        # Symbol specific drawing
        if name == "food":
            # Wheat
            draw.ellipse([22,18,42,42], fill=(240,200,100), outline=(0,0,0,255), width=2)
            for i in range(3):
                y = 22 + i*8
                draw.line([(32,y), (38, y-4)], fill=(0,0,0,255), width=2)
                draw.line([(32,y), (26, y-4)], fill=(0,0,0,255), width=2)
        elif name == "wood":
            draw.rectangle([18,18,46,46], fill=(101,67,33), outline=(0,0,0,255), width=2)
            for x in [24,32,40]:
                draw.line([(x,18),(x,46)], fill=(0,0,0,80), width=1)
        elif name == "gold":
            draw.ellipse([20,20,44,44], fill=(255,235,100), outline=(0,0,0,255), width=2)
            draw.ellipse([26,26,36,36], fill=(255,255,255,150))
        elif name == "mana":
            draw.polygon([(32,12),(46,32),(32,52),(18,32)], fill=(150,180,255), outline=(0,0,0,255), width=2)
            draw.ellipse([26,26,38,38], fill=(255,255,255,200))
        elif name == "stone":
            draw.rectangle([20,20,44,44], fill=(180,180,190), outline=(0,0,0,255), width=2)
            draw.rectangle([24,24,32,32], fill=(120,120,130))
            draw.rectangle([34,28,42,36], fill=(120,120,130))
        
        img.save(os.path.join(ICONS_DIR, f"{name}.png"))
        img.save(os.path.join(UI_DIR, f"icon_{name}.png"))
        print(f"Generated resource icon: {name}")

# 3. TILES - 64x64
def generate_tiles():
    tiles = {
        "grass": {"base": (60, 150, 60), "detail": (40, 120, 40)},
        "dirt": {"base": (139, 90, 43), "detail": (110, 70, 30)},
        "water": {"base": (40, 100, 180), "detail": (60, 140, 220)},
        "forest": {"base": (30, 80, 30), "detail": (50, 110, 50)},
        "stone": {"base": (120, 120, 130), "detail": (90, 90, 100)},
        "sand": {"base": (210, 180, 120), "detail": (190, 160, 100)},
        "mana_crystal": {"base": (80, 60, 140), "detail": (120, 100, 200)},
        "gold_vein": {"base": (180, 150, 30), "detail": (220, 200, 80)},
    }
    
    for name, colors in tiles.items():
        img = Image.new('RGBA', (64,64), colors["base"])
        draw = ImageDraw.Draw(img)
        # Add noise/detail
        for _ in range(30):
            x = random.randint(0,63)
            y = random.randint(0,63)
            s = random.randint(1,4)
            draw.ellipse([x,y,x+s,y+s], fill=colors["detail"])
        # Border
        draw.rectangle([0,0,63,63], outline=(0,0,0,60), width=1)
        
        # Specific details
        if name == "forest":
            draw.ellipse([16,8,48,40], fill=(20,60,20), outline=(0,0,0,255), width=1)
            draw.rectangle([28,40,36,56], fill=(80,50,20), outline=(0,0,0,255), width=1)
        elif name == "water":
            for y in [16,32,48]:
                draw.line([(8,y),(56,y)], fill=(255,255,255,60), width=1)
        elif name == "mana_crystal":
            draw.polygon([(32,10),(48,32),(32,54),(16,32)], fill=(150,120,255), outline=(0,0,0,255), width=1)
        elif name == "gold_vein":
            draw.ellipse([18,18,46,46], fill=(255,215,0), outline=(0,0,0,255), width=1)
        
        img.save(os.path.join(SPRITES_TILES, f"{name}.png"))
        print(f"Generated tile: {name}")
    
    # Also generate a tileset image 512x128 (8 tiles)
    tileset = Image.new('RGBA', (512, 64), (0,0,0,0))
    for i, name in enumerate(tiles.keys()):
        tile_img = Image.open(os.path.join(SPRITES_TILES, f"{name}.png"))
        tileset.paste(tile_img, (i*64, 0))
    tileset.save(os.path.join(SPRITES_TILES, "tileset.png"))

# 4. BUILDINGS - 128x128
def generate_buildings():
    buildings = {
        "town_hall": {"w": 120, "h": 100, "colors": [(180,175,160), (120,30,30)], "type": "castle"},
        "house": {"w": 80, "h": 70, "colors": [(160,120,80), (120,30,30)], "type": "house"},
        "barracks": {"w": 100, "h": 80, "colors": [(140,130,120), (100,20,20)], "type": "barracks"},
        "archery": {"w": 90, "h": 75, "colors": [(150,120,80), (80,60,40)], "type": "archery"},
        "stable": {"w": 110, "h": 85, "colors": [(130,100,70), (90,60,30)], "type": "stable"},
        "mage_tower": {"w": 70, "h": 120, "colors": [(100,80,150), (60,40,120)], "type": "tower"},
        "wall": {"w": 64, "h": 48, "colors": [(150,150,150), (100,100,100)], "type": "wall"},
        "market": {"w": 100, "h": 80, "colors": [(180,150,100), (200,50,50)], "type": "market"},
    }
    
    for name, spec in buildings.items():
        img = Image.new('RGBA', (128,128), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        cx, cy = 64, 64
        w, h = spec["w"], spec["h"]
        base_color, roof_color = spec["colors"]
        
        # Shadow
        draw.ellipse([cx-w//2+10, cy+h//2-10, cx+w//2+10, cy+h//2+10], fill=(0,0,0,80))
        
        if spec["type"] == "castle":
            # Main building
            draw.rectangle([cx-w//2, cy-h//2+20, cx+w//2, cy+h//2], fill=base_color, outline=(0,0,0,255), width=3)
            # Towers
            draw.rectangle([cx-w//2-10, cy-h//2, cx-w//2+10, cy+h//2-20], fill=base_color, outline=(0,0,0,255), width=2)
            draw.rectangle([cx+w//2-10, cy-h//2, cx+w//2+10, cy+h//2-20], fill=base_color, outline=(0,0,0,255), width=2)
            # Roof
            draw.polygon([(cx-w//2-15, cy-h//2), (cx-w//2, cy-h//2-20), (cx-w//2+15, cy-h//2)], fill=roof_color, outline=(0,0,0,255), width=2)
            draw.polygon([(cx+w//2-15, cy-h//2), (cx+w//2, cy-h//2-20), (cx+w//2+15, cy-h//2)], fill=roof_color, outline=(0,0,0,255), width=2)
            draw.rectangle([cx-w//2, cy-h//2-10, cx+w//2, cy-h//2+20], fill=roof_color, outline=(0,0,0,255), width=2)
            # Door
            draw.rectangle([cx-15, cy+h//2-30, cx+15, cy+h//2], fill=(60,30,10), outline=(0,0,0,255), width=2)
            # Flag
            draw.rectangle([cx, cy-h//2-35, cx+3, cy-h//2-10], fill=(80,80,80))
            draw.polygon([(cx+3, cy-h//2-35), (cx+3, cy-h//2-25), (cx+20, cy-h//2-30)], fill=(50,50,200), outline=(0,0,0,255), width=1)
        elif spec["type"] == "tower":
            draw.rectangle([cx-w//2, cy-h//2+30, cx+w//2, cy+h//2], fill=base_color, outline=(0,0,0,255), width=3)
            draw.polygon([(cx-w//2-10, cy-h//2+30), (cx, cy-h//2), (cx+w//2+10, cy-h//2+30)], fill=roof_color, outline=(0,0,0,255), width=3)
            # Crystal on top
            draw.polygon([(cx, cy-h//2-15), (cx+10, cy-h//2), (cx, cy-h//2+10), (cx-10, cy-h//2)], fill=(100,200,255), outline=(0,0,0,255), width=2)
            # Windows
            for y in [cy-10, cy+10, cy+30]:
                draw.rectangle([cx-8, y, cx+8, y+12], fill=(150,200,255), outline=(0,0,0,255), width=1)
        elif spec["type"] == "wall":
            draw.rectangle([cx-w//2, cy-h//2, cx+w//2, cy+h//2], fill=base_color, outline=(0,0,0,255), width=2)
            for x in range(cx-w//2, cx+w//2, 16):
                draw.rectangle([x, cy-h//2-8, x+8, cy-h//2], fill=base_color, outline=(0,0,0,255), width=1)
        else:
            # Generic building
            draw.rectangle([cx-w//2, cy-h//2+20, cx+w//2, cy+h//2], fill=base_color, outline=(0,0,0,255), width=3)
            draw.polygon([(cx-w//2, cy-h//2+20), (cx, cy-h//2), (cx+w//2, cy-h//2+20)], fill=roof_color, outline=(0,0,0,255), width=3)
            # Door
            draw.rectangle([cx-12, cy+h//2-25, cx+12, cy+h//2], fill=(60,30,10), outline=(0,0,0,255), width=2)
            if name == "barracks":
                # Swords icon
                draw.line([(cx-20, cy), (cx+20, cy+10)], fill=(0,0,0,255), width=3)
            elif name == "archery":
                draw.polygon([(cx, cy-5), (cx+15, cy), (cx, cy+5)], fill=(139,90,43), outline=(0,0,0,255), width=1)
        
        img.save(os.path.join(SPRITES_BUILDINGS, f"{name}.png"))
        print(f"Generated building: {name}")
        
        # Generate age variants (recolor for higher ages)
        for age in [2,3]:
            age_img = img.copy()
            # Tint for age progression - more gold/blue
            tint = (20*age, 10*age, 30*age)
            # Simple overlay
            overlay = Image.new('RGBA', (128,128), tint + (30,))
            age_img = Image.alpha_composite(age_img, overlay)
            age_img.save(os.path.join(SPRITES_BUILDINGS, f"{name}_age{age}.png"))

# 5. UNITS - 64x64 pixel art style
def generate_units():
    units = {
        "villager": {"color": (160, 120, 80), "weapon": None, "size": 32},
        "swordsman": {"color": (180, 180, 200), "weapon": "sword", "size": 36},
        "archer": {"color": (100, 150, 80), "weapon": "bow", "size": 34},
        "knight": {"color": (200, 200, 220), "weapon": "lance", "size": 40},
        "mage": {"color": (120, 80, 180), "weapon": "staff", "size": 36},
        "golem": {"color": (130, 130, 140), "weapon": None, "size": 48},
        "dragon": {"color": (180, 50, 30), "weapon": None, "size": 56},
        "healer": {"color": (220, 220, 180), "weapon": "staff", "size": 32},
    }
    
    for name, spec in units.items():
        img = Image.new('RGBA', (64,64), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        cx, cy = 32, 32
        s = spec["size"] // 2
        color = spec["color"]
        dark = tuple(max(0, c-40) for c in color)
        light = tuple(min(255, c+40) for c in color)
        
        # Shadow
        draw.ellipse([cx-s+4, cy+s-4, cx+s+4, cy+s+6], fill=(0,0,0,80))
        
        if name == "dragon":
            # Dragon - top down
            draw.ellipse([cx-s, cy-s//2, cx+s, cy+s//2], fill=color, outline=(0,0,0,255), width=2)
            # Wings
            draw.ellipse([cx-s-8, cy-s//2, cx-s+8, cy+s//2], fill=dark, outline=(0,0,0,255), width=2)
            draw.ellipse([cx+s-8, cy-s//2, cx+s+8, cy+s//2], fill=dark, outline=(0,0,0,255), width=2)
            # Head
            draw.ellipse([cx+s-4, cy-8, cx+s+12, cy+8], fill=color, outline=(0,0,0,255), width=2)
            # Tail
            draw.polygon([(cx-s, cy), (cx-s-12, cy-6), (cx-s-12, cy+6)], fill=color, outline=(0,0,0,255), width=2)
        elif name == "golem":
            # Big rocky creature
            draw.rectangle([cx-s, cy-s, cx+s, cy+s], fill=color, outline=(0,0,0,255), width=3)
            draw.rectangle([cx-s+4, cy-s+4, cx+s-4, cy-s+12], fill=light, outline=(0,0,0,255), width=1)
            draw.rectangle([cx-8, cy-4, cx+8, cy+8], fill=(100,200,255), outline=(0,0,0,255), width=1) # eye
        else:
            # Humanoid - chibi style
            # Body
            draw.ellipse([cx-s//2, cy-s//2, cx+s//2, cy+s//2], fill=color, outline=(0,0,0,255), width=2)
            # Head
            head_color = (255, 220, 180) if name != "golem" else color
            draw.ellipse([cx-s//3, cy-s, cx+s//3, cy-s//3], fill=head_color, outline=(0,0,0,255), width=2)
            # Helmet/hat
            if name in ["swordsman", "knight"]:
                draw.rectangle([cx-s//3, cy-s-4, cx+s//3, cy-s//2], fill=(150,150,160), outline=(0,0,0,255), width=2)
            elif name == "mage":
                draw.polygon([(cx-s//3, cy-s//3), (cx, cy-s-12), (cx+s//3, cy-s//3)], fill=(80,40,120), outline=(0,0,0,255), width=2)
            elif name == "healer":
                draw.ellipse([cx-s//3, cy-s-6, cx+s//3, cy-s//2+4], fill=(255,255,255), outline=(0,0,0,255), width=1)
            
            # Weapon
            if spec["weapon"] == "sword":
                draw.rectangle([cx+s//2, cy-2, cx+s//2+12, cy+2], fill=(200,200,220), outline=(0,0,0,255), width=1)
            elif spec["weapon"] == "bow":
                draw.arc([cx+s//2-4, cy-8, cx+s//2+8, cy+8], 270, 90, fill=(139,90,43), width=2)
                draw.line([(cx+s//2, cy-6), (cx+s//2, cy+6)], fill=(0,0,0,255), width=1)
            elif spec["weapon"] == "lance":
                draw.rectangle([cx+s//2, cy-2, cx+s//2+18, cy+2], fill=(180,180,180), outline=(0,0,0,255), width=1)
                draw.polygon([(cx+s//2+18, cy-4), (cx+s//2+24, cy), (cx+s//2+18, cy+4)], fill=(200,200,200), outline=(0,0,0,255), width=1)
            elif spec["weapon"] == "staff":
                draw.rectangle([cx+s//2, cy-10, cx+s//2+3, cy+10], fill=(139,90,43), outline=(0,0,0,255), width=1)
                if name == "mage":
                    draw.ellipse([cx+s//2-2, cy-14, cx+s//2+8, cy-4], fill=(100,200,255), outline=(0,0,0,255), width=1)
                else:
                    draw.ellipse([cx+s//2-2, cy-14, cx+s//2+8, cy-4], fill=(255,255,150), outline=(0,0,0,255), width=1)
        
        img.save(os.path.join(SPRITES_UNITS, f"{name}.png"))
        print(f"Generated unit: {name}")
        
        # Generate 4 directional variants by flipping/hue
        for dir_idx, dir_name in enumerate(["north", "east", "south", "west"]):
            # For MVP, just copy with slight rotation marker
            variant = img.copy()
            d = ImageDraw.Draw(variant)
            # Add small direction arrow
            if dir_name == "north":
                d.polygon([(32,4), (28,10), (36,10)], fill=(255,0,0,150))
            elif dir_name == "east":
                d.polygon([(60,32), (54,28), (54,36)], fill=(255,0,0,150))
            elif dir_name == "south":
                d.polygon([(32,60), (28,54), (36,54)], fill=(255,0,0,150))
            else:
                d.polygon([(4,32), (10,28), (10,36)], fill=(255,0,0,150))
            variant.save(os.path.join(SPRITES_UNITS, f"{name}_{dir_name}.png"))

# 6. UI ELEMENTS
def generate_ui():
    # Button 256x64
    for state in ["normal", "hover", "pressed", "disabled"]:
        img = Image.new('RGBA', (256,64), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        if state == "normal":
            bg = (80, 60, 40)
            border = (40,30,20)
        elif state == "hover":
            bg = (100, 80, 50)
            border = (60,40,20)
        elif state == "pressed":
            bg = (60, 40, 25)
            border = (30,20,10)
        else:
            bg = (60,60,60)
            border = (40,40,40)
        
        draw.rectangle([2,2,254,62], fill=bg, outline=border, width=3)
        # Inner highlight
        draw.rectangle([6,6,250,18], fill=(255,255,255,40))
        # Fantasy border corners
        for x,y in [(2,2),(254,2),(2,62),(254,62)]:
            draw.rectangle([x-2,y-2,x+2,y+2], fill=(200,180,100), outline=(0,0,0,255), width=1)
        
        img.save(os.path.join(UI_DIR, f"button_{state}.png"))
    
    # Panel 512x512
    img = Image.new('RGBA', (512,512), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([4,4,508,508], fill=(50,40,30,220), outline=(100,80,50,255), width=4)
    draw.rectangle([12,12,500,500], outline=(200,180,100,100), width=2)
    # Corners
    for x,y in [(4,4),(508,4),(4,508),(508,508)]:
        draw.rectangle([x-4,y-4,x+4,y+4], fill=(200,180,100), outline=(0,0,0,255), width=1)
    img.save(os.path.join(UI_DIR, "panel_large.png"))
    
    # Small panel 256x256
    img.resize((256,256), Image.LANCZOS).save(os.path.join(UI_DIR, "panel_small.png"))
    
    # Health bar 128x16
    for color_name, color in [("health", (0,200,0)), ("mana", (50,100,255)), ("xp", (200,180,0))]:
        img = Image.new('RGBA', (128,16), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        draw.rectangle([0,0,127,15], fill=(20,20,20,255), outline=(0,0,0,255), width=2)
        draw.rectangle([2,2,100,13], fill=color, outline=(0,0,0,255), width=1)
        img.save(os.path.join(UI_DIR, f"bar_{color_name}.png"))
    
    # Selection circle 64x32 (isometric)
    img = Image.new('RGBA', (64,32), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([2,2,62,30], outline=(0,255,0,200), width=2)
    draw.ellipse([4,4,60,28], outline=(255,255,255,100), width=1)
    img.save(os.path.join(UI_DIR, "selection_circle.png"))
    
    # Minimap frame 256x256
    img = Image.new('RGBA', (256,256), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0,0,255,255], fill=(20,15,10,200), outline=(150,120,80,255), width=4)
    img.save(os.path.join(UI_DIR, "minimap_frame.png"))
    
    print("Generated UI elements")

# 7. Generate effects and icons for tech
def generate_tech_icons():
    techs = ["age_up", "sword_upgrade", "armor_upgrade", "magic_upgrade", "gather_upgrade"]
    for tech in techs:
        img = Image.new('RGBA', (64,64), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        draw.ellipse([2,2,62,62], fill=(60,50,30), outline=(200,180,100,255), width=3)
        if "age" in tech:
            draw.polygon([(32,12),(52,52),(12,52)], fill=(200,180,100), outline=(0,0,0,255), width=2)
        elif "sword" in tech:
            draw.rectangle([20,20,44,28], fill=(200,200,220), outline=(0,0,0,255), width=1)
        elif "armor" in tech:
            draw.rectangle([18,18,46,46], fill=(150,150,160), outline=(0,0,0,255), width=2)
        elif "magic" in tech:
            draw.ellipse([22,22,42,42], fill=(100,150,255), outline=(0,0,0,255), width=2)
        else:
            draw.rectangle([16,28,48,36], fill=(139,90,43), outline=(0,0,0,255), width=2)
        img.save(os.path.join(ICONS_DIR, f"{tech}.png"))
        print(f"Generated tech icon: {tech}")

if __name__ == "__main__":
    print("=== Fantasy RTS Asset Generation ===")
    generate_app_icon()
    generate_resource_icons()
    generate_tiles()
    generate_buildings()
    generate_units()
    generate_ui()
    generate_tech_icons()
    print("=== All assets generated successfully ===")
