"""Motor de habitaciones en perspectiva de un punto de fuga central.
Mundo: X derecha, Y arriba, Z hacia el fondo (metros). Cámara en (0, ey, 0) mirando +Z."""
import numpy as np
from PIL import Image, ImageDraw
from lib import *

SS = 2          # supermuestreo de la geometría
PPM = 40        # píxeles de textura por metro


def homografia(dst, src):
    A, B = [], []
    for (x, y), (u, v) in zip(dst, src):
        A.append([x, y, 1, 0, 0, 0, -u*x, -u*y]); B.append(u)
        A.append([0, 0, 0, x, y, 1, -v*x, -v*y]); B.append(v)
    return np.linalg.solve(np.array(A, float), np.array(B, float))


def T(wm, hm, seed=0):
    """Lienzo-textura de wm x hm metros."""
    return Lienzo(max(2, int(round(wm*PPM))), max(2, int(round(hm*PPM))), seed)


class Sala:
    def __init__(s, W, H, D, ey, f, cy=None, tam=(320, 180), seed=1, niebla=(2.5, 11.0, 0.6),
                 color_niebla=(10, 12, 16)):
        s.W, s.H, s.D, s.ey, s.f = W, H, D, ey, f
        s.w, s.h = tam
        s.cx = s.w/2.0
        s.cy = cy if cy is not None else s.h*0.47
        s.lz = Lienzo(s.w, s.h, seed)
        s.rng = random.Random(seed)
        s.big = Image.new("RGB", (s.w*SS, s.h*SS), (0, 0, 0))
        s.zinv = np.zeros((s.h*SS, s.w*SS), np.float32)
        s.zonas = {}
        s.niebla = niebla; s.color_niebla = color_niebla
        s.seed = seed

    # ---------- proyección ----------
    def p(s, X, Y, Z):
        return (s.cx + s.f*X/Z, s.cy - s.f*(Y-s.ey)/Z)

    def pie(s, X, Z):
        """punto del suelo en el espacio 1280x720 (x4)"""
        x, y = s.p(X, 0, Z)
        return (x*4, y*4)

    def escala(s, Z):
        """píxeles (espacio x4) por metro a profundidad Z"""
        return s.f/Z*4

    # ---------- primitiva: textura sobre cuadrilátero 3D ----------
    def quad(s, pts3d, tex, src=None, zona=None):
        if isinstance(tex, Lienzo):
            tex = tex.img
        scr = [s.p(*q) for q in pts3d]
        dst = [(x*SS, y*SS) for x, y in scr]
        tw, th = tex.size
        src = src or [(0, 0), (tw, 0), (tw, th), (0, th)]
        coef = homografia(dst, src)
        warped = tex.convert("RGB").transform(s.big.size, Image.PERSPECTIVE, coef, Image.BILINEAR)
        mask = Image.new("L", s.big.size, 0)
        ImageDraw.Draw(mask).polygon(dst, fill=255)
        if tex.mode == "RGBA":
            al = tex.getchannel("A").transform(s.big.size, Image.PERSPECTIVE, coef, Image.BILINEAR)
            mask = Image.fromarray(((np.asarray(mask) > 0) & (np.asarray(al) > 127)).astype(np.uint8)*255)
        s.big.paste(warped, (0, 0), mask)
        # 1/z es afín en pantalla para un plano
        zs = [q[2] for q in pts3d]
        A = np.array([[x, y, 1] for x, y in dst], float)
        sol, *_ = np.linalg.lstsq(A, 1.0/np.array(zs), rcond=None)
        xs = [d[0] for d in dst]; ys = [d[1] for d in dst]
        x0, x1 = max(0, int(min(xs))), min(s.big.size[0], int(max(xs))+2)
        y0, y1 = max(0, int(min(ys))), min(s.big.size[1], int(max(ys))+2)
        if x1 > x0 and y1 > y0:
            gx, gy = np.meshgrid(np.arange(x0, x1), np.arange(y0, y1))
            zi = (sol[0]*gx + sol[1]*gy + sol[2]).astype(np.float32)
            m = np.asarray(mask)[y0:y1, x0:x1] > 0
            sub = s.zinv[y0:y1, x0:x1]
            sub[m] = zi[m]
        if zona:
            s.zonas[zona] = [(x*4, y*4) for x, y in scr]
        return scr

    def zona(s, nombre, pts3d):
        s.zonas[nombre] = [tuple(v*4 for v in s.p(*q)) for q in pts3d]

    def zona_pantalla(s, nombre, x, y, w, h):
        s.zonas[nombre] = [(x*4, y*4), ((x+w)*4, y*4), ((x+w)*4, (y+h)*4), (x*4, (y+h)*4)]

    # ---------- superficies base ----------
    def base(s, tex_izq, tex_der, tex_fondo, tex_suelo, tex_techo, z0=0.35):
        W, H, D = s.W, s.H, s.D
        s.tex = dict(izq=tex_izq, der=tex_der, fondo=tex_fondo)
        # suelo y techo
        sw, sh = tex_suelo.img.size
        s.quad([(-W/2, 0, D), (W/2, 0, D), (W/2, 0, z0), (-W/2, 0, z0)], tex_suelo,
               src=[(0, D*PPM), (sw, D*PPM), (sw, z0*PPM), (0, z0*PPM)] if False else None)
        s.quad([(-W/2, H, z0), (W/2, H, z0), (W/2, H, D), (-W/2, H, D)], tex_techo)
        # paredes: u = z (izq) / u = D-z (der)
        iw, ih = tex_izq.img.size
        s.quad([(-W/2, H, z0), (-W/2, H, D), (-W/2, 0, D), (-W/2, 0, z0)], tex_izq,
               src=[(z0*PPM, 0), (D*PPM, 0), (D*PPM, ih), (z0*PPM, ih)])
        iw, ih = tex_der.img.size
        s.quad([(W/2, H, D), (W/2, H, z0), (W/2, 0, z0), (W/2, 0, D)], tex_der,
               src=[((iw-D*PPM), 0), (iw-z0*PPM, 0), (iw-z0*PPM, ih), (iw-D*PPM, ih)])
        s.quad([(-W/2, H, D), (W/2, H, D), (W/2, 0, D), (-W/2, 0, D)], tex_fondo)

    # ---------- decals en paredes ----------
    def decal(s, lado, a0, a1, v0, v1, tex, m=0, zona=None, z_fondo=None):
        """lado: 'I' izquierda, 'D' derecha, 'F' fondo. a0<a1: z (laterales) o x (fondo). v: altura (m)."""
        W, D = s.W, s.D
        e = m/PPM
        if lado == "I":
            X = -W/2+0.005
            pts = [(X, v1+e, a0-e), (X, v1+e, a1+e), (X, v0-e, a1+e), (X, v0-e, a0-e)]
            zp = [(X, v1, a0), (X, v1, a1), (X, v0, a1), (X, v0, a0)]
        elif lado == "D":
            X = W/2-0.005
            pts = [(X, v1+e, a1+e), (X, v1+e, a0-e), (X, v0-e, a0-e), (X, v0-e, a1+e)]
            zp = [(X, v1, a1), (X, v1, a0), (X, v0, a0), (X, v0, a1)]
        else:
            Z = D-0.005
            pts = [(a0-e, v1+e, Z), (a1+e, v1+e, Z), (a1+e, v0-e, Z), (a0-e, v0-e, Z)]
            zp = [(a0, v1, Z), (a1, v1, Z), (a1, v0, Z), (a0, v0, Z)]
        s.quad(pts, tex)
        if zona:
            s.zona(zona, zp)

    def decal_suelo(s, x0, x1, z0, z1, tex, zona=None):
        s.quad([(x0, 0.003, z1), (x1, 0.003, z1), (x1, 0.003, z0), (x0, 0.003, z0)], tex)
        if zona:
            s.zona(zona, [(x0, 0, z1), (x1, 0, z1), (x1, 0, z0), (x0, 0, z0)])

    def horiz(s, x0, x1, z0, z1, y, tex, zona=None):
        """decal horizontal a altura y (mesas, suelo)."""
        s.quad([(x0, y, z1), (x1, y, z1), (x1, y, z0), (x0, y, z0)], tex)
        if zona:
            s.zona(zona, [(x0, y, z1), (x1, y, z1), (x1, y, z0), (x0, y, z0)])

    def frontal(s, x0, x1, y0, y1, Z, tex, m=0, zona=None):
        e = m/PPM
        s.quad([(x0-e, y1+e, Z), (x1+e, y1+e, Z), (x1+e, y0-e, Z), (x0-e, y0-e, Z)], tex)
        if zona:
            s.zona(zona, [(x0, y1, Z), (x1, y1, Z), (x1, y0, Z), (x0, y0, Z)])

    # ---------- cajas (muebles) ----------
    def caja(s, x0, x1, y0, y1, z0, z1, color, frente=None, lado=None, tapa=None, zona=None, ruido=0.08):
        def plano(wm, hm, k, sd):
            t = T(wm, hm, sd)
            t.degradado(0, 0, t.w, t.h, mul(color, k*1.1), mul(color, k*0.85))
            t.ruido(0, 0, t.w, t.h, 0.3, ruido*2)
            t.rect(0, 0, t.w, 1, mul(color, k*1.35)); t.rect(0, t.h-1, t.w, 1, mul(color, k*0.5))
            return t
        # tapa
        if y1 < s.ey:
            tt = tapa or plano(x1-x0, z1-z0, 1.15, 1)
            s.quad([(x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0)], tt)
        # lateral
        if (x0+x1)/2 > 0.02:
            tl = lado or plano(z1-z0, y1-y0, 0.7, 2)
            s.quad([(x0, y1, z1), (x0, y1, z0), (x0, y0, z0), (x0, y0, z1)], tl)
        elif (x0+x1)/2 < -0.02:
            tl = lado or plano(z1-z0, y1-y0, 0.7, 2)
            s.quad([(x1, y1, z0), (x1, y1, z1), (x1, y0, z1), (x1, y0, z0)], tl)
        tf = frente or plano(x1-x0, y1-y0, 1.0, 3)
        s.quad([(x0, y1, z0), (x1, y1, z0), (x1, y0, z0), (x0, y0, z0)], tf)
        if zona:
            s.zona(zona, [(x0, y1, z0), (x1, y1, z0), (x1, y0, z0), (x0, y0, z0)])

    # ---------- luces ----------
    def lampara(s, X, Z, ancho=1.0, largo=0.3, color=(210, 230, 235), fuerza=0.6, apagada=False, radio=1.6):
        H = s.H
        t = T(ancho, largo)
        t.rect(0, 0, t.w, t.h, (150, 155, 160))
        if not apagada:
            t.rect(2, 2, t.w-4, t.h-4, (240, 248, 250))
        else:
            t.rect(2, 2, t.w-4, t.h-4, (60, 62, 66))
        s.quad([(X-ancho/2, H-0.01, Z-largo/2), (X+ancho/2, H-0.01, Z-largo/2),
                (X+ancho/2, H-0.01, Z+largo/2), (X-ancho/2, H-0.01, Z+largo/2)], t)
        s._luces = getattr(s, "_luces", [])
        s._luces.append((X, Z, ancho, color, fuerza, apagada, radio))

    def aplicar_luces(s):
        for X, Z, ancho, color, fuerza, apagada, radio in getattr(s, "_luces", []):
            if apagada:
                continue
            xs, ys = s.p(X, s.H, Z)
            esc = s.f/Z
            s.lz.foco(xs, ys+2, esc*radio*0.7, esc*0.45, color, fuerza*0.9)
            xp, yp = s.p(X, 0, Z)
            s.lz.foco(xp, yp, esc*radio*1.4, esc*radio*0.35, color, fuerza*0.7)
            # luz sobre las paredes cercanas
            s.lz.foco(xs, s.p(X, s.H*0.55, Z)[1], esc*radio*1.7, esc*radio*1.1, color, fuerza*0.28)

    # ---------- composición ----------
    def componer(s):
        a = np.asarray(s.big, np.float32)
        zi = s.zinv
        z = np.where(zi > 1e-4, 1.0/np.maximum(zi, 1e-4), s.D)
        z0, z1, mx = s.niebla
        t = np.clip((z-z0)/(z1-z0), 0, 1)[..., None]*mx
        a = a*(1-t) + np.array(s.color_niebla, np.float32)*t
        im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).resize((s.w, s.h), Image.BOX)
        s.lz.img = im
        s.lz.d = ImageDraw.Draw(im)
        s.lz.d.fontmode = "1"
        return s.lz

# ----------------- texturas base -----------------
def tex_pared(wm, hm, color, tipo="panel", zocalo=None, seed=1, junta=1.0, azulejo_h=0.0, manchas=4):
    c = T(wm, hm, seed)
    c.degradado(0, 0, c.w, c.h, mul(color, 0.7), mul(color, 1.05))
    if tipo == "panel":
        n = int(wm/junta)+1
        for i in range(n):
            x = int(i*junta*PPM)
            c.linea(x, 0, x, c.h-1, mul(color, 0.72)); c.linea(x+1, 0, x+1, c.h-1, mul(color, 1.12))
    if azulejo_h > 0:
        ah = int(azulejo_h*PPM)
        for x in range(0, c.w, 8):
            c.linea(x, c.h-ah, x, c.h-1, mul(color, 0.8))
        for y in range(c.h-ah, c.h, 8):
            c.linea(0, y, c.w, y, mul(color, 0.8))
        c.rect(0, c.h-ah-1, c.w, 2, mul(color, 1.25))
    # manchas de humedad
    for i in range(manchas):
        x = c.rng.randint(0, max(1, c.w-12)); y = c.rng.randint(0, max(1, c.h-20))
        c.elipse(x, y, c.rng.randint(8, 30), c.rng.randint(10, 28), mul(color, 0.9))
    c.ruido(0, 0, c.w, c.h, 0.12, 0.14)
    # banda superior y zócalo
    c.rect(0, 0, c.w, 4, mul(color, 0.55))
    zc = zocalo or mul(color, 0.5)
    zh = max(3, int(0.12*PPM))
    c.rect(0, c.h-zh, c.w, zh, zc); c.rect(0, c.h-zh, c.w, 1, mul(zc, 1.5))
    return c


def tex_suelo(wm, dm, color, tipo="baldosa", seed=2, lado=1.0):
    c = T(wm, dm, seed)
    c.degradado(0, 0, c.w, c.h, mul(color, 1.05), mul(color, 0.85))
    if tipo == "baldosa":
        n = int(lado*PPM)
        for x in range(0, c.w, n):
            c.linea(x, 0, x, c.h-1, mul(color, 0.62))
        for y in range(0, c.h, n):
            c.linea(0, y, c.w, y, mul(color, 0.62))
        for i in range(int(wm*dm*1.2)):
            x = (c.rng.randint(0, c.w-1)//n)*n; y = (c.rng.randint(0, c.h-1)//n)*n
            c.rect(x+1, y+1, n-1, n-1, mul(color, c.rng.uniform(0.88, 1.12)))
    elif tipo == "madera":
        for x in range(0, c.w, 9):
            c.linea(x, 0, x, c.h-1, mul(color, 0.6))
        for i in range(int(wm*dm*2)):
            x = c.rng.randint(0, c.w-1); y = c.rng.randint(0, c.h-1)
            c.linea(x, y, x, min(c.h-1, y+c.rng.randint(6, 40)), mul(color, 0.7))
    c.ruido(0, 0, c.w, c.h, 0.16, 0.18)
    for i in range(int(wm*dm/3)):
        c.elipse(c.rng.randint(0, c.w), c.rng.randint(0, c.h), c.rng.randint(6, 26), c.rng.randint(4, 14), mul(color, 0.8))
    return c


def tex_techo(wm, dm, color, seed=3):
    c = T(wm, dm, seed)
    c.rect(0, 0, c.w, c.h, color)
    n = int(0.6*PPM)
    for x in range(0, c.w, n):
        c.linea(x, 0, x, c.h-1, mul(color, 0.6))
    for y in range(0, c.h, n):
        c.linea(0, y, c.w, y, mul(color, 0.6))
    c.ruido(0, 0, c.w, c.h, 0.2, 0.2)
    return c


def recortar(c, clave=(0, 0, 0)):
    """Lienzo -> imagen RGBA con el color clave transparente."""
    im = c.img.convert("RGBA")
    a = np.asarray(im).copy()
    m = (a[..., 0] == clave[0]) & (a[..., 1] == clave[1]) & (a[..., 2] == clave[2])
    a[m, 3] = 0
    return Image.fromarray(a)
