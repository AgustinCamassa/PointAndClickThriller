import numpy as np, random, math
from PIL import Image, ImageDraw, ImageFont

BAYER = np.array([[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]], np.float32)/16.0
FUENTE = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

def mezcla(a, b, t):
    return tuple(int(a[i]*(1-t)+b[i]*t) for i in range(3))

def mul(c, f):
    return tuple(max(0, min(255, int(v*f))) for v in c)

class Lienzo:
    def __init__(s, w=320, h=180, seed=1):
        s.w, s.h = w, h
        s.img = Image.new("RGB", (w, h), (0, 0, 0))
        s.d = ImageDraw.Draw(s.img)
        s.d.fontmode = "1"
        s.luz = np.zeros((h, w, 3), np.float32)
        s.amb = np.ones((h, w, 3), np.float32)
        s.rng = random.Random(seed)
        s.nrng = np.random.RandomState(seed)

    # ---- primitivas ----
    def rect(s, x, y, w, h, c):
        s.d.rectangle([x, y, x+w-1, y+h-1], fill=c)
    def borde(s, x, y, w, h, c):
        s.d.rectangle([x, y, x+w-1, y+h-1], outline=c)
    def linea(s, x0, y0, x1, y1, c, ancho=1):
        s.d.line([x0, y0, x1, y1], fill=c, width=ancho)
    def poli(s, pts, c):
        s.d.polygon(pts, fill=c)
    def elipse(s, x, y, w, h, c):
        s.d.ellipse([x, y, x+w-1, y+h-1], fill=c)
    def px(s, x, y, c):
        if 0 <= x < s.w and 0 <= y < s.h:
            s.img.putpixel((int(x), int(y)), c)
    def texto(s, x, y, t, c, tam=7):
        f = ImageFont.truetype(FUENTE, tam)
        s.d.text((x, y), t, fill=c, font=f)
    def ancho_texto(s, t, tam=7):
        f = ImageFont.truetype(FUENTE, tam)
        return int(s.d.textlength(t, font=f))
    def degradado(s, x, y, w, h, c0, c1):
        for j in range(h):
            s.d.line([x, y+j, x+w-1, y+j], fill=mezcla(c0, c1, j/max(1, h-1)))
    def ruido(s, x, y, w, h, prob, delta):
        for j in range(h):
            for i in range(w):
                if s.rng.random() < prob:
                    px = s.img.getpixel((x+i, y+j)) if 0 <= x+i < s.w and 0 <= y+j < s.h else None
                    if px is not None:
                        k = 1 + s.rng.uniform(-delta, delta)
                        s.img.putpixel((x+i, y+j), mul(px, k))

    # ---- luz ----
    def foco(s, cx, cy, rx, ry, color, fuerza):
        ys, xs = np.mgrid[0:s.h, 0:s.w]
        d = np.sqrt(((xs-cx)/rx)**2 + ((ys-cy)/ry)**2)
        f = np.clip(1.0 - d, 0, 1)**1.6 * fuerza
        for k in range(3):
            s.luz[..., k] += f * (color[k]/255.0)
    def cono(s, cx, y0, y1, w0, w1, color, fuerza):
        ys, xs = np.mgrid[0:s.h, 0:s.w]
        t = np.clip((ys-y0)/max(1, (y1-y0)), 0, 1)
        half = (w0 + (w1-w0)*t)/2.0
        lateral = np.clip(1.0 - np.abs(xs-cx)/np.maximum(half, 1), 0, 1)
        mask = ((ys >= y0) & (ys <= y1)).astype(np.float32)
        f = lateral**1.3 * (1.0 - t*0.75) * mask * fuerza
        for k in range(3):
            s.luz[..., k] += f * (color[k]/255.0)
    def oscurecer(s, x, y, w, h, factor):
        s.amb[y:y+h, x:x+w, :] *= factor

    # ---- salida ----
    def final(s, niveles=11, vineta=0.55, grano=0.018, escala=4, ambiente=1.0, tinte=None):
        a = np.asarray(s.img, np.float32)/255.0
        a = a*s.amb*ambiente + s.luz*0.55*(0.35+a.mean(axis=2, keepdims=True))
        if tinte is not None:
            a = a*np.array(tinte, np.float32)
        ys, xs = np.mgrid[0:s.h, 0:s.w]
        r = np.sqrt(((xs-s.w/2)/(s.w*0.62))**2 + ((ys-s.h/2)/(s.h*0.68))**2)
        a *= (1.0 - vineta*np.clip(r-0.35, 0, 1)**1.5)[..., None]
        a += (s.nrng.rand(s.h, s.w, 1).astype(np.float32)-0.5)*grano*2
        a = np.clip(a, 0, 1)
        th = np.tile(BAYER, (s.h//4+1, s.w//4+1))[:s.h, :s.w][..., None]
        q = np.floor(a*(niveles-1) + th)/(niveles-1)
        im = Image.fromarray((np.clip(q, 0, 1)*255).astype(np.uint8))
        return im.resize((s.w*escala, s.h*escala), Image.NEAREST)

# ---- helpers de escena ----
def habitacion(c, pared, suelo, linea=140, techo=8, panel=True, zocalo=None):
    c.degradado(0, 0, c.w, linea, mul(pared, 0.72), pared)
    c.rect(0, 0, c.w, techo, mul(pared, 0.35))
    c.rect(0, techo, c.w, 1, mul(pared, 0.5))
    if panel:
        for x in range(0, c.w, 40):
            c.linea(x, techo, x, linea-1, mul(pared, 0.82))
            c.linea(x+1, techo, x+1, linea-1, mul(pared, 1.08))
    c.ruido(0, techo, c.w, linea-techo, 0.07, 0.12)
    z = zocalo or mul(pared, 0.55)
    c.rect(0, linea-4, c.w, 4, z)
    c.rect(0, linea-4, c.w, 1, mul(z, 1.4))
    # suelo con baldosas en perspectiva
    c.degradado(0, linea, c.w, c.h-linea, mul(suelo, 0.8), mul(suelo, 1.15))
    vp = (c.w/2, linea-30)
    for k in range(-12, 13):
        xb = c.w/2 + k*34
        c.linea(int(vp[0]+(xb-vp[0])*0.35), linea, int(xb), c.h-1, mul(suelo, 0.65))
    y = linea
    paso = 3.0
    while y < c.h:
        c.linea(0, int(y), c.w, int(y), mul(suelo, 0.68))
        paso *= 1.32
        y += paso
    c.ruido(0, linea, c.w, c.h-linea, 0.08, 0.15)

def puerta(c, x, y, w, h, color, cristal=None, picaporte=True, lado="d", marco=None):
    marco = marco or mul(color, 0.35)
    c.rect(x-2, y-2, w+4, h+2, marco)
    c.degradado(x, y, w, h, mul(color, 1.1), mul(color, 0.72))
    # paneles
    c.borde(x+3, y+4, w-6, int(h*0.38), mul(color, 0.6))
    c.borde(x+3, y+int(h*0.5), w-6, int(h*0.42), mul(color, 0.6))
    c.linea(x, y, x, y+h-1, mul(color, 1.4))           # canto iluminado
    c.linea(x+w-1, y, x+w-1, y+h-1, mul(color, 0.5))
    if cristal:
        cx, cy, cw, ch = cristal
        c.rect(x+cx, y+cy, cw, ch, (18, 28, 34))
        c.borde(x+cx-1, y+cy-1, cw+2, ch+2, mul(marco, 1.5))
    if picaporte:
        hx = x+w-6 if lado == "d" else x+4
        c.rect(hx, y+int(h*0.52), 3, 5, (190, 180, 140))
        c.rect(hx, y+int(h*0.52), 3, 1, (240, 235, 200))
    c.rect(x-2, y+h, w+4, 1, (0, 0, 0))     # sombra bajo la puerta

def lampara_techo(c, cx, y=8, ancho=40, color=(200, 220, 230), fuerza=0.7, apagada=False):
    c.rect(cx-ancho//2, y, ancho, 3, (150, 155, 160))
    if not apagada:
        c.rect(cx-ancho//2+2, y+3, ancho-4, 1, (235, 245, 250))
        c.cono(cx, y+3, y+130, ancho, ancho*3.2, color, fuerza)
        c.foco(cx, y+3, ancho*0.8, 10, color, fuerza*0.6)
    else:
        c.rect(cx-ancho//2+2, y+3, ancho-4, 1, (60, 62, 66))

def crt(c, x, y, w, h, pantalla=(30, 80, 60), carcasa=(128, 122, 108), brillo=0.5, base=True):
    c.rect(x, y, w, h, carcasa)
    c.rect(x, y, w, 1, mul(carcasa, 1.3))
    c.rect(x, y+h-1, w, 1, mul(carcasa, 0.6))
    c.rect(x+3, y+3, w-6, h-9, mul(carcasa, 0.4))
    c.rect(x+4, y+4, w-8, h-11, pantalla)
    # reflejo
    c.rect(x+5, y+5, max(1, (w-10)//3), 1, mul(pantalla, 1.8))
    c.foco(x+w/2, y+h/2, w*1.1, h*1.2, pantalla, brillo)
    c.rect(x+w//2-1, y+h-4, 2, 2, (80, 200, 90))      # led
    if base:
        c.rect(x+w//2-6, y+h, 12, 2, mul(carcasa, 0.7))
        c.rect(x+w//2-9, y+h+2, 18, 1, mul(carcasa, 0.5))

def lineas_texto(c, x, y, w, n, color, sep=3, seed=0):
    r = random.Random(seed)
    for i in range(n):
        ln = r.randint(w//3, w)
        c.rect(x, y+i*sep, ln, 1, color)

def rotulo(c, cx, y, texto, color=(180, 190, 195), fondo=(34, 38, 44), tam=6):
    w = c.ancho_texto(texto, tam)+6
    c.rect(cx-w//2, y, w, 9, fondo)
    c.borde(cx-w//2, y, w, 9, mul(fondo, 1.6))
    c.texto(cx-w//2+3, y-1, texto, color, tam)

# ---- fuente de píxeles 3x5 ----
_G = {
 "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
 "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
 "I": "111010010010111", "J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
 "M": "101111111101101", "N": "110101101101101", "O": "010101101101010", "P": "110101110100100",
 "Q": "010101101110011", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
 "U": "101101101101111", "V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
 "Y": "101101010010010", "Z": "111001010100111",
 "0": "111101101101111", "1": "010110010010111", "2": "110001010100111", "3": "110001010001110",
 "4": "101101111001001", "5": "111100110001110", "6": "011100111101111", "7": "111001010010010",
 "8": "111101111101111", "9": "111101111001110", "-": "000000111000000", ".": "000000000000010",
 ":": "000010000010000", " ": "000000000000000", "Ñ": "111000101101101", "!": "010010010000010",
 "?": "110001010000010", "/": "001001010100100",
}

def _texto_px(self, x, y, t, color, escala=1):
    cx = x
    for ch in t.upper():
        g = _G.get(ch, _G[" "])
        for i, b in enumerate(g):
            if b == "1":
                gx, gy = i % 3, i//3
                self.rect(cx+gx*escala, y+gy*escala, escala, escala, color)
        cx += 4*escala
    return cx - x
def _ancho_px(self, t, escala=1):
    return len(t)*4*escala - escala
Lienzo.texto_px = _texto_px
Lienzo.ancho_px = _ancho_px

def rotulo(c, cx, y, texto, color=(190, 200, 205), fondo=(30, 34, 40), tam=6):
    w = c.ancho_px(texto)+5
    c.rect(cx-w//2, y, w, 9, fondo)
    c.borde(cx-w//2, y, w, 9, mul(fondo, 1.8))
    c.texto_px(cx-w//2+3, y+2, texto, color)
