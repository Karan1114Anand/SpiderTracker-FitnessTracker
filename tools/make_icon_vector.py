import numpy as np, math
from PIL import Image, ImageDraw, ImageFilter

S = 2048; C = S // 2
F = 1.12  # unit -> pixel scale

def bez(p0,p1,p2,p3,n=80):
    t = np.linspace(0,1,n)[:,None]
    P = [np.array(p,float) for p in (p0,p1,p2,p3)]
    return ((1-t)**3)*P[0] + 3*((1-t)**2)*t*P[1] + 3*(1-t)*(t**2)*P[2] + (t**3)*P[3]

def taper_poly(pts, w0, w1):
    n = len(pts)
    left, right = [], []
    for i in range(n):
        a = pts[max(i-1,0)]; b = pts[min(i+1,n-1)]
        d = b - a; d = d/ (np.linalg.norm(d)+1e-9)
        nrm = np.array([-d[1], d[0]])
        w = (w0 + (w1-w0)*(i/(n-1))**0.8)/2
        left.append(pts[i] + nrm*w); right.append(pts[i] - nrm*w)
    return [tuple(p) for p in left] + [tuple(p) for p in reversed(right)]

def to_px(p, side): return (C + side*p[0]*F, C + p[1]*F)

legs = [
    ((28,-70),  (150,-300), (330,-380), (470,-190), 64, 8),   # front, arcs up and hooks down
    ((40,-30),  (250,-190), (420,-170), (540,-40),  62, 8),
    ((40, 20),  (260, 110), (430, 140), (530, 260), 62, 8),
    ((28, 65),  (170, 250), (300, 380), (390, 500), 64, 8),   # rear, sweeps down
]

def mask_spider():
    m = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(m)
    for side in (-1, 1):
        for p0,p1,p2,p3,w0,w1 in legs:
            pts = bez(p0,p1,p2,p3)
            pts = np.array([to_px(p, side) for p in pts])
            poly = taper_poly(pts, w0*F, w1*F)
            d.polygon(poly, fill=255)
    # body drawn separately, then rounded so the joins have no notches
    bm = Image.new('L', (S, S), 0)
    bd = ImageDraw.Draw(bm)
    def ell(cx, cy, rx, ry): bd.ellipse([C+(cx-rx)*F, C+(cy-ry)*F, C+(cx+rx)*F, C+(cy+ry)*F], fill=255)
    ell(0, -128, 56, 60)      # head
    ell(0, -72, 60, 50)       # thorax
    ell(0, 52, 96, 140)       # abdomen
    bd.polygon([(C-84*F, C+120*F), (C+84*F, C+120*F), (C+18*F, C+232*F), (C-18*F, C+232*F)], fill=255)
    bm = bm.filter(ImageFilter.GaussianBlur(34)).point(lambda v: 255 if v > 118 else 0)
    m = Image.composite(bm, m, bm)
    return m

m = mask_spider().filter(ImageFilter.GaussianBlur(1.2))

# red vertical gradient
ys = np.linspace(0,1,S)[:,None]
top = np.array([255, 78, 80]); bot = np.array([190, 28, 34])
grad = (top*(1-ys) + bot*ys)[:, None, :].repeat(S, axis=1) if False else None
g = np.zeros((S,S,4), np.uint8)
for c in range(3):
    g[:,:,c] = (top[c]*(1-ys) + bot[c]*ys).astype(np.uint8).repeat(S, axis=1)
g[:,:,3] = np.array(m)
fg = Image.fromarray(g, 'RGBA')

# background: dark tile, soft vertical gradient + faint red glow
bgarr = np.zeros((S,S,4), np.uint8)
for c,(a,b) in enumerate([(26,10),(26,10),(30,12)]):
    bgarr[:,:,c] = (a*(1-ys) + b*ys).astype(np.uint8).repeat(S, axis=1)
bgarr[:,:,3] = 255
bg = Image.fromarray(bgarr, 'RGBA')
glow = Image.new('RGBA', (S,S), (0,0,0,0))
gd = ImageDraw.Draw(glow)
gd.ellipse([C-520, C-520, C+520, C+520], fill=(229,56,59,70))
glow = glow.filter(ImageFilter.GaussianBlur(220))
bg = Image.alpha_composite(bg, glow)

# a soft shadow under the spider for depth
sh = Image.new('RGBA', (S,S), (0,0,0,0))
shm = m.filter(ImageFilter.GaussianBlur(26))
sh.putalpha(shm.point(lambda v: int(v*0.55)))
fg_shadowed = Image.alpha_composite(sh.transform(sh.size, Image.AFFINE, (1,0,0,0,1,-18)), fg)

res = '/home/klaus/Projects/Spider-Tracker/android/app/src/main/res'
dens = {'mdpi':1, 'hdpi':1.5, 'xhdpi':2, 'xxhdpi':3, 'xxxhdpi':4}
def out(im, n): return im.resize((n, n), Image.LANCZOS)
for name, k in dens.items():
    n = int(108*k)
    out(fg, n).save(f'{res}/mipmap-{name}/ic_launcher_foreground.png')
    out(bg, n).save(f'{res}/mipmap-{name}/ic_launcher_background.png')
    n2 = int(48*k)
    comp = Image.alpha_composite(bg, fg_shadowed)
    crop = int(S*72/108); off = (S-crop)//2
    comp = comp.crop((off,off,off+crop,off+crop)).resize((n2,n2), Image.LANCZOS)
    mask = Image.new('L', (n2*4,n2*4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,n2*4-1,n2*4-1], radius=int(n2*4*0.22), fill=255)
    comp.putalpha(mask.resize((n2,n2), Image.LANCZOS))
    comp.save(f'{res}/mipmap-{name}/ic_launcher.png')

prev = Image.alpha_composite(bg, fg_shadowed)
crop = int(S*72/108); off=(S-crop)//2
prev.crop((off,off,off+crop,off+crop)).resize((512,512), Image.LANCZOS).save('/tmp/icon/preview2.png')
