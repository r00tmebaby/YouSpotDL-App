"""
YouSpotDL — Windows app icon generator.
Produces app/windows/runner/resources/app_icon.ico
with sizes: 256, 128, 64, 48, 32, 16.

Usage:  python generate_icon.py
Requires: pip install Pillow
"""

import os
import math

try:
    from PIL import Image, ImageDraw
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'Pillow'])
    from PIL import Image, ImageDraw


# ── Palette ────────────────────────────────────────────────────────────────
PRIMARY      = (0, 188, 212, 255)   # #00BCD4 cyan
PRIMARY_DARK = (0, 97, 100, 255)    # #006164 dark cyan
WHITE        = (255, 255, 255, 255)
WHITE_DIM    = (255, 255, 255, 220)
BADGE_BG     = (0, 60, 70, 220)


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def draw_rounded_rect_gradient(img: Image.Image, radius_frac: float = 0.22):
    """Fill image with a top-left→bottom-right linear gradient inside a rounded rect."""
    w, h = img.size
    r = max(2, int(w * radius_frac))
    mask = Image.new('L', (w, h), 0)
    md = ImageDraw.Draw(mask)
    try:
        md.rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=255)
    except AttributeError:
        md.rectangle([0, 0, w - 1, h - 1], fill=255)

    grad = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(h):
        for x in range(w):
            t = (x / w + y / h) / 2
            color = lerp_color(PRIMARY, PRIMARY_DARK, t)
            gd.point((x, y), fill=color)

    img.paste(grad, mask=mask)


def draw_music_note(draw: ImageDraw.ImageDraw, s: int, color):
    """Draw a simple quarter-note (head + stem + flag)."""
    # Note head — oval
    head_w = max(4, int(s * 0.24))
    head_h = max(3, int(s * 0.18))
    head_cx = int(s * 0.36)
    head_cy = int(s * 0.64)
    draw.ellipse(
        [head_cx - head_w // 2, head_cy - head_h // 2,
         head_cx + head_w // 2, head_cy + head_h // 2],
        fill=color,
    )

    # Stem — right side of head, going up
    stem_w = max(2, int(s * 0.07))
    stem_x = head_cx + head_w // 2 - stem_w
    stem_top = int(s * 0.22)
    stem_bot = head_cy
    draw.rectangle([stem_x, stem_top, stem_x + stem_w, stem_bot], fill=color)

    # Flag — small curve implied by filled ellipse at top-right of stem
    flag_w = max(3, int(s * 0.20))
    flag_h = max(3, int(s * 0.14))
    draw.ellipse(
        [stem_x, stem_top, stem_x + flag_w, stem_top + flag_h],
        fill=color,
    )


def draw_download_badge(draw: ImageDraw.ImageDraw, s: int):
    """Download arrow badge at bottom-right."""
    cs = max(6, int(s * 0.38))
    cx = s - cs - max(2, int(s * 0.06))
    cy = s - cs - max(2, int(s * 0.06))

    # Badge circle
    draw.ellipse([cx, cy, cx + cs, cy + cs], fill=BADGE_BG)

    # Arrow shaft
    ax = cx + cs // 2
    shaft_top = cy + int(cs * 0.18)
    shaft_bot = cy + int(cs * 0.60)
    sw = max(1, int(cs * 0.18))
    draw.rectangle([ax - sw // 2, shaft_top, ax + sw // 2, shaft_bot], fill=WHITE)

    # Arrow head (triangle)
    hw = max(2, int(cs * 0.32))
    ht = max(2, int(cs * 0.24))
    pts = [
        (ax - hw, shaft_bot),
        (ax + hw, shaft_bot),
        (ax, shaft_bot + ht),
    ]
    draw.polygon(pts, fill=WHITE)


def make_frame(s: int) -> Image.Image:
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_rounded_rect_gradient(img)

    if s >= 32:
        draw_music_note(draw, s, WHITE_DIM)
    if s >= 48:
        draw_download_badge(draw, s)

    return img


def generate_ico(output_path: str):
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    sizes = [256, 128, 64, 48, 32, 16]
    frames = [make_frame(s) for s in sizes]
    frames[0].save(
        output_path,
        format='ICO',
        append_images=frames[1:],
        sizes=[(s, s) for s in sizes],
    )
    print(f'✅  Icon written → {output_path}')


if __name__ == '__main__':
    out = os.path.join(
        os.path.dirname(__file__),
        'app', 'windows', 'runner', 'resources', 'app_icon.ico',
    )
    generate_ico(out)

