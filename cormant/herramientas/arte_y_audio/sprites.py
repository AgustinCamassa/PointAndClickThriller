from lib import *
from PIL import Image, ImageDraw
import numpy as np

PIEL = (190, 146, 118); PIEL_S = (146, 106, 88)
PELO = (16, 16, 20); PELO_L = (52, 54, 66)
CHAQ = (36, 42, 62); CHAQ_L = (70, 82, 112); CHAQ_S = (24, 28, 42)
PANT = (26, 28, 40); PANT_L = (50, 56, 78)
ZAP = (14, 14, 18)
LUZ = (120, 150, 200)

class Sp:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); s.d = ImageDraw.Draw(s.im)
    def r(s, x, y, w, h, c): s.d.rectangle([x, y, x+w-1, y+h-1], fill=c+(255,))
    def e(s, x, y, w, h, c): s.d.ellipse([x, y, x+w-1, y+h-1], fill=c+(255,))
    def p(s, pts, c): s.d.polygon(pts, fill=c+(255,))
    def l(s, x0, y0, x1, y1, c, w=1): s.d.line([x0, y0, x1, y1], fill=c+(255,), width=w)
    def salida(s, escala=4, contorno=True):
        a = np.array(s.im)
        alfa = a[..., 3] > 0
        if contorno:
            ext = np.zeros_like(alfa)
            ext[1:, :] |= alfa[:-1, :]; ext[:-1, :] |= alfa[1:, :]
            ext[:, 1:] |= alfa[:, :-1]; ext[:, :-1] |= alfa[:, 1:]
            borde = ext & ~alfa
            a[borde] = (8, 8, 12, 255)
        # luz de contorno fría en el lado derecho
        der = np.zeros_like(alfa); der[:, :-1] = alfa[:, :-1] & ~alfa[:, 1:]
        a[der, :3] = np.clip(a[der, :3].astype(int)*0.55 + np.array(LUZ)*0.45, 0, 255).astype(np.uint8)
        return Image.fromarray(a).resize((s.w*escala, s.h*escala), Image.NEAREST)

def de_espaldas():
    s = Sp(30, 63)
    s.r(9, 38, 6, 22, PANT); s.r(15, 38, 6, 22, PANT); s.r(14, 38, 2, 22, (14, 14, 22)); s.r(9, 38, 1, 20, PANT_L)
    s.r(8, 59, 7, 4, ZAP); s.r(15, 59, 7, 4, ZAP)
    s.p([(6, 17), (24, 17), (23, 40), (7, 40)], CHAQ); s.r(7, 17, 16, 2, CHAQ_L); s.r(14, 19, 2, 20, CHAQ_S)
    s.r(7, 38, 16, 3, (20, 22, 32))
    s.r(2, 18, 5, 21, CHAQ); s.r(23, 18, 5, 21, CHAQ); s.r(2, 18, 1, 20, CHAQ_L)
    s.r(2, 38, 5, 4, PIEL); s.r(23, 38, 5, 4, PIEL)
    s.r(12, 13, 6, 4, PIEL_S)
    s.e(9, 1, 12, 14, PELO); s.r(10, 2, 3, 2, PELO_L); s.r(14, 3, 4, 1, PELO_L)
    s.r(8, 8, 2, 4, PIEL_S); s.r(20, 8, 2, 4, PIEL_S)
    return s.salida()

def sentado():
    s = Sp(30, 50)
    # base de silla y pie
    s.r(14, 38, 3, 8, (50, 52, 58)); s.l(6, 47, 24, 47, (40, 42, 48), 2); s.r(5, 46, 3, 3, (20, 20, 24)); s.r(22, 46, 3, 3, (20, 20, 24)); s.r(14, 46, 3, 3, (20, 20, 24))
    # respaldo
    s.r(5, 22, 20, 16, (56, 58, 66)); s.r(5, 22, 20, 1, (96, 100, 112)); s.r(5, 22, 1, 16, (84, 88, 98))
    # torso y brazos (hacia adelante)
    s.p([(5, 13), (25, 13), (24, 26), (6, 26)], CHAQ); s.r(5, 13, 20, 2, CHAQ_L); s.r(14, 15, 2, 11, CHAQ_S)
    s.r(2, 14, 4, 10, CHAQ); s.r(24, 14, 4, 10, CHAQ)
    s.r(12, 9, 6, 4, PIEL_S)
    s.e(9, 0, 12, 12, PELO); s.r(10, 1, 3, 2, PELO_L)
    s.r(8, 6, 2, 3, PIEL_S); s.r(20, 6, 2, 3, PIEL_S)
    return s.salida()

def perfil():
    s = Sp(28, 61)   # mira hacia la izquierda
    s.r(10, 38, 8, 20, PANT); s.r(10, 38, 1, 20, PANT_L); s.r(13, 38, 1, 20, (16, 16, 24))
    s.p([(5, 57), (14, 57), (14, 61), (3, 61)], ZAP)
    s.p([(8, 17), (20, 17), (19, 40), (9, 40)], CHAQ); s.r(8, 17, 12, 2, CHAQ_L); s.r(8, 17, 1, 22, CHAQ_L)
    s.r(7, 19, 5, 17, CHAQ); s.r(5, 33, 4, 4, CHAQ_S); s.r(3, 34, 4, 4, PIEL)      # brazo adelantado
    s.r(12, 13, 5, 5, PIEL_S)
    s.e(8, 1, 12, 13, PELO); s.r(10, 2, 4, 2, PELO_L)
    s.r(6, 6, 6, 8, PIEL); s.r(5, 9, 2, 2, PIEL)         # cara y nariz
    s.r(7, 8, 1, 1, (20, 20, 24))
    return s.salida()

def tumbado():
    # Visto desde los pies de la camilla (escorzo): cabeza al fondo, arriba; pies hacia la cámara, abajo.
    s = Sp(26, 26)
    s.e(8, 0, 11, 9, PIEL); s.e(8, 0, 11, 4, PELO); s.r(10, 5, 2, 1, (20, 20, 24)); s.r(15, 5, 2, 1, (20, 20, 24))
    s.r(4, 8, 18, 8, CHAQ); s.r(4, 8, 18, 2, CHAQ_L)                     # pecho
    s.r(2, 9, 3, 9, CHAQ_S); s.r(21, 9, 3, 9, CHAQ_S)                    # brazos
    s.r(2, 18, 3, 2, PIEL); s.r(21, 18, 3, 2, PIEL)                      # manos
    s.r(7, 16, 12, 7, PANT); s.r(7, 16, 12, 1, PANT_L); s.r(12, 17, 2, 6, PANT_L)   # piernas
    s.r(6, 23, 6, 3, ZAP); s.r(14, 23, 6, 3, ZAP)                        # suelas
    return s.salida()

def levantandose():
    s = Sp(37, 57)
    s.r(14, 42, 20, 8, PANT); s.r(14, 42, 20, 1, PANT_L)           # muslos hacia la izquierda
    s.r(14, 48, 8, 9, PANT); s.r(10, 55, 12, 2, ZAP)                # piernas colgando
    s.p([(18, 20), (32, 22), (34, 44), (18, 44)], CHAQ); s.r(18, 20, 14, 2, CHAQ_L)
    s.r(26, 28, 5, 14, CHAQ_S); s.r(28, 42, 4, 3, PIEL)              # brazo apoyado
    s.r(8, 22, 12, 6, CHAQ)
    s.r(10, 14, 5, 5, PIEL_S)
    s.e(4, 4, 14, 14, PELO); s.r(6, 5, 4, 2, PELO_L)               # cabeza inclinada
    s.r(5, 11, 5, 6, PIEL); s.r(6, 13, 1, 1, (20, 20, 24))
    return s.salida()

def mancha():
    """Mancha oscura y húmeda en el suelo (sprite RGBA, 3:1)."""
    w, h = 60, 20
    r = np.random.RandomState(5)
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    nx = (xs-w/2)/(w/2); ny = (ys-h/2)/(h/2)
    ang = np.arctan2(ny, nx)
    radio = 0.82+0.12*np.sin(ang*3+1.0)+0.08*np.sin(ang*5+2.0)
    d = np.sqrt(nx**2+ny**2)
    a = np.zeros((h, w, 4), np.uint8)
    dentro = d < radio
    base = np.array([54, 14, 14], np.float32)
    ruido = r.uniform(-8, 8, (h, w, 1))
    col = np.clip(base+ruido, 0, 255)
    a[dentro, :3] = col[dentro]; a[dentro, 3] = 255
    luz = dentro & (ny < -0.2) & (d < radio*0.7) & (r.rand(h, w) < 0.5)
    a[luz, :3] = (96, 30, 30)
    gotas = (d >= radio) & (d < radio+0.12) & (r.rand(h, w) < 0.12)
    a[gotas, :3] = (54, 14, 14); a[gotas, 3] = 255
    return Image.fromarray(a).resize((w*3, h*3), Image.NEAREST)

def cuadro(girado):
    s = Sp(38, 28)
    s.r(0, 0, 38, 28, (90, 64, 34)); s.r(0, 0, 38, 1, (170, 130, 70)); s.r(0, 0, 1, 28, (140, 104, 56)); s.r(37, 0, 1, 28, (52, 36, 20))
    s.r(2, 2, 34, 24, (40, 30, 20))
    # lienzo: crepúsculo con lago y pinos
    for y in range(3, 25):
        t = (y-3)/21.0
        col = mezcla((190, 120, 80), (40, 52, 84), t) if y < 14 else mezcla((30, 44, 70), (14, 20, 34), (y-14)/10.0)
        if girado and y < 14:
            col = mezcla((170, 60, 60), (40, 30, 60), t)
        s.r(3, y, 32, 1, col)
    s.p([(3, 14), (10, 8), (16, 14)], (14, 24, 34)); s.p([(14, 14), (24, 6), (34, 14)], (10, 20, 30))
    s.r(3, 14, 32, 1, (70, 90, 120))
    for x, h in [(6, 6), (9, 9), (29, 8), (32, 6)]:
        s.p([(x, 14), (x+2, 14-h), (x+4, 14)], (8, 16, 20))
    s.e(24, 4, 4, 4, (240, 220, 170) if not girado else (230, 90, 80))   # sol / luna
    if girado:
        s.r(18, 16, 2, 5, (4, 4, 6)); s.e(17, 14, 4, 4, (4, 4, 6))      # una figura en el lago
    return s.salida(contorno=False)

if __name__ == "__main__":
    ims = [de_espaldas(), sentado(), perfil(), tumbado(), levantandose(), cuadro(False), cuadro(True)]
    W = sum(i.width for i in ims)+10*len(ims)
    sheet = Image.new("RGB", (W, 300), (60, 70, 70)); x = 0
    for i in ims:
        sheet.paste(i, (x, 0), i); x += i.width+10
    sheet.save("hoja_sprites.png")
