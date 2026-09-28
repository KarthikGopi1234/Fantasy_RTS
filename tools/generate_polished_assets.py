#!/usr/bin/env python3
"""
Polished Assets Generator v2.1.0
Much better artwork than piss poor - proper shading, details, fantasy style
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random
import math

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
ICONS_DIR = os.path.join(ASSETS_DIR, "icons")
UI_DIR = os.path.join(ASSETS_DIR, "ui")
BUILDINGS_DIR = os.path.join(ASSETS_DIR, "sprites/buildings")
UNITS_DIR = os.path.join(ASSETS_DIR, "sprites/units")
TILES_DIR = os.path.join(ASSETS_DIR, "sprites/tiles")
BG_DIR = os.path.join(ASSETS_DIR, "backgrounds")

for d in [ICONS_DIR, UI_DIR, BUILDINGS_DIR, UNITS_DIR, TILES_DIR, BG_DIR, os.path.join(ASSETS_DIR, "splash")]:
    os.makedirs(d, exist_ok=True)

random.seed(12345)

def draw_rounded_rect(draw, xy, radius, fill, outline=None, width=1):
    x0, y0, x1, y1 = xy
    # Simple rounded rect via polygon + circles
    draw.rectangle([x0+radius, y0, x1-radius, y1], fill=fill, outline=outline, width=width)
    draw.rectangle([x0, y0+radius, x1, y1-radius], fill=fill, outline=outline, width=width)
    draw.ellipse([x0, y0, x0+radius*2, y0+radius*2], fill=fill, outline=outline, width=width)
    draw.ellipse([x1-radius*2, y0, x1, y0+radius*2], fill=fill, outline=outline, width=width)
    draw.ellipse([x0, y1-radius*2, x0+radius*2, y1], fill=fill, outline=outline, width=width)
    draw.ellipse([x1-radius*2, y1-radius*2, x1, y1], fill=fill, outline=outline, width=width)

def add_shadow(img, offset=4, alpha=60):
    shadow = Image.new('RGBA', img.size, (0,0,0,0))
    draw = ImageDraw.Draw(shadow)
    # Simple shadow is just darkened bottom
    w,h = img.size
    draw.ellipse([w*0.2, h*0.75, w*0.8, h*0.95], fill=(0,0,0,alpha))
    return Image.alpha_composite(img, shadow)

# 1. SPLASH SCREEN - 720x1280 portrait fantasy
def generate_splash():
    w,h = 720,1280
    img = Image.new('RGBA', (w,h), (20,30,60,255))
    draw = ImageDraw.Draw(img)
    
    # Gradient sky from deep night to dawn
    for y in range(h):
        ratio = y / h
        if ratio < 0.5:
            # Night to twilight
            r = int(15 + ratio*80)
            g = int(20 + ratio*60)
            b = int(50 + ratio*100)
        else:
            # Twilight to ground
            r2 = (ratio-0.5)*2
            r = int(95 + r2*40)
            g = int(80 + r2*80)
            b = int(150 - r2*50)
        draw.line([(0,y),(w,y)], fill=(r,g,b,255))
    
    # Stars
    for _ in range(150):
        x = random.randint(0,w)
        y = random.randint(0,int(h*0.6))
        s = random.randint(1,3)
        alpha = random.randint(100,255)
        draw.ellipse([x,y,x+s,y+s], fill=(255,255,200,alpha))
    
    # Moon
    draw.ellipse([w-150, 80, w-50, 180], fill=(240,240,200,255), outline=(0,0,0,100), width=2)
    draw.ellipse([w-140, 90, w-60, 170], fill=(220,220,180,50))
    # Craters
    draw.ellipse([w-120, 100, w-100, 120], fill=(200,200,160,100))
    draw.ellipse([w-90, 120, w-70, 140], fill=(200,200,160,80))
    
    # Mountains silhouette
    mountain_points = [(0, int(h*0.55))]
    for x in range(0, w+50, 80):
        y = int(h*0.55) + random.randint(-60,40)
        mountain_points.append((x,y))
    mountain_points.append((w, int(h*0.55)))
    mountain_points.append((w, int(h*0.65)))
    mountain_points.append((0, int(h*0.65)))
    draw.polygon(mountain_points, fill=(30,40,70,255), outline=(0,0,0,80), width=1)
    
    # Ground with texture
    draw.rectangle([0, int(h*0.65), w, h], fill=(25,60,35,255))
    # Grass texture
    for _ in range(300):
        x = random.randint(0,w)
        y = random.randint(int(h*0.65), h)
        s = random.randint(2,6)
        col = (random.randint(30,80), random.randint(80,140), random.randint(30,70), 150)
        draw.ellipse([x,y,x+s,y+s], fill=col)
    
    # Central castle - much more detailed
    cx, cy = w//2, int(h*0.55)
    # Shadow
    draw.ellipse([cx-140, cy+80, cx+140, cy+110], fill=(0,0,0,80))
    
    # Main keep - stone with texture
    keep_w, keep_h = 200, 180
    # Base stone
    draw.rectangle([cx-keep_w//2, cy-keep_h//2, cx+keep_w//2, cy+keep_h//2], fill=(170,165,150,255), outline=(0,0,0,255), width=4)
    # Stone texture lines
    for y in range(cy-keep_h//2+10, cy+keep_h//2, 20):
        draw.line([(cx-keep_w//2, y), (cx+keep_w//2, y)], fill=(0,0,0,30), width=1)
    for x in range(cx-keep_w//2+10, cx+keep_w//2, 25):
        draw.line([(x, cy-keep_h//2), (x, cy+keep_h//2)], fill=(0,0,0,20), width=1)
    # Battlements
    for x in range(cx-keep_w//2, cx+keep_w//2, 22):
        draw.rectangle([x, cy-keep_h//2-18, x+14, cy-keep_h//2], fill=(170,165,150,255), outline=(0,0,0,255), width=2)
    # Windows with glow
    for wx, wy in [(cx-40, cy-40), (cx+20, cy-40), (cx-15, cy+10)]:
        # Glow
        draw.ellipse([wx-8, wy-8, wx+28, wy+32], fill=(255,200,50,80))
        draw.rectangle([wx, wy, wx+20, wy+24], fill=(255,220,100,255), outline=(0,0,0,255), width=2)
        draw.rectangle([wx+8, wy, wx+12, wy+24], fill=(0,0,0,255), width=1) # cross
        draw.rectangle([wx, wy+10, wx+20, wy+14], fill=(0,0,0,255), width=1)
    # Door with arch
    draw.rectangle([cx-25, cy+20, cx+25, cy+keep_h//2], fill=(60,30,10,255), outline=(0,0,0,255), width=3)
    draw.rectangle([cx-25, cy+20, cx+25, cy+35], fill=(90,60,30,255), outline=(0,0,0,255), width=2)
    # Arch top
    draw.ellipse([cx-25, cy+5, cx+25, cy+35], fill=(90,60,30,255), outline=(0,0,0,255), width=3)
    draw.ellipse([cx-25, cy+5, cx+25, cy+35], fill=(60,30,10,255))
    draw.rectangle([cx-20, cy+20, cx+20, cy+keep_h//2], fill=(40,20,5,255))
    
    # Side towers - more detailed
    for side in [-1, 1]:
        tx = cx + side*130
        tw, th = 70, 140
        # Tower
        draw.rectangle([tx-tw//2, cy-th//2+20, tx+tw//2, cy+keep_h//2-20], fill=(150,145,130,255), outline=(0,0,0,255), width=3)
        # Stone lines
        for y in range(cy-th//2+30, cy+keep_h//2-20, 18):
            draw.line([(tx-tw//2, y), (tx+tw//2, y)], fill=(0,0,0,25), width=1)
        # Roof cone
        draw.polygon([(tx-tw//2-10, cy-th//2+20), (tx, cy-th//2-30), (tx+tw//2+10, cy-th//2+20)], fill=(120,30,30,255), outline=(0,0,0,255), width=3)
        # Roof highlight
        draw.polygon([(tx, cy-th//2-30), (tx+tw//2+10, cy-th//2+20), (tx+10, cy-th//2+15)], fill=(160,50,50,255))
        # Flag pole
        draw.rectangle([tx-2, cy-th//2-60, tx+2, cy-th//2-30], fill=(80,80,80,255))
        # Flag
        flag_col = (200,50,50,255) if side==-1 else (50,80,200,255)
        draw.polygon([(tx+2, cy-th//2-60), (tx+2, cy-th//2-40), (tx+30, cy-th//2-50)], fill=flag_col, outline=(0,0,0,255), width=2)
        # Tower window
        draw.ellipse([tx-8, cy-10, tx+8, cy+10], fill=(255,220,100,255), outline=(0,0,0,255), width=2)
    
    # Dragon - much more detailed, flying
    dx, dy = 120, 180
    # Body gradient
    draw.ellipse([dx-10, dy-15, dx+70, dy+25], fill=(180,40,20,255), outline=(0,0,0,255), width=3)
    # Scales
    for i in range(4):
        x = dx + i*15
        draw.ellipse([x, dy-5, x+12, dy+8], fill=(200,60,30,255), outline=(0,0,0,100), width=1)
    # Wings with membrane
    # Left wing
    draw.polygon([(dx+10, dy), (dx-40, dy-40), (dx-30, dy-10), (dx-10, dy+5)], fill=(140,20,10,255), outline=(0,0,0,255), width=2)
    # Wing bones
    draw.line([(dx+10, dy), (dx-40, dy-40)], fill=(0,0,0,255), width=2)
    draw.line([(dx, dy), (dx-30, dy-10)], fill=(0,0,0,255), width=2)
    # Right wing
    draw.polygon([(dx+40, dy), (dx+90, dy-35), (dx+80, dy-5), (dx+60, dy+8)], fill=(140,20,10,255), outline=(0,0,0,255), width=2)
    draw.line([(dx+40, dy), (dx+90, dy-35)], fill=(0,0,0,255), width=2)
    # Head with horns
    draw.ellipse([dx+60, dy-12, dx+95, dy+12], fill=(180,40,20,255), outline=(0,0,0,255), width=2)
    # Horns
    draw.polygon([(dx+70, dy-12), (dx+65, dy-28), (dx+75, dy-10)], fill=(240,230,180,255), outline=(0,0,0,255), width=2)
    # Eye
    draw.ellipse([dx+82, dy-4, dx+88, dy+2], fill=(255,220,50,255), outline=(0,0,0,255), width=1)
    draw.ellipse([dx+84, dy-2, dx+86, dy+0], fill=(0,0,0,255))
    # Teeth
    for tx in [dx+90, dx+86]:
        draw.polygon([(tx, dy+4), (tx+4, dy+8), (tx, dy+8)], fill=(255,255,255,255), outline=(0,0,0,255), width=1)
    # Tail with spines
    draw.polygon([(dx-10, dy), (dx-50, dy+15), (dx-45, dy+5), (dx-5, dy-5)], fill=(180,40,20,255), outline=(0,0,0,255), width=2)
    for i in range(3):
        sx = dx-20 - i*10
        draw.polygon([(sx, dy), (sx-5, dy-12), (sx+2, dy)], fill=(0,0,0,255))
    # Fire breath with gradient
    # Outer
    draw.polygon([(dx+95, dy-2), (dx+150, dy-8), (dx+145, dy+8), (dx+95, dy+6)], fill=(255,120,20,255), outline=(255,180,50,255), width=2)
    # Inner
    draw.polygon([(dx+110, dy-2), (dx+145, dy-4), (dx+140, dy+4), (dx+110, dy+2)], fill=(255,220,100,255))
    # Sparks
    for _ in range(8):
        sx = random.randint(dx+120, dx+160)
        sy = random.randint(dy-10, dy+10)
        s = random.randint(2,5)
        draw.ellipse([sx,sy,sx+s,sy+s], fill=(255,255,200,200))
    
    # Title with outline and shadow
    title = "AETHER EMPIRES"
    # Shadow
    draw.text((w//2+3, 280+3), title, fill=(0,0,0,180), anchor="mm", font_size=52)
    # Main
    draw.text((w//2, 280), title, fill=(255,220,100,255), stroke_width=3, stroke_fill=(0,0,0,255), anchor="mm", font_size=52)
    
    subtitle = "IDLE AUTO-BATTLER"
    draw.text((w//2+2, 330+2), subtitle, fill=(0,0,0,150), anchor="mm", font_size=28)
    draw.text((w//2, 330), subtitle, fill=(200,200,255,255), stroke_width=2, stroke_fill=(0,0,0,255), anchor="mm", font_size=28)
    
    # Tap to start with glow
    # Glow bg
    draw.rounded_rectangle([w//2-180, 1050, w//2+180, 1120], radius=20, fill=(255,220,100,30), outline=(255,220,100,100), width=2)
    draw.text((w//2, 1085), "TAP TO START", fill=(255,255,255,255), stroke_width=2, stroke_fill=(0,0,0,255), anchor="mm", font_size=32)
    
    # Version
    draw.text((w//2, 1180), "v2.1.0 - Portrait Idle", fill=(255,255,255,150), anchor="mm", font_size=18)
    
    # Save
    img.save(os.path.join(BASE_DIR, "assets/splash/splash_720x1280.png"))
    img.resize((1080,1920), Image.LANCZOS).save(os.path.join(BASE_DIR, "assets/splash/splash_1080x1920.png"))
    img.resize((512,512), Image.LANCZOS).save(os.path.join(BASE_DIR, "icon.png"))
    img.resize((512,512), Image.LANCZOS).save(os.path.join(ICONS_DIR, "app_icon_512.png"))
    img.resize((192,192), Image.LANCZOS).save(os.path.join(ICONS_DIR, "app_icon_192.png"))
    print("Generated polished splash and icon")

def generate_buildings_polished():
    buildings = {
        "town_hall": {"base": (175,165,145), "roof": (130,35,35), "w": 140, "h": 110, "detail": "castle"},
        "house": {"base": (180,150,110), "roof": (140,40,40), "w": 90, "h": 75, "detail": "house"},
        "barracks": {"base": (160,150,135), "roof": (100,25,25), "w": 120, "h": 90, "detail": "barracks"},
        "archery": {"base": (170,140,100), "roof": (90,70,40), "w": 110, "h": 85, "detail": "archery"},
        "stable": {"base": (150,130,90), "roof": (110,80,40), "w": 130, "h": 95, "detail": "stable"},
        "mage_tower": {"base": (110,90,160), "roof": (70,50,130), "w": 80, "h": 140, "detail": "tower"},
        "wall": {"base": (160,160,160), "roof": (120,120,120), "w": 100, "h": 50, "detail": "wall"},
        "market": {"base": (190,170,120), "roof": (200,60,60), "w": 120, "h": 90, "detail": "market"},
        "lumber_camp": {"base": (140,110,70), "roof": (100,70,40), "w": 100, "h": 80, "detail": "lumber"},
    }
    
    for name, spec in buildings.items():
        size = 192
        img = Image.new('RGBA', (size,size), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        cx, cy = size//2, size//2
        w,h = spec["w"], spec["h"]
        base_col = spec["base"]
        roof_col = spec["roof"]
        
        # Shadow
        draw.ellipse([cx-w//2+8, cy+h//2-8, cx+w//2+8, cy+h//2+8], fill=(0,0,0,70))
        
        if spec["detail"] == "castle":
            # Main
            draw.rectangle([cx-w//2, cy-h//2+25, cx+w//2, cy+h//2], fill=base_col, outline=(0,0,0,255), width=3)
            # Stone texture
            for y in range(cy-h//2+35, cy+h//2, 18):
                draw.line([(cx-w//2, y), (cx+w//2, y)], fill=(0,0,0,25), width=1)
            # Towers
            for side in [-1,1]:
                tx = cx + side*(w//2+15)
                draw.rectangle([tx-20, cy-h//2+10, tx+20, cy+h//2-10], fill=tuple(max(0,c-15) for c in base_col), outline=(0,0,0,255), width=2)
                # Battlements
                for bx in range(tx-20, tx+20, 10):
                    draw.rectangle([bx, cy-h//2, bx+6, cy-h//2+10], fill=tuple(max(0,c-15) for c in base_col), outline=(0,0,0,255), width=1)
                # Roof
                draw.polygon([(tx-25, cy-h//2+10), (tx, cy-h//2-15), (tx+25, cy-h//2+10)], fill=roof_col, outline=(0,0,0,255), width=2)
            # Main roof
            draw.rectangle([cx-w//2, cy-h//2+5, cx+w//2, cy-h//2+25], fill=roof_col, outline=(0,0,0,255), width=2)
            # Door arch
            draw.rectangle([cx-18, cy+h//2-35, cx+18, cy+h//2], fill=(60,30,10,255), outline=(0,0,0,255), width=2)
            draw.ellipse([cx-18, cy+h//2-45, cx+18, cy+h//2-25], fill=(80,50,20,255), outline=(0,0,0,255), width=2)
            # Windows with glow
            for wx, wy in [(cx-35, cy-15), (cx+20, cy-15)]:
                draw.ellipse([wx-4, wy-4, wx+20, wy+20], fill=(255,200,50,60))
                draw.rectangle([wx, wy, wx+16, wy+16], fill=(255,220,100,255), outline=(0,0,0,255), width=2)
                draw.line([(wx+7, wy), (wx+7, wy+16)], fill=(0,0,0,255), width=1)
                draw.line([(wx, wy+7), (wx+16, wy+7)], fill=(0,0,0,255), width=1)
        elif spec["detail"] == "tower":
            # Tall tower
            draw.rectangle([cx-w//2, cy-h//2+40, cx+w//2, cy+h//2], fill=base_col, outline=(0,0,0,255), width=3)
            # Stone lines
            for y in range(cy-h//2+50, cy+h//2, 16):
                draw.line([(cx-w//2, y), (cx+w//2, y)], fill=(0,0,0,25), width=1)
            # Roof
            draw.polygon([(cx-w//2-12, cy-h//2+40), (cx, cy-h//2), (cx+w//2+12, cy-h//2+40)], fill=roof_col, outline=(0,0,0,255), width=3)
            # Crystal
            draw.polygon([(cx, cy-h//2-20), (cx+12, cy-h//2-5), (cx, cy-h//2+8), (cx-12, cy-h//2-5)], fill=(100,200,255,255), outline=(0,0,0,255), width=2)
            # Glow
            draw.ellipse([cx-16, cy-h//2-12, cx+16, cy-h//2+12], fill=(100,200,255,60))
            # Windows
            for y in [cy-10, cy+15, cy+40]:
                draw.rectangle([cx-10, y, cx+10, y+14], fill=(150,200,255,255), outline=(0,0,0,255), width=1)
                draw.ellipse([cx-10, y, cx+10, y+14], fill=(200,220,255,100))
        elif spec["detail"] == "wall":
            draw.rectangle([cx-w//2, cy-h//2, cx+w//2, cy+h//2], fill=base_col, outline=(0,0,0,255), width=3)
            # Stone pattern
            for x in range(cx-w//2+5, cx+w//2, 20):
                for y in range(cy-h//2+5, cy+h//2, 15):
                    if random.random()>0.3:
                        draw.rectangle([x,y,x+16,y+10], fill=tuple(max(0,c-20) for c in base_col), outline=(0,0,0,50), width=1)
            # Battlements
            for x in range(cx-w//2, cx+w//2, 18):
                draw.rectangle([x, cy-h//2-12, x+10, cy-h//2], fill=base_col, outline=(0,0,0,255), width=2)
        else:
            # Generic with better detail
            draw.rectangle([cx-w//2, cy-h//2+22, cx+w//2, cy+h//2], fill=base_col, outline=(0,0,0,255), width=3)
            # Wood or stone texture
            if spec["detail"] in ["lumber", "archery"]:
                for x in range(cx-w//2+5, cx+w//2, 12):
                    draw.line([(x, cy-h//2+22), (x, cy+h//2)], fill=(0,0,0,30), width=1)
            # Roof
            draw.polygon([(cx-w//2-4, cy-h//2+22), (cx, cy-h//2), (cx+w//2+4, cy-h//2+22)], fill=roof_col, outline=(0,0,0,255), width=3)
            # Roof highlight
            draw.polygon([(cx, cy-h//2), (cx+w//2+4, cy-h//2+22), (cx+10, cy-h//2+18)], fill=tuple(min(255,c+30) for c in roof_col))
            # Door
            draw.rectangle([cx-14, cy+h//2-28, cx+14, cy+h//2], fill=(70,40,15,255), outline=(0,0,0,255), width=2)
            # Detail based on type
            if spec["detail"] == "barracks":
                # Crossed swords icon above door
                draw.line([(cx-12, cy), (cx+12, cy+8)], fill=(0,0,0,255), width=3)
                draw.line([(cx+12, cy), (cx-12, cy+8)], fill=(0,0,0,255), width=3)
                draw.line([(cx-10, cy+2), (cx+10, cy+10)], fill=(200,200,220,255), width=2)
                draw.line([(cx+10, cy+2), (cx-10, cy+10)], fill=(200,200,220,255), width=2)
            elif spec["detail"] == "archery":
                # Bow
                draw.arc([cx-10, cy-5, cx+10, cy+15], 200, 340, fill=(139,90,43,255), width=3)
            elif spec["detail"] == "stable":
                # Horse shoe
                draw.arc([cx-8, cy-2, cx+8, cy+14], 180, 360, fill=(0,0,0,255), width=3)
            elif spec["detail"] == "market":
                # Awning stripes
                for i, x in enumerate(range(cx-w//2, cx+w//2, 14)):
                    col = (200,60,60,255) if i%2==0 else (240,220,100,255)
                    draw.rectangle([x, cy-h//2+22, x+14, cy-h//2+32], fill=col, outline=(0,0,0,255), width=1)
        
        img.save(os.path.join(BUILDINGS_DIR, f"{name}.png"))
        print(f"Generated polished building: {name}")

def generate_units_polished():
    units = {
        "villager": {"body": (160,120,80), "accent": (120,90,60), "weapon": None, "size": 40, "type": "worker"},
        "swordsman": {"body": (180,180,200), "accent": (150,150,170), "weapon": "sword", "size": 44, "type": "melee"},
        "archer": {"body": (100,150,80), "accent": (80,120,60), "weapon": "bow", "size": 42, "type": "ranged"},
        "knight": {"body": (200,200,220), "accent": (180,180,200), "weapon": "lance", "size": 50, "type": "cavalry"},
        "mage": {"body": (120,80,180), "accent": (90,60,150), "weapon": "staff", "size": 44, "type": "magic"},
        "golem": {"body": (130,130,140), "accent": (100,100,110), "weapon": None, "size": 58, "type": "tank"},
        "dragon": {"body": (180,50,30), "accent": (140,30,20), "weapon": None, "size": 68, "type": "flying"},
        "healer": {"body": (220,220,180), "accent": (200,200,160), "weapon": "staff", "size": 40, "type": "healer"},
    }
    
    for name, spec in units.items():
        size = 128
        img = Image.new('RGBA', (size,size), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        cx, cy = size//2, size//2
        s = spec["size"]//2
        body_col = spec["body"]
        accent_col = spec["accent"]
        
        # Shadow
        draw.ellipse([cx-s+6, cy+s-2, cx+s+6, cy+s+8], fill=(0,0,0,70))
        
        if spec["type"] == "flying":
            # Dragon top-down polished
            # Body with gradient
            draw.ellipse([cx-s, cy-s//2, cx+s, cy+s//2], fill=body_col, outline=(0,0,0,255), width=3)
            # Scales
            for i in range(5):
                x = cx - s + i*12 + 8
                draw.ellipse([x, cy-8, x+14, cy+4], fill=tuple(min(255,c+20) for c in body_col), outline=(0,0,0,80), width=1)
            # Wings with membrane detail
            # Left
            draw.ellipse([cx-s-18, cy-s//2, cx-s+6, cy+s//2], fill=accent_col, outline=(0,0,0,255), width=2)
            # Wing fingers
            for y in [cy-10, cy, cy+10]:
                draw.line([(cx-s, y), (cx-s-18, y-4)], fill=(0,0,0,255), width=2)
            # Right
            draw.ellipse([cx+s-6, cy-s//2, cx+s+18, cy+s//2], fill=accent_col, outline=(0,0,0,255), width=2)
            for y in [cy-10, cy, cy+10]:
                draw.line([(cx+s, y), (cx+s+18, y-4)], fill=(0,0,0,255), width=2)
            # Head
            draw.ellipse([cx+s-6, cy-12, cx+s+18, cy+12], fill=body_col, outline=(0,0,0,255), width=3)
            # Horns
            draw.polygon([(cx+s+2, cy-12), (cx+s, cy-22), (cx+s+8, cy-10)], fill=(240,230,180,255), outline=(0,0,0,255), width=2)
            # Eye
            draw.ellipse([cx+s+6, cy-4, cx+s+12, cy+2], fill=(255,220,50,255), outline=(0,0,0,255), width=1)
            draw.ellipse([cx+s+8, cy-2, cx+s+10, cy+0], fill=(0,0,0,255))
            # Tail
            draw.polygon([(cx-s, cy), (cx-s-20, cy-8), (cx-s-20, cy+8)], fill=body_col, outline=(0,0,0,255), width=2)
            # Spines
            for i in range(3):
                sx = cx - s + 10 - i*8
                draw.polygon([(sx, cy-s//2), (sx-3, cy-s//2-10), (sx+3, cy-s//2)], fill=(0,0,0,255))
        elif spec["type"] == "tank":
            # Golem - rocky with cracks and glow
            draw.rectangle([cx-s, cy-s, cx+s, cy+s], fill=body_col, outline=(0,0,0,255), width=3)
            # Rock cracks
            for _ in range(6):
                x1 = random.randint(cx-s+4, cx+s-4)
                y1 = random.randint(cy-s+4, cy+s-4)
                x2 = x1 + random.randint(-12,12)
                y2 = y1 + random.randint(-12,12)
                draw.line([(x1,y1),(x2,y2)], fill=(0,0,0,80), width=2)
            # Eyes glow
            draw.rectangle([cx-12, cy-8, cx-4, cy+2], fill=(100,200,255,255), outline=(0,0,0,255), width=2)
            draw.rectangle([cx+4, cy-8, cx+12, cy+2], fill=(100,200,255,255), outline=(0,0,0,255), width=2)
            draw.rectangle([cx-10, cy-6, cx-6, cy+0], fill=(255,255,255,200))
            # Moss
            draw.ellipse([cx-s+2, cy-s+2, cx-s+12, cy-s+10], fill=(60,120,40,180))
        else:
            # Humanoid chibi polished
            # Legs
            draw.rectangle([cx-10, cy+8, cx-3, cy+s], fill=accent_col, outline=(0,0,0,255), width=2)
            draw.rectangle([cx+3, cy+8, cx+10, cy+s], fill=accent_col, outline=(0,0,0,255), width=2)
            # Body armor/clothes
            draw.rectangle([cx-14, cy-8, cx+14, cy+14], fill=body_col, outline=(0,0,0,255), width=3)
            # Belt
            draw.rectangle([cx-14, cy+6, cx+14, cy+10], fill=(80,60,30,255), outline=(0,0,0,255), width=1)
            # Arms
            draw.rectangle([cx-20, cy-4, cx-14, cy+8], fill=body_col, outline=(0,0,0,255), width=2)
            draw.rectangle([cx+14, cy-4, cx+20, cy+8], fill=body_col, outline=(0,0,0,255), width=2)
            # Head
            draw.ellipse([cx-14, cy-22, cx+14, cy-2], fill=(255,220,180,255), outline=(0,0,0,255), width=2)
            # Eyes
            draw.ellipse([cx-8, cy-14, cx-4, cy-10], fill=(0,0,0,255))
            draw.ellipse([cx+4, cy-14, cx+8, cy-10], fill=(0,0,0,255))
            # Helmet/hat based on type
            if spec["type"] == "melee":
                # Helmet with visor
                draw.rectangle([cx-16, cy-26, cx+16, cy-14], fill=(150,150,160,255), outline=(0,0,0,255), width=2)
                draw.rectangle([cx-16, cy-18, cx+16, cy-14], fill=(100,100,110,255))
            elif spec["type"] == "ranged":
                # Hood
                draw.ellipse([cx-16, cy-24, cx+16, cy-8], fill=(80,120,60,255), outline=(0,0,0,255), width=2)
            elif spec["type"] == "cavalry":
                # Knight helm with plume
                draw.rectangle([cx-16, cy-28, cx+16, cy-12], fill=(180,180,190,255), outline=(0,0,0,255), width=2)
                draw.rectangle([cx-2, cy-36, cx+4, cy-28], fill=(200,50,50,255), outline=(0,0,0,255), width=1)
            elif spec["type"] == "magic":
                # Wizard hat
                draw.polygon([(cx-14, cy-14), (cx, cy-32), (cx+14, cy-14)], fill=(80,40,120,255), outline=(0,0,0,255), width=2)
                draw.ellipse([cx-4, cy-30, cx+6, cy-20], fill=(100,200,255,255), outline=(0,0,0,255), width=1)
            elif spec["type"] == "healer":
                # White hood with red cross
                draw.ellipse([cx-14, cy-24, cx+14, cy-8], fill=(255,255,255,255), outline=(0,0,0,255), width=2)
                draw.rectangle([cx-2, cy-20, cx+2, cy-10], fill=(200,50,50,255))
                draw.rectangle([cx-6, cy-16, cx+6, cy-12], fill=(200,50,50,255))
            elif spec["type"] == "worker":
                # Cap
                draw.rectangle([cx-14, cy-22, cx+14, cy-14], fill=(160,120,80,255), outline=(0,0,0,255), width=2)
            
            # Weapon polished
            if spec["weapon"] == "sword":
                # Sword with guard
                draw.rectangle([cx+20, cy-2, cx+44, cy+2], fill=(200,200,220,255), outline=(0,0,0,255), width=2)
                draw.rectangle([cx+18, cy-6, cx+22, cy+6], fill=(100,80,40,255), outline=(0,0,0,255), width=1)
                # Shine
                draw.line([(cx+22, cy-1), (cx+40, cy-1)], fill=(255,255,255,150), width=1)
            elif spec["weapon"] == "bow":
                # Bow with string
                draw.arc([cx+14, cy-10, cx+30, cy+10], 270, 90, fill=(139,90,43,255), width=3)
                draw.line([(cx+22, cy-8), (cx+22, cy+8)], fill=(240,240,220,255), width=1)
                # Arrow
                draw.rectangle([cx+22, cy-1, cx+36, cy+1], fill=(200,180,100,255), outline=(0,0,0,255), width=1)
                draw.polygon([(cx+36, cy-3), (cx+42, cy), (cx+36, cy+3)], fill=(180,180,180,255), outline=(0,0,0,255), width=1)
            elif spec["weapon"] == "lance":
                # Lance with flag
                draw.rectangle([cx+20, cy-2, cx+52, cy+2], fill=(180,180,180,255), outline=(0,0,0,255), width=2)
                draw.polygon([(cx+52, cy-5), (cx+62, cy), (cx+52, cy+5)], fill=(200,200,200,255), outline=(0,0,0,255), width=2)
                draw.rectangle([cx+20, cy-6, cx+24, cy+6], fill=(120,80,40,255), outline=(0,0,0,255), width=1)
            elif spec["weapon"] == "staff":
                draw.rectangle([cx+20, cy-16, cx+24, cy+12], fill=(139,90,43,255), outline=(0,0,0,255), width=2)
                if spec["type"] == "magic":
                    # Orb
                    draw.ellipse([cx+16, cy-22, cx+28, cy-10], fill=(100,200,255,255), outline=(0,0,0,255), width=2)
                    draw.ellipse([cx+18, cy-20, cx+24, cy-14], fill=(255,255,255,180))
                    # Glow
                    draw.ellipse([cx+12, cy-26, cx+32, cy-6], fill=(100,200,255,40))
                else:
                    # Heal staff
                    draw.ellipse([cx+16, cy-22, cx+28, cy-10], fill=(255,255,150,255), outline=(0,0,0,255), width=2)
                    draw.ellipse([cx+18, cy-20, cx+24, cy-14], fill=(255,255,255,200))
        
        img.save(os.path.join(UNITS_DIR, f"{name}.png"))
        print(f"Generated polished unit: {name}")

def generate_tiles_polished():
    tiles = {
        "grass": {"base": (60,150,60), "detail": (40,120,40)},
        "forest": {"base": (35,90,35), "detail": (25,70,25)},
        "gold_vein": {"base": (180,150,30), "detail": (220,200,80)},
        "stone": {"base": (120,120,130), "detail": (90,90,100)},
        "mana_crystal": {"base": (80,60,140), "detail": (120,100,200)},
    }
    for name, cols in tiles.items():
        img = Image.new('RGBA', (96,96), cols["base"])
        draw = ImageDraw.Draw(img)
        # Texture
        for _ in range(40):
            x = random.randint(0,95)
            y = random.randint(0,95)
            s = random.randint(2,6)
            draw.ellipse([x,y,x+s,y+s], fill=cols["detail"] + (100,))
        # Border
        draw.rectangle([0,0,95,95], outline=(0,0,0,60), width=2)
        # Icon
        if name == "forest":
            # Tree
            draw.rectangle([40,56,56,88], fill=(80,50,20,255), outline=(0,0,0,255), width=2)
            draw.ellipse([16,16,80,64], fill=(20,80,20,255), outline=(0,0,0,255), width=2)
            draw.ellipse([24,24,48,48], fill=(40,120,40,180))
        elif name == "gold_vein":
            draw.ellipse([20,20,76,76], fill=(255,215,0,255), outline=(0,0,0,255), width=3)
            draw.ellipse([30,30,50,50], fill=(255,255,180,150))
        elif name == "stone":
            draw.rectangle([16,16,80,80], fill=(180,180,190,255), outline=(0,0,0,255), width=2)
            draw.rectangle([24,24,40,40], fill=(130,130,140,255))
            draw.rectangle([48,32,72,56], fill=(130,130,140,255))
        elif name == "mana_crystal":
            draw.polygon([(48,12),(72,36),(64,72),(32,72),(24,36)], fill=(120,100,220,255), outline=(0,0,0,255), width=2)
            draw.polygon([(48,12),(56,36),(48,60),(40,36)], fill=(150,130,255,180))
        
        img.save(os.path.join(TILES_DIR, f"{name}.png"))
        print(f"Generated polished tile: {name}")

def generate_ui_polished():
    # Button polished 320x80
    for state in ["normal", "pressed"]:
        w,h = 320,80
        img = Image.new('RGBA', (w,h), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        # Shadow
        draw.rounded_rectangle([4,8,w-4,h-4], radius=16, fill=(0,0,0,80))
        # Main
        bg = (90,70,50,255) if state=="normal" else (70,50,35,255)
        border = (60,40,20,255)
        draw.rounded_rectangle([0,0,w-8,h-8], radius=16, fill=bg, outline=border, width=3)
        # Highlight top
        draw.rounded_rectangle([4,4,w-12,24], radius=8, fill=(255,255,255,50))
        # Fantasy corners
        for x,y in [(4,4),(w-12,4),(4,h-12),(w-12,h-12)]:
            draw.rectangle([x,y,x+8,y+8], fill=(200,180,100,255), outline=(0,0,0,255), width=1)
        
        img.save(os.path.join(UI_DIR, f"button_{state}.png"))
    
    # Panel polished
    img = Image.new('RGBA', (512,512), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([8,8,504,504], radius=20, fill=(45,35,25,230), outline=(120,100,60,255), width=4)
    draw.rounded_rectangle([16,16,496,496], radius=16, outline=(200,180,100,60), width=2)
    # Inner shadow
    draw.rounded_rectangle([20,20,492,40], radius=8, fill=(255,255,255,20))
    img.save(os.path.join(UI_DIR, "panel_large.png"))
    img.resize((256,256), Image.LANCZOS).save(os.path.join(UI_DIR, "panel_small.png"))
    
    # Resource bar bg
    img = Image.new('RGBA', (720,120), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0,0,720,120], fill=(15,20,35,230), outline=(80,60,30,255), width=3)
    # Divider lines
    for x in range(120,720,120):
        draw.line([(x,10),(x,110)], fill=(80,60,30,100), width=2)
    img.save(os.path.join(UI_DIR, "resource_bar.png"))
    
    # Bottom nav bg
    img = Image.new('RGBA', (720,140), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0,0,720,140], fill=(20,15,10,240), outline=(80,60,30,255), width=3)
    img.save(os.path.join(UI_DIR, "bottom_nav.png"))
    
    print("Generated polished UI")

if __name__ == "__main__":
    print("=== Polished Assets v2.1.0 ===")
    generate_splash()
    generate_buildings_polished()
    generate_units_polished()
    generate_tiles_polished()
    generate_ui_polished()
    print("=== All polished assets generated ===")
