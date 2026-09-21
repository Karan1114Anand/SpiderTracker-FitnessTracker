"""Turn one square PNG (1024x1024 or larger) into every Android launcher icon.

    python3 tools/icons_from_png.py path/to/logo.png

Keep the artwork inside the central ~66% of the image: Android masks the
outer edge into a circle, squircle or rounded square depending on the phone.
Overwrites the mipmap-* launcher files under android/app/src/main/res.
"""
import sys
from PIL import Image, ImageDraw

RES = "android/app/src/main/res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

src = Image.open(sys.argv[1]).convert("RGBA")
side = min(src.size)
src = src.crop(((src.width - side) // 2, (src.height - side) // 2,
                (src.width + side) // 2, (src.height + side) // 2))

for name, k in DENSITIES.items():
    n = int(108 * k)                     # adaptive layers: 108dp
    src.resize((n, n), Image.LANCZOS).save(f"{RES}/mipmap-{name}/ic_launcher_background.png")
    Image.new("RGBA", (n, n), (0, 0, 0, 0)).save(f"{RES}/mipmap-{name}/ic_launcher_foreground.png")

    n2 = int(48 * k)                     # legacy icon: 48dp rounded square
    crop = int(side * 72 / 108); off = (side - crop) // 2
    tile = src.crop((off, off, off + crop, off + crop)).resize((n2, n2), Image.LANCZOS)
    mask = Image.new("L", (n2 * 4, n2 * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, n2 * 4 - 1, n2 * 4 - 1], radius=int(n2 * 4 * 0.22), fill=255)
    tile.putalpha(mask.resize((n2, n2), Image.LANCZOS))
    tile.save(f"{RES}/mipmap-{name}/ic_launcher.png")
print("done")
