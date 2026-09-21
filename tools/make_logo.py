"""Builds the Spider-Tracker launcher icon.

Writes tools/logo.svg (source of truth) and tools/logo_fg.svg (the same mark
on a transparent canvas, for the adaptive icon foreground), then renders
them to PNG with ImageMagick and slices every Android density.

    python3 tools/make_logo.py

The mark: a progress ring filled part-way in red, with a compact geometric spider at its centre.
"""
import math, subprocess
from PIL import Image, ImageDraw

BLACK, TRACK, RED = "#0B0B0C", "#2A2A2F", "#E5383B"
S, C = 1024, 512
R, RING = 296, 52            # ring radius, stroke width
FILL = 0.70                  # how far the red arc runs, clockwise from the top

def octagon(r):
    return [(C + r*math.cos(math.radians(-90 + 45*i)), C + r*math.sin(math.radians(-90 + 45*i))) for i in range(8)]

def arc_points(pts, fraction):
    """Points along the closed polygon from vertex 0, clockwise, covering `fraction` of the perimeter."""
    ring = pts + [pts[0]]
    lens = [math.dist(ring[i], ring[i+1]) for i in range(8)]
    target = sum(lens) * fraction
    out, run = [ring[0]], 0.0
    for i, L in enumerate(lens):
        if run + L >= target:
            t = (target - run) / L
            out.append((ring[i][0] + (ring[i+1][0]-ring[i][0])*t, ring[i][1] + (ring[i+1][1]-ring[i][1])*t))
            return out
        run += L
        out.append(ring[i+1])
    return out

def path(pts, close=False):
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return d + (" Z" if close else "")

def mark():
    # progress ring: a full track and a red arc from 12 o'clock, clockwise
    ang = 2 * math.pi * FILL
    ex, ey = C + R * math.sin(ang), C - R * math.cos(ang)
    large = 1 if FILL > 0.5 else 0
    track = f'<circle cx="{C}" cy="{C}" r="{R}" fill="none" stroke="{TRACK}" stroke-width="{RING}"/>'
    arc = (f'<path d="M{C},{C-R} A{R},{R} 0 {large} 1 {ex:.1f},{ey:.1f}" fill="none" '
           f'stroke="{RED}" stroke-width="{RING}" stroke-linecap="round"/>')

    # spider: two-segment legs, mirrored, scaled to leave air inside the ring
    K = 0.90
    DY = -46 * K   # the rear legs are longer; lift the whole figure to sit centred
    legs = [((22,-34), (112,-104), (196,-78)),
            ((34,-6),  (150,-34),  (226,16)),
            ((34, 22), (150, 62),  (210,132)),
            ((22, 50), (100,128),  (146,204))]
    g = []
    for side in (-1, 1):
        for a, k, f in legs:
            p = [(C + side*x*K, C + (y + 8)*K + DY) for x, y in (a, k, f)]
            g.append(f'<path d="{path(p)}" fill="none" stroke="{RED}" stroke-width="{30*K:.1f}" '
                     f'stroke-linecap="round" stroke-linejoin="round"/>')
    body = (f'<ellipse cx="{C}" cy="{C+(38+8)*K+DY:.1f}" rx="{58*K:.1f}" ry="{78*K:.1f}" fill="{RED}"/>'
            f'<circle cx="{C}" cy="{C+(-50+8)*K+DY:.1f}" r="{34*K:.1f}" fill="{RED}"/>')
    return track + arc + "".join(g) + body

def svg(background):
    bg = f'<rect width="{S}" height="{S}" fill="{BLACK}"/>' if background else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
            f'{bg}{mark()}</svg>')

open("tools/logo.svg", "w").write(svg(True))
open("tools/logo_fg.svg", "w").write(svg(False))

def render(src, dst, transparent):
    args = ["convert", "-background", "none" if transparent else BLACK, "-density", "96", src, "-resize", f"{S}x{S}", dst]
    subprocess.run(args, check=True)

render("tools/logo.svg", "/tmp/logo/full.png", False)
render("tools/logo_fg.svg", "/tmp/logo/fg.png", True)

full = Image.open("/tmp/logo/full.png").convert("RGBA")
fg = Image.open("/tmp/logo/fg.png").convert("RGBA")
bgimg = Image.new("RGBA", (S, S), BLACK)

RES = "android/app/src/main/res"
for name, k in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
    n = int(108 * k)
    fg.resize((n, n), Image.LANCZOS).save(f"{RES}/mipmap-{name}/ic_launcher_foreground.png")
    bgimg.resize((n, n)).save(f"{RES}/mipmap-{name}/ic_launcher_background.png")
    n2 = int(48 * k)
    crop = int(S * 72 / 108); off = (S - crop) // 2
    tile = full.crop((off, off, off + crop, off + crop)).resize((n2, n2), Image.LANCZOS)
    mask = Image.new("L", (n2*4, n2*4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, n2*4-1, n2*4-1], radius=int(n2*4*0.22), fill=255)
    tile.putalpha(mask.resize((n2, n2), Image.LANCZOS))
    tile.save(f"{RES}/mipmap-{name}/ic_launcher.png")

# previews: full size, and at real launcher size
full.resize((512, 512), Image.LANCZOS).save("/tmp/logo/preview.png")
small = full.crop((off, off, off + crop, off + crop)).resize((48*3, 48*3), Image.LANCZOS)
small.save("/tmp/logo/preview_small.png")
print("ok")
