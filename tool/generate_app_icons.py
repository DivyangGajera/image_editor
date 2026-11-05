"""Generates Chitred's launcher icons and splash images.

Usage (from the repo root; needs Pillow with libraqm for Devanagari shaping):
    python3 tool/generate_app_icons.py . android/app/src/main/res
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = sys.argv[1]
OUT = sys.argv[2]  # android res dir, or a preview dir
FONT = os.path.join(ROOT, 'assets/ui_fonts/Poppins-700.ttf')
DEEP = (194, 65, 12)
SAFFRON = (249, 115, 22)
GLYPH = 'चि'

def gradient(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(DEEP[i] + (SAFFRON[i] - DEEP[i]) * (1 - t)) for i in range(3))
    return img

def glyph_layer(size, glyph_box, color=(255, 255, 255, 255)):
    """Transparent layer with the glyph centred, fitting a glyph_box square."""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font_size = int(glyph_box)
    for _ in range(40):
        font = ImageFont.truetype(FONT, font_size, layout_engine=ImageFont.Layout.RAQM) if ImageFont.core.HAVE_RAQM else ImageFont.truetype(FONT, font_size)
        l, t, r, b = draw.textbbox((0, 0), GLYPH, font=font)
        if r - l <= glyph_box and b - t <= glyph_box:
            break
        font_size = int(font_size * 0.95)
    l, t, r, b = draw.textbbox((0, 0), GLYPH, font=font)
    x = (size - (r - l)) / 2 - l
    y = (size - (b - t)) / 2 - t
    # soft shadow
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((x, y + size * 0.012), GLYPH, font=font, fill=(90, 30, 5, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.012))
    layer = Image.alpha_composite(shadow, layer)
    ImageDraw.Draw(layer).text((x, y), GLYPH, font=font, fill=color)
    return layer

def rounded_icon(size, radius_frac=0.24):
    bg = gradient(size).convert('RGBA')
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * radius_frac), fill=255)
    icon = Image.alpha_composite(bg, glyph_layer(size, size * 0.56))
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(icon, (0, 0), mask)
    return out

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)

if not ImageFont.core.HAVE_RAQM:
    sys.exit('Pillow needs libraqm to shape the Devanagari glyph correctly.')
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for name, f in DENSITIES.items():
    legacy = round(48 * f)
    save(rounded_icon(legacy * 4).resize((legacy, legacy), Image.LANCZOS), f'{OUT}/mipmap-{name}/ic_launcher.png')
    adaptive = round(108 * f)
    big = adaptive * 4
    # Adaptive layers: safe zone is the central 66 of 108 dp.
    save(gradient(big).resize((adaptive, adaptive), Image.LANCZOS), f'{OUT}/mipmap-{name}/ic_launcher_background.png')
    save(glyph_layer(big, big * 0.40).resize((adaptive, adaptive), Image.LANCZOS), f'{OUT}/mipmap-{name}/ic_launcher_foreground.png')
    mono = glyph_layer(big, big * 0.40, color=(0, 0, 0, 255))
    save(mono.resize((adaptive, adaptive), Image.LANCZOS), f'{OUT}/mipmap-{name}/ic_launcher_monochrome.png')
    splash = round(128 * f)
    save(rounded_icon(splash * 4).resize((splash, splash), Image.LANCZOS), f'{OUT}/drawable-{name}/splash_logo.png')
