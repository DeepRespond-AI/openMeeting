"""Composes DR Meeting launcher-icon / splash source images from assets/brand/brand-logo.png
(same recipe as the desktop icon: white rounded tile + centered logo at ~62% of the canvas).

Outputs go to assets/brand/launcher/ (not bundled into the app). Usage, from mobile/:
    python3 tool/brand_images.py . && dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
import sys
from PIL import Image, ImageDraw, ImageFilter

root = sys.argv[1]
logo = Image.open(f'{root}/assets/brand/brand-logo.png').convert('RGBA')
logo = logo.crop(logo.getbbox())

def place(canvas, width_ratio, size, dy=0):
    w = int(size * width_ratio)
    h = int(logo.height * w / logo.width)
    l = logo.resize((w, h), Image.LANCZOS)
    canvas.alpha_composite(l, ((size - w) // 2, (size - h) // 2 + dy))

S = 1024
WHITE = (255, 255, 255, 255)

# 1) icon_1024.png — desktop-style: transparent canvas, soft shadow, white rounded tile, logo.
tile_margin = int(S * 30 / 512)
tile = S - 2 * tile_margin
radius = int(tile * 0.225)
icon = Image.new('RGBA', (S, S), (0, 0, 0, 0))
shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle(
    [tile_margin, tile_margin + 8, S - tile_margin, S - tile_margin + 8], radius, fill=(15, 23, 42, 40))
icon.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))
ImageDraw.Draw(icon).rounded_rectangle([tile_margin, tile_margin, S - tile_margin, S - tile_margin], radius, fill=WHITE)
place(icon, 318 / 512, S, dy=int(S * 0.02))
icon.save(f'{root}/assets/brand/launcher/icon_1024.png')

# 2) icon_ios_1024.png — opaque full-bleed white (iOS applies its own mask; alpha not allowed).
ios = Image.new('RGBA', (S, S), WHITE)
place(ios, 0.70, S, dy=int(S * 0.02))
ios.convert('RGB').save(f'{root}/assets/brand/launcher/icon_ios_1024.png')

# 3) icon_foreground_1024.png — Android adaptive foreground: logo inside the 66% safe zone.
fg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
place(fg, 0.56, S, dy=int(S * 0.015))
fg.save(f'{root}/assets/brand/launcher/icon_foreground_1024.png')

# 4) splash_logo.png — splash image (treated as xxxhdpi = 4x by flutter_native_splash).
sw = 720
sh = int(logo.height * sw / logo.width)
logo.resize((sw, sh), Image.LANCZOS).save(f'{root}/assets/brand/launcher/splash_logo.png')

# 5) splash_android12.png — Android 12 splash icon: 1152 canvas, visible circle of 768 → logo ≤ ~70% of it.
A = 1152
a12 = Image.new('RGBA', (A, A), (0, 0, 0, 0))
place(a12, 0.46, A)
a12.save(f'{root}/assets/brand/launcher/splash_android12.png')
print('ok')
