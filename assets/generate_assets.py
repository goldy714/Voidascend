"""
VoidAscent – pixel-art asset generator
Run: python assets/generate_assets.py
"""
from PIL import Image, ImageDraw, ImageFilter
import math, os

BASE = os.path.dirname(__file__)

def save(img: Image.Image, *path_parts):
    p = os.path.join(BASE, *path_parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print("  saved", p)

def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def upscale(img, factor=2):
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)

# ── colour palette ──────────────────────────────────────────────────────────
C = {
    "hull_light":  (180, 200, 230, 255),
    "hull_mid":    (100, 130, 170, 255),
    "hull_dark":   ( 45,  60,  90, 255),
    "cockpit":     ( 80, 200, 255, 255),
    "cockpit_hi":  (200, 240, 255, 255),
    "engine_glow": ( 80, 150, 255, 255),
    "engine_core": (160, 220, 255, 255),
    "red_trim":    (220,  50,  50, 255),
    "gold_trim":   (230, 180,  40, 255),
    "green_trim":  ( 50, 200,  80, 255),
    "purple":      (160,  60, 220, 255),
    "orange":      (240, 130,  20, 255),
    "white":       (255, 255, 255, 255),
    "black":       (  0,   0,   0, 255),
    "transp":      (  0,   0,   0,   0),
}

def glow_circle(draw, cx, cy, r, color, steps=8):
    """Draw a glowing dot by layering transparent circles."""
    r_, g_, b_, _ = color
    for i in range(steps, 0, -1):
        alpha = int(180 * (i / steps) ** 1.5)
        rad = r * i / steps
        draw.ellipse(
            [cx - rad, cy - rad, cx + rad, cy + rad],
            fill=(r_, g_, b_, alpha)
        )

# ═══════════════════════════════════════════════════════════════════════════
# SHIPS
# ═══════════════════════════════════════════════════════════════════════════

def make_scout():
    """Sleek triangular blue scout — 64×64."""
    S = 64
    img = new(S, S)
    d = ImageDraw.Draw(img)

    # Main hull — pointing UP (tip at top)
    hull = [(32, 4), (52, 54), (32, 46), (12, 54)]
    d.polygon(hull, fill=C["hull_mid"])

    # Hull highlight (left face)
    d.polygon([(32, 4), (12, 54), (32, 46)], fill=C["hull_light"])

    # Hull shadow (right face)
    d.polygon([(32, 4), (52, 54), (32, 46)], fill=C["hull_dark"])

    # Cockpit
    d.ellipse([26, 14, 38, 30], fill=C["cockpit"])
    d.ellipse([28, 16, 36, 24], fill=C["cockpit_hi"])

    # Side wings
    d.polygon([(12, 54), (4, 62), (20, 56)],  fill=C["hull_dark"])
    d.polygon([(52, 54), (60, 62), (44, 56)], fill=C["hull_dark"])
    d.polygon([(12, 54), (4, 62), (12, 60)],  fill=C["red_trim"])
    d.polygon([(52, 54), (60, 62), (52, 60)], fill=C["red_trim"])

    # Engine nozzle
    d.rectangle([26, 52, 38, 58], fill=C["hull_dark"])
    glow_circle(d, 32, 58, 8, C["engine_glow"])
    d.ellipse([28, 55, 36, 62], fill=C["engine_core"])

    # Outline
    d.polygon(hull, outline=C["black"])
    return img

def make_destroyer():
    """Wide, heavy destroyer — 64×64."""
    S = 64
    img = new(S, S)
    d = ImageDraw.Draw(img)

    # Wide hull
    hull = [(32, 6), (58, 44), (32, 52), (6, 44)]
    d.polygon(hull, fill=C["hull_mid"])
    d.polygon([(32, 6), (6, 44), (32, 52)],  fill=C["hull_light"])
    d.polygon([(32, 6), (58, 44), (32, 52)], fill=C["hull_dark"])

    # Armour plates
    d.polygon([(18, 36), (6, 44),  (20, 46)], fill=C["hull_dark"])
    d.polygon([(46, 36), (58, 44), (44, 46)], fill=C["hull_dark"])

    # Cockpit
    d.ellipse([25, 14, 39, 30], fill=C["cockpit"])
    d.ellipse([27, 16, 37, 24], fill=C["cockpit_hi"])

    # Dual cannons
    d.rectangle([14, 24, 20, 40], fill=C["hull_dark"])
    d.rectangle([44, 24, 50, 40], fill=C["hull_dark"])
    d.rectangle([15, 22, 19, 28], fill=C["red_trim"])
    d.rectangle([45, 22, 49, 28], fill=C["red_trim"])

    # Engine row
    for ex in [22, 32, 42]:
        d.rectangle([ex-3, 50, ex+3, 56], fill=C["hull_dark"])
        glow_circle(d, ex, 56, 5, C["engine_glow"])
        d.ellipse([ex-3, 53, ex+3, 60], fill=C["engine_core"])

    d.polygon(hull, outline=C["black"])
    return img

# ═══════════════════════════════════════════════════════════════════════════
# ENEMIES
# ═══════════════════════════════════════════════════════════════════════════

def make_enemy_basic():
    """Red alien saucer pointing DOWN — 48×48."""
    S = 48
    img = new(S, S)
    d = ImageDraw.Draw(img)

    # Body
    d.polygon([(24,44),(6,16),(42,16)], fill=(160,20,20,255))
    d.polygon([(24,44),(6,16),(24,22)], fill=(200,40,40,255))

    # Side fins
    d.polygon([(6,16),(0,28),(10,24)],  fill=(120,10,10,255))
    d.polygon([(42,16),(48,28),(38,24)],fill=(120,10,10,255))

    # Cockpit (ominous green)
    d.ellipse([19,14,29,24], fill=(30,180,60,255))
    d.ellipse([21,16,27,22], fill=(160,255,160,255))

    # Engine glow (top, since facing down)
    d.rectangle([20,6,28,14], fill=(80,10,10,255))
    glow_circle(d, 24, 8, 6, (255, 80, 20, 255))

    d.polygon([(24,44),(6,16),(42,16)], outline=C["black"])
    return img

def make_enemy_rare():
    """Purple elite enemy — 48×48."""
    S = 48
    img = new(S, S)
    d = ImageDraw.Draw(img)

    # Diamond body
    d.polygon([(24,44),(4,24),(24,4),(44,24)], fill=(100,20,160,255))
    d.polygon([(24,44),(4,24),(24,24)],        fill=(140,40,200,255))
    d.polygon([(24,4),(44,24),(24,24)],        fill=(80,10,130,255))

    # Core
    d.ellipse([18,18,30,30], fill=(200,100,255,255))
    d.ellipse([20,20,28,28], fill=(255,220,255,255))
    glow_circle(d, 24, 24, 10, (200, 80, 255, 255))

    # Spikes
    for angle_deg in [45, 135, 225, 315]:
        a = math.radians(angle_deg)
        x1, y1 = 24 + 14*math.cos(a), 24 + 14*math.sin(a)
        x2, y2 = 24 + 22*math.cos(a-0.25), 24 + 22*math.sin(a-0.25)
        x3, y3 = 24 + 22*math.cos(a+0.25), 24 + 22*math.sin(a+0.25)
        d.polygon([(x1,y1),(x2,y2),(x3,y3)], fill=(180,60,240,255))

    d.polygon([(24,44),(4,24),(24,4),(44,24)], outline=C["black"])
    return img

# ═══════════════════════════════════════════════════════════════════════════
# BULLETS
# ═══════════════════════════════════════════════════════════════════════════

def make_bullet_player():
    """Bright cyan laser bolt — 8×24."""
    img = new(8, 24)
    d = ImageDraw.Draw(img)
    # Core
    d.rectangle([3, 2, 4, 21], fill=(200, 240, 255, 255))
    # Glow
    d.rectangle([2, 4, 5, 19], fill=(80, 200, 255, 180))
    d.rectangle([1, 6, 6, 17], fill=(40, 140, 255,  80))
    # Tip
    d.ellipse([2, 0, 5, 5], fill=(255, 255, 255, 255))
    return img

def make_bullet_enemy():
    """Orange enemy shot — 6×18."""
    img = new(6, 18)
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, 3, 15], fill=(255, 200, 80, 255))
    d.rectangle([1, 4, 4, 13], fill=(255, 130, 20, 160))
    d.ellipse([1, 0, 4, 4],    fill=(255, 240, 160, 255))
    return img

# ═══════════════════════════════════════════════════════════════════════════
# PICKUPS
# ═══════════════════════════════════════════════════════════════════════════

def make_pickup_metal():
    """Grey hexagonal metal scrap — 20×20."""
    img = new(20, 20)
    d = ImageDraw.Draw(img)
    pts = [(10+8*math.cos(math.radians(60*i-30)),
            10+8*math.sin(math.radians(60*i-30))) for i in range(6)]
    d.polygon(pts, fill=(160,170,185,255), outline=(80,90,110,255))
    d.polygon([(10,10),(pts[0][0],pts[0][1]),(pts[1][0],pts[1][1])],
              fill=(200,210,225,200))
    d.ellipse([7,7,13,13], fill=(220,225,235,255))
    return img

def make_pickup_crystal():
    """Cyan gem — 20×20."""
    img = new(20, 20)
    d = ImageDraw.Draw(img)
    # Diamond shape
    d.polygon([(10,2),(18,10),(10,18),(2,10)], fill=(40,190,230,255), outline=(0,100,160,255))
    d.polygon([(10,2),(18,10),(10,10)],        fill=(120,230,255,220))
    glow_circle(d, 10, 10, 9, (80,200,255,255))
    d.ellipse([8,7,12,11], fill=(220,250,255,255))
    return img

# ═══════════════════════════════════════════════════════════════════════════
# MODULE ICONS  (32×32)
# ═══════════════════════════════════════════════════════════════════════════

def make_mod_weapon():
    """Red cannon icon."""
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,2,30,30], radius=4, fill=(60,10,10,255), outline=(180,20,20,255))
    # Barrel
    d.rectangle([14, 4, 18, 20], fill=(200,40,40,255))
    d.rectangle([13, 4, 19,  8], fill=(230,80,80,255))
    # Base
    d.ellipse([8,18,24,26], fill=(160,30,30,255), outline=(200,50,50,255))
    d.ellipse([11,20,21,24], fill=(200,50,50,255))
    glow_circle(d, 16, 6, 5, (255,100,60,255))
    return img

def make_mod_shield():
    """Blue shield icon."""
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,2,30,30], radius=4, fill=(10,20,60,255), outline=(40,100,220,255))
    # Shield shape
    d.polygon([(16,4),(28,10),(28,20),(16,28),(4,20),(4,10)],
              fill=(20,80,180,255), outline=(80,160,255,255))
    d.polygon([(16,4),(28,10),(16,16)], fill=(60,140,240,200))
    glow_circle(d, 16, 16, 8, (80,160,255,255))
    d.ellipse([12,12,20,20], fill=(160,220,255,255))
    return img

def make_mod_engine():
    """Orange thrust icon."""
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,2,30,30], radius=4, fill=(50,20,5,255), outline=(220,120,20,255))
    # Nozzle
    d.rectangle([11,6,21,20], fill=(160,80,20,255), outline=(220,130,40,255))
    d.polygon([(8,20),(24,20),(28,28),(4,28)], fill=(120,60,10,255))
    # Flame
    glow_circle(d, 16, 26, 8, (255,160,20,255))
    d.ellipse([11,22,21,30], fill=(255,220,80,255))
    glow_circle(d, 16, 24, 5, (255,100,10,255))
    return img

def make_mod_collector():
    """Yellow magnet icon."""
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,2,30,30], radius=4, fill=(40,35,5,255), outline=(200,180,20,255))
    # U-magnet
    d.arc([6,6,26,22], start=0, end=180, fill=(210,190,30,255), width=5)
    d.rectangle([6,14,11,26],  fill=(210,190,30,255))
    d.rectangle([21,14,26,26], fill=(210,190,30,255))
    # Poles
    d.rectangle([6,24,11,28],  fill=(220,40,40,255))
    d.rectangle([21,24,26,28], fill=(40,80,220,255))
    glow_circle(d, 16, 14, 6, (240,220,60,255))
    return img

def make_mod_cargo():
    """Grey crate icon."""
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,2,30,30], radius=4, fill=(25,28,32,255), outline=(120,130,145,255))
    # Crate
    d.rectangle([6,10,26,24], fill=(90,100,115,255), outline=(150,160,175,255))
    # Planks
    d.line([(16,10),(16,24)], fill=(130,140,155,255), width=1)
    d.line([(6,17),(26,17)],  fill=(130,140,155,255), width=1)
    # Handle
    d.rectangle([13,8,19,12], fill=(160,170,185,255), outline=(180,190,205,255))
    return img

def make_mod_special():
    """Purple star / ability icon."""
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,2,30,30], radius=4, fill=(20,5,40,255), outline=(160,40,240,255))
    # Star
    pts = []
    for i in range(10):
        r = 11 if i % 2 == 0 else 5
        a = math.radians(i * 36 - 90)
        pts.append((16 + r*math.cos(a), 16 + r*math.sin(a)))
    d.polygon(pts, fill=(140,40,210,255), outline=(200,100,255,255))
    glow_circle(d, 16, 16, 7, (200,80,255,255))
    d.ellipse([13,13,19,19], fill=(240,200,255,255))
    return img

# ═══════════════════════════════════════════════════════════════════════════
# BACKGROUND STAR / NEBULA  (for variety, optional)
# ═══════════════════════════════════════════════════════════════════════════

def make_planet_glacius():
    """Icy blue planet — 128×128, used as a background deco."""
    S = 128
    img = new(S, S)
    d = ImageDraw.Draw(img)
    # Base sphere
    d.ellipse([4,4,S-4,S-4], fill=(20,60,120,255))
    # Ice cap highlight
    d.ellipse([30,8,98,40],   fill=(160,210,240,200))
    d.ellipse([40,12,88,32],  fill=(220,240,255,220))
    # Surface bands
    for y, alpha in [(50,60),(70,40),(90,30)]:
        d.arc([10,y,S-10,y+18], start=0, end=180,
              fill=(100,160,220,alpha), width=3)
    # Atmosphere rim
    d.ellipse([4,4,S-4,S-4], outline=(100,180,255,120), width=4)
    d.ellipse([2,2,S-2,S-2], outline=(60,130,220, 60), width=3)
    return img

# ═══════════════════════════════════════════════════════════════════════════
# GENERATE ALL
# ═══════════════════════════════════════════════════════════════════════════

print("Generating VoidAscent assets...")

# Ships (scale ×2 → 128×128)
save(upscale(make_scout(), 2),    "ships", "ship_scout.png")
save(upscale(make_destroyer(), 2),"ships", "ship_destroyer.png")

# Enemies
save(upscale(make_enemy_basic(), 2), "enemies", "enemy_basic.png")
save(upscale(make_enemy_rare(),  2), "enemies", "enemy_rare.png")

# Bullets (keep small, Godot scales via sprite)
save(make_bullet_player(), "bullets", "bullet_player.png")
save(make_bullet_enemy(),  "bullets", "bullet_enemy.png")

# Pickups (scale ×2)
save(upscale(make_pickup_metal(),   2), "pickups", "pickup_metal.png")
save(upscale(make_pickup_crystal(), 2), "pickups", "pickup_crystal.png")

# Module icons (scale ×2 → 64×64)
save(upscale(make_mod_weapon(),    2), "modules", "mod_weapon.png")
save(upscale(make_mod_shield(),    2), "modules", "mod_shield.png")
save(upscale(make_mod_engine(),    2), "modules", "mod_engine.png")
save(upscale(make_mod_collector(), 2), "modules", "mod_collector.png")
save(upscale(make_mod_cargo(),     2), "modules", "mod_cargo.png")
save(upscale(make_mod_special(),   2), "modules", "mod_special.png")

# Planet
save(make_planet_glacius(), "fx", "planet_glacius.png")

print("Done! All assets written to assets/")
