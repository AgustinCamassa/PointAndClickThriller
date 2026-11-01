# OBSOLETO: salas provisionales en 3D (ver exportar3d.py). No se usa con los fondos fotorrealistas.
from persp import *
from escenas1 import ROJO, MARRON, AZUL, MORADO, reloj, planta

# ---------- texturas de objetos ----------
def mancha(wm, hm, color, seed=0, op=150):
    w, h = int(wm*PPM), int(hm*PPM)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).ellipse([0, 0, w-1, h-1], fill=op)
    from PIL import ImageFilter
    m = m.filter(ImageFilter.GaussianBlur(3))
    im.paste(Image.new("RGB", (w, h), color), (0, 0), m)
    a = np.asarray(im).copy(); a[..., 3] = np.asarray(m)
    a[..., 3] = (a[..., 3] > 40)*255
    return Image.fromarray(a)

def tex_puerta(color, w=0.95, h=2.1, cristal=None, picaporte=True, rot=None, lado="d"):
    pw, ph = int(w*PPM), int(h*PPM)
    c = Lienzo(pw+4, ph+4, 5)
    puerta(c, 2, 2, pw, ph, color, cristal=cristal, picaporte=picaporte, lado=lado)
    return c

def tex_rotulo(texto, color=(190, 200, 205), fondo=(30, 34, 40)):
    w = len(texto)*4+6
    c = Lienzo(w, 11, 1)
    c.rect(0, 0, w, 11, fondo); c.borde(0, 0, w, 11, mul(fondo, 1.8))
    c.texto_px(3, 3, texto, color)
    return c

def ancho_rotulo_m(texto):
    return (len(texto)*4+6)/PPM

def tex_crt(wm=0.6, hm=0.48, pantalla=(30, 120, 74), brillo=0.0, carcasa=(128, 122, 108), lineas=True):
    w, h = int(wm*PPM), int(hm*PPM)
    c = Lienzo(w, h+3, 7)
    c.rect(0, 0, w, h+3, (0, 0, 0))
    crt(c, 0, 0, w, h, pantalla, carcasa, brillo=0.0, base=False)
    if lineas:
        lineas_texto(c, 4, 5, w-10, max(2, (h-12)//3), mul(pantalla, 2.0), 3, 4)
    c.rect(w//2-6, h, 12, 2, mul(carcasa, 0.7))
    return c

def tex_color(wm, hm, color, ruido=0.12, borde=True):
    c = T(wm, hm, 9)
    c.degradado(0, 0, c.w, c.h, mul(color, 1.1), mul(color, 0.85))
    c.ruido(0, 0, c.w, c.h, 0.25, ruido)
    if borde:
        c.borde(0, 0, c.w, c.h, mul(color, 0.5))
    return c

def tex_cristal(wm, hm, fondo=(10, 16, 24), marco=(78, 84, 94), siluetas=True, tinte=(110, 140, 170)):
    c = T(wm, hm, 11)
    c.rect(0, 0, c.w, c.h, marco)
    m = 3
    c.rect(m, m, c.w-2*m, c.h-2*m, fondo)
    if siluetas:
        for i in range(3):
            x = m+4+i*(c.w//4); y = c.h//2+c.rng.randint(-4, 6)
            c.rect(x, y, 6+c.rng.randint(0, 6), c.h-m-y-2, mul(fondo, 1.9))
    # reflejo diagonal
    c.linea(m, c.h-m-1, c.w//2, m, mul(fondo, 2.6)); c.linea(m+6, c.h-m-1, c.w//2+6, m, mul(fondo, 2.0))
    return c

# ---------------------------------------------------------------- RECEPCIÓN
def _puerta_cristal():
    c = Lienzo(int(1.6*PPM)+4, int(2.2*PPM)+4, 6)
    c.rect(0, 0, c.w, c.h, (60, 42, 28)); c.rect(2, 2, c.w//2-3, c.h-4, (86, 60, 40)); c.rect(c.w//2+1, 2, c.w//2-3, c.h-4, (86, 60, 40))
    for x0 in (6, c.w//2+5):
        c.rect(x0, 8, c.w//2-13, c.h-18, (150, 175, 190)); c.ruido(x0, 8, c.w//2-13, c.h-18, 0.3, 0.15)
    c.rect(c.w//2-3, c.h//2, 2, 6, (210, 170, 70)); c.rect(c.w//2+1, c.h//2, 2, 6, (210, 170, 70))
    return c

def _puerta_restringida():
    c = Lienzo(int(1.2*PPM)+4, int(2.3*PPM)+4, 6)
    c.rect(0, 0, c.w, c.h, (46, 40, 36)); c.degradado(2, 2, c.w-4, c.h-4, (112, 82, 56), (84, 60, 40))
    c.borde(5, 6, c.w-10, c.h-12, (70, 50, 36)); c.rect(c.w-9, c.h//2, 3, 6, (190, 180, 150))
    c.rect(c.w//2-16, 14, 32, 9, (50, 38, 30)); c.texto_px(c.w//2-14, 16, "PRIVADO", (190, 170, 140))
    return c

def _recepcion_base(seed, reverso=False):
    W, H, D = 7.0, 3.2, 9.0
    s = Sala(W, H, D, 1.6, 160, cy=88, seed=seed, niebla=(3.0, 12.0, 0.65))
    col = (74, 86, 98)
    s.base(tex_pared(D, H, col, "panel", seed=1, junta=0.8), tex_pared(D, H, col, "panel", seed=2, junta=0.8),
           tex_pared(W, H, col, "panel", seed=3, junta=0.8), tex_suelo(W, D, (54, 60, 68), seed=4, lado=0.5),
           tex_techo(W, D, (58, 62, 68)))
    # tuberías de cobre a lo largo de las paredes
    for lado in ("I", "D"):
        t = T(D, 0.07); t.rect(0, 0, t.w, t.h, (150, 96, 60)); t.rect(0, 0, t.w, 1, (210, 150, 100))
        s.decal(lado, 0.35, D, 2.55, 2.62, t)
    return s

def recepcion():
    s = _recepcion_base(11)
    W, H, D = s.W, s.H, s.D
    # alfombra
    r = tex_suelo(4.6, 3.8, (96, 88, 70), tipo="madera", seed=5); r.ruido(0, 0, r.w, r.h, 0.6, 0.2)
    s.decal_suelo(-2.3, 2.3, 3.2, 7.0, r)
    # letrero CORMANT (cristal unidireccional = ventana amarilla del boceto)
    c = T(3.4, 1.05, 12)
    c.rect(0, 0, c.w, c.h, (96, 102, 110)); c.rect(3, 3, c.w-6, c.h-6, (10, 14, 20)); c.borde(3, 3, c.w-6, c.h-6, (40, 46, 54))
    c.linea(20, c.h-5, 52, 5, (22, 30, 40)); c.linea(70, c.h-5, 102, 5, (22, 30, 40))
    t = "CORMANT"; tw = c.ancho_texto(t, 17); c.texto(c.w//2-tw//2, 6, t, (150, 160, 172), 17)
    c.texto_px(c.w//2-c.ancho_px("MEDICAL SYSTEMS")//2, c.h-14, "MEDICAL SYSTEMS", (96, 106, 118))
    s.frontal(-2.3, 1.1, 1.65, 2.7, D, c, zona="letrero")
    # mostrador
    fr = T(3.8, 1.05, 13)
    fr.rect(0, 0, fr.w, fr.h, (76, 62, 50))
    for x in range(0, fr.w, 22): fr.linea(x, 6, x, fr.h-1, (58, 46, 38))
    fr.rect(0, 0, fr.w, 6, (156, 142, 120)); fr.rect(0, 0, fr.w, 1, (200, 190, 168)); fr.ruido(0, 0, fr.w, fr.h, 0.12, 0.15)
    s.caja(-2.4, 1.4, 0, 1.05, 7.7, 8.5, (120, 96, 72), frente=fr)
    s.zona("numero", [(-1.5, 0.95, 7.7), (-0.5, 0.95, 7.7), (-0.5, 0.3, 7.7), (-1.5, 0.3, 7.7)])
    # ordenadores y papeles
    s.frontal(-1.85, -1.25, 1.05, 1.55, 8.0, tex_crt(0.6, 0.5, (30, 120, 74)), zona="pc1")
    s.frontal(-0.55, 0.05, 1.05, 1.55, 8.0, tex_crt(0.6, 0.5, (26, 42, 126), lineas=False), zona="pc2")
    p = T(1.0, 0.22); p.rect(0, 0, p.w, p.h, (226, 224, 210)); lineas_texto(p, 2, 2, 30, 3, (120, 120, 130), 3, 3)
    s.horiz(-1.15, -0.65, 7.85, 8.15, 1.055, p)
    # puerta roja a la derecha del mostrador, en la pared del fondo
    s.frontal(1.85, 2.8, 0, 2.15, D, tex_puerta(ROJO), m=2, zona="puerta_pasillo")
    rw = ancho_rotulo_m("PASILLO")
    s.frontal(2.32-rw/2, 2.32+rw/2, 2.3, 2.3+11/PPM, D, tex_rotulo("PASILLO"))
    # reloj
    c = Lienzo(24, 24, 3); reloj(c, 12, 12, 10, 3, 14)
    s.frontal(1.2, 1.7, 2.4, 2.9, D, c)
    # pared izquierda: puerta doble de cristal marrón (sin acceso), a mitad de sala
    s.decal("I", 4.0, 5.6, 0, 2.2, _puerta_cristal(), m=2, zona="puerta_izq")
    # corcho
    t = T(1.2, 0.9); t.rect(0, 0, t.w, t.h, (96, 72, 50)); t.rect(2, 2, t.w-4, t.h-4, (150, 110, 74)); t.ruido(2, 2, t.w-4, t.h-4, 0.2, 0.2)
    for (x, y, w, h, col) in [(6, 6, 12, 15, (222, 220, 205)), (22, 8, 14, 10, (210, 200, 160)), (30, 20, 12, 12, (200, 215, 225))]:
        t.rect(x, y, w, h, col)
    s.decal("I", 6.4, 7.6, 1.2, 2.1, t)
    # pared derecha: puerta metálica marrón (sin acceso) y lector rojo
    s.decal("D", 4.2, 5.4, 0, 2.3, _puerta_restringida(), m=2, zona="puerta_der")
    t = T(0.22, 0.34); t.rect(0, 0, t.w, t.h, (26, 28, 32)); t.rect(3, 3, t.w-6, 8, (60, 64, 70)); t.rect(t.w//2-1, t.h-8, 3, 3, (255, 40, 40))
    s.decal("D", 5.55, 5.77, 1.0, 1.34, t)
    # extintor
    t = T(0.22, 0.6); t.rect(2, 8, t.w-4, t.h-8, (170, 30, 30)); t.rect(4, 2, t.w-8, 7, (40, 40, 40)); t.rect(4, 14, 3, t.h-20, (220, 90, 90))
    s.decal("D", 6.3, 6.52, 0.9, 1.5, t)
    # luces
    for z in (4.0, 7.0):
        for x in (-1.9, 1.9):
            s.lampara(x, z, 0.18, 1.3, (200, 225, 240), 0.5, radio=1.5)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(-0.8, 1.2, 8.0), 28, 18, (110, 255, 150), 0.18)
    s.zona_pantalla("vuelta", 138, 160, 44, 18)
    return lz.final(ambiente=1.4), s

def recepcion_reverso():
    s = _recepcion_base(12, True)
    W, H, D = s.W, s.H, s.D
    # ventanales con niebla a los lados de la puerta
    for x0, x1 in ((-3.1, -1.7), (1.7, 3.1)):
        c = T(x1-x0, 1.6, 14); c.rect(0, 0, c.w, c.h, (58, 64, 72)); c.degradado(3, 3, c.w-6, c.h-6, (170, 190, 205), (110, 130, 148))
        c.linea(c.w//2, 3, c.w//2, c.h-4, (58, 64, 72))
        s.frontal(x0, x1, 0.8, 2.4, D, c, m=0)
    # puerta de entrada de cristal
    c = Lienzo(int(1.5*PPM), int(2.4*PPM), 15)
    c.rect(0, 0, c.w, c.h, (50, 56, 64)); c.degradado(3, 3, c.w//2-4, c.h-4, (190, 205, 218), (120, 140, 156))
    c.degradado(c.w//2+2, 3, c.w//2-5, c.h-4, (186, 202, 216), (116, 136, 152))
    c.rect(c.w//2-1, 3, 3, c.h-4, (40, 44, 52)); c.rect(c.w//2-9, c.h//2, 2, 10, (190, 190, 190)); c.rect(c.w//2+7, c.h//2, 2, 10, (190, 190, 190))
    s.frontal(-0.75, 0.75, 0, 2.4, D, c, zona="puerta_entrada")
    c = Lienzo(36, 9, 2); c.rect(0, 0, 36, 9, (26, 30, 34)); c.texto_px(7, 2, "SALIDA", (80, 230, 120))
    s.frontal(-0.4, 0.4, 2.55, 2.55+9/PPM, D, c)
    # bancos de espera en ambas paredes
    for lado, x0, x1 in (("I", -3.5, -3.05), ("D", 3.05, 3.5)):
        s.caja(x0, x1, 0, 0.45, 5.7, 8.4, (52, 70, 100))
    # las mismas puertas marrones de la vista hacia el mostrador (z medido desde esta pared): a la izquierda la
    # metálica del lado este, a la derecha la doble de cristal del lado oeste
    s.decal("I", 3.6, 4.8, 0, 2.3, _puerta_restringida(), m=2, zona="puerta_restringida")
    s.decal("D", 3.4, 5.0, 0, 2.2, _puerta_cristal(), m=2, zona="puerta_cristal")
    # plantas
    for x in (-1.6, 1.0):
        c = Lienzo(22, 28, 3); planta(c, 2, 0)
        s.frontal(x, x+0.55, 0, 0.7, D-0.3, recortar(c))
    # tablones
    for lado, a0, a1 in (("I", 6.3, 7.0), ("D", 6.3, 7.0)):
        c = T(0.7, 0.9); c.rect(0, 0, c.w, c.h, (190, 190, 180)); c.rect(2, 4, c.w-4, 2, (80, 80, 90)); lineas_texto(c, 3, 10, c.w-8, 6, (110, 110, 120), 3, 8)
        s.decal(lado, a0, a1, 1.1, 2.0, c)
    for x in (-1.9, 0.0, 1.9):
        s.lampara(x, 5.5, 0.2, 1.4, (200, 225, 240), 0.5, radio=1.5)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(0, 0.9, D), 70, 50, (160, 200, 235), 0.45)
    lz.cono(160, int(s.p(0, 0, D)[1]), 179, 40, 130, (150, 190, 225), 0.3)
    s.zona_pantalla("vuelta", 138, 160, 44, 18)
    return lz.final(ambiente=1.4), s


# ---------------------------------------------------------------- PASILLO
def _rect_limpio():
    c = T(0.5, 1.0, 4); c.rect(0, 0, c.w, c.h, (70, 76, 86)); c.ruido(0, 0, c.w, c.h, 0.3, 0.2)
    c.rect(4, 12, c.w-8, c.h-30, (110, 120, 132)); c.rect(5, 13, 1, 1, (30, 30, 34)); c.rect(c.w-7, c.h-20, 1, 1, (30, 30, 34))
    return c

def pasillo():
    W, H, D = 2.8, 2.8, 9.0
    s = Sala(W, H, D, 1.55, 190, cy=84, seed=21, niebla=(3.0, 11.0, 0.65))
    col = (82, 90, 100)
    s.base(tex_pared(D, H, col, "panel", seed=1, junta=1.0, azulejo_h=1.1), tex_pared(D, H, col, "panel", seed=2, junta=1.0, azulejo_h=1.1),
           tex_pared(W, H, col, "panel", seed=3, junta=1.0, azulejo_h=1.1), tex_suelo(W, D, (60, 66, 74), seed=4, lado=0.5),
           tex_techo(W, D, (62, 66, 72)))
    # tubería superior a la izquierda
    t = T(D, 0.12); t.rect(0, 0, t.w, t.h, (96, 102, 108)); t.rect(0, 0, t.w, 1, (170, 176, 182)); t.rect(0, t.h-1, t.w, 1, (40, 44, 48))
    s.decal("I", 0.35, D, 2.45, 2.57, t); s.decal("D", 0.35, D, 2.45, 2.57, t)
    # puertas: izquierda (roja cerca, marrón lejos), fondo (marrón), derecha (roja)
    s.decal("I", 3.6, 4.55, 0, 2.1, tex_puerta(ROJO), m=2, zona="puerta_vigilancia")
    rw = ancho_rotulo_m("VIGILANCIA"); s.decal("I", 3.55, 3.55+rw, 2.25, 2.25+11/PPM, tex_rotulo("VIGILANCIA"))
    s.decal("I", 6.2, 7.0, 0, 2.1, tex_puerta(MARRON, w=0.8, cristal=(6, 8, 21, 30)), m=2, zona="puerta_bloq1")
    c = T(0.8, 0.9, 5); c.rect(0, 0, c.w, c.h, (170, 195, 212)); c.ruido(0, 0, c.w, c.h, 0.25, 0.15)
    for i in range(7):
        gx = 2+c.rng.randint(0, c.w-6); gy = 2+c.rng.randint(0, c.h//2); c.linea(gx, gy, gx, gy+c.rng.randint(2, 6), (230, 240, 248))
    s.decal("I", 6.28, 6.92, 0.95, 1.65, c)
    s.frontal(-0.45, 0.45, 0, 2.1, D, tex_puerta(MARRON), m=2, zona="puerta_bloq2")
    s.decal("D", 3.9, 4.85, 0, 2.1, tex_puerta(ROJO), m=2, zona="puerta_lab")
    rw = ancho_rotulo_m("LABORATORIO"); s.decal("D", 3.85, 3.85+rw, 2.25, 2.25+11/PPM, tex_rotulo("LABORATORIO"))
    s.decal("D", 6.0, 6.5, 0.9, 1.9, _rect_limpio())
    # extintor
    t = T(0.22, 0.6); t.rect(2, 8, t.w-4, t.h-8, (170, 30, 30)); t.rect(4, 2, t.w-8, 7, (40, 40, 40))
    s.decal("I", 5.2, 5.42, 0.9, 1.5, t)
    for z in (3.0, 6.0):
        s.lampara(0, z, 0.9, 0.22, (210, 230, 235), 0.5 if z < 5 else 0.38, radio=1.1)
    s.aplicar_luces()
    lz = s.componer()
    s.zona_pantalla("puerta_recepcion", 118, 158, 84, 22)
    return lz.final(ambiente=1.4), s

# ---------------------------------------------------------------- VIGILANCIA
def vigilancia():
    W, H, D = 5.0, 2.8, 6.5
    s = Sala(W, H, D, 1.5, 190, cy=84, seed=31, niebla=(2.5, 9.0, 0.55))
    col = (44, 50, 62)
    s.base(tex_pared(D, H, col, "panel", seed=1), tex_pared(D, H, col, "panel", seed=2), tex_pared(W, H, col, "panel", seed=3),
           tex_suelo(W, D, (28, 32, 40), seed=4), tex_techo(W, D, (34, 38, 46)))
    # puerta roja de entrada, pared izquierda
    s.decal("I", 3.0, 3.95, 0, 2.1, tex_puerta(ROJO), m=2, zona="puerta_pasillo")
    rw = ancho_rotulo_m("PASILLO"); s.decal("I", 2.95, 2.95+rw, 2.25, 2.25+11/PPM, tex_rotulo("PASILLO"))
    # ventana a la recepción (cristal unidireccional) sobre el escritorio
    s.frontal(-2.2, 1.0, 1.65, 2.65, D, tex_cristal(3.2, 1.0), zona="ventana")
    # escritorio con banco de monitores
    s.caja(-2.3, 1.0, 0, 0.8, 5.55, 6.4, (74, 76, 84), frente=tex_color(3.3, 0.8, (50, 52, 60)))
    verde = (60, 130, 90)
    for i in range(3):
        x0 = -2.2+i*1.0
        c = tex_crt(0.95, 0.72, verde if i < 2 else (22, 40, 30), carcasa=(70, 72, 76), lineas=False)
        w, h = c.w, c.h - 3
        if i == 0:      # laboratorio: mostrador al fondo y cuadro
            c.rect(7, h//2, w-14, 3, (40, 90, 64)); c.rect(7, h//2+3, w-14, 6, (28, 64, 46))
            c.rect(w//2-4, 9, 9, 7, (120, 200, 150)); c.borde(w//2-4, 9, 9, 7, (30, 70, 50))
        elif i == 1:    # pasillo: líneas de fuga
            cx, cy = w//2, h//2-2
            for (x1, y1) in [(7, 7), (w-8, 7), (7, h-9), (w-8, h-9)]:
                c.linea(x1, y1, cx-5 if x1 < cx else cx+5, cy-3 if y1 < cy else cy+3, (150, 220, 180))
            c.rect(cx-5, cy-3, 10, 6, (36, 80, 58))
        else:           # sin señal: nieve verde y negro
            for k in range(70):
                x = c.rng.randint(6, w-14); y = c.rng.randint(6, h-9)
                c.rect(x, y, c.rng.randint(2, 9), 1, (70, 170, 110) if k % 3 else (6, 10, 8))
            c.rect(6, h//2-1, w-12, 2, (90, 200, 130))
        s.frontal(x0, x0+0.95, 0.83, 1.55, 6.3, c)
    s.zona("monitores", [(-2.2, 1.55, 6.3), (0.75, 1.55, 6.3), (0.75, 0.83, 6.3), (-2.2, 0.83, 6.3)])
    # cuaderno verde sobre el escritorio
    t = T(0.4, 0.3); t.rect(0, 0, t.w, t.h, (28, 80, 56)); t.rect(2, 2, t.w-4, 1, (70, 140, 100)); t.rect(4, 6, t.w-8, 1, (210, 206, 190))
    s.horiz(0.45, 0.85, 5.7, 6.0, 0.803, t, zona="cuaderno")
    # archivero con cajones
    fr = T(0.9, 1.5, 14); fr.rect(0, 0, fr.w, fr.h, (86, 92, 100)); fr.rect(0, 0, 2, fr.h, (140, 148, 158)); fr.rect(0, 0, fr.w, 2, (150, 156, 166))
    for i in range(4):
        y = 3+i*14; fr.rect(3, y, fr.w-6, 12, (100, 106, 114)); fr.borde(3, y, fr.w-6, 12, (60, 64, 70))
        fr.rect(fr.w//2-6, y+3, 12, 4, (200, 200, 188)); fr.rect(fr.w//2-4, y+4, 8, 1, (80, 80, 84))
    s.caja(1.25, 2.15, 0, 1.5, 5.7, 6.4, (96, 102, 110), frente=fr, zona="archivero")
    # papeles en la pared
    c = T(0.3, 0.4); c.rect(0, 0, c.w, c.h, (208, 204, 188)); lineas_texto(c, 2, 3, 8, 4, (90, 90, 96), 3, 3)
    s.decal("D", 4.6, 4.9, 1.4, 1.8, c)
    c = T(0.5, 0.6); c.rect(0, 0, c.w, c.h, (214, 190, 120)); lineas_texto(c, 2, 3, 12, 3, (90, 70, 40), 3, 4)
    s.decal("D", 3.2, 3.7, 1.2, 1.8, c)
    # silla vacía no: Eric trae la suya
    s.lampara(0, 3.8, 0.9, 0.22, (170, 200, 230), 0.25, radio=1.2)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(-0.7, 1.5, 6.3), 60, 30, (80, 150, 140), 0.3)
    lz.foco(*s.p(-0.7, 2.1, 6.4), 50, 30, (100, 130, 170), 0.2)
    s.eric = {"pose": "sentado", "X": -0.6, "Z": 4.8, "alto_m": 1.35}
    return lz.final(ambiente=1.55, vineta=0.6), s

# ---------------------------------------------------------------- LABORATORIO
def laboratorio():
    W, H, D = 7.0, 3.0, 8.0
    s = Sala(W, H, D, 1.55, 190, cy=86, seed=41, niebla=(3.0, 11.0, 0.55))
    col = (58, 78, 72)
    s.base(tex_pared(D, H, col, "panel", seed=1, azulejo_h=1.3), tex_pared(D, H, col, "panel", seed=2, azulejo_h=1.3),
           tex_pared(W, H, col, "panel", seed=3, azulejo_h=1.3), tex_suelo(W, D, (40, 52, 50), seed=4, lado=0.5),
           tex_techo(W, D, (50, 62, 60)))
    # puerta roja a la oficina (única de la pared derecha)
    s.decal("D", 4.7, 5.65, 0, 2.1, tex_puerta(ROJO), m=2, zona="puerta_oficina")
    rw = ancho_rotulo_m("OFICINA"); s.decal("D", 4.65, 4.65+rw, 2.25, 2.25+11/PPM, tex_rotulo("OFICINA"))
    # armario / estantería de muestras (pared izquierda)
    c = T(1.7, 2.2, 16); c.rect(0, 0, c.w, c.h, (92, 100, 104)); c.rect(0, 0, 2, c.h, (150, 158, 160)); c.borde(0, 0, c.w, c.h, (50, 56, 58))
    for i in range(4):
        y = 6+i*int(c.h/4.2); c.rect(2, y+14, c.w-4, 2, (150, 158, 156))
        for j, col2 in enumerate([(120, 160, 90), (170, 150, 80), (90, 140, 170), (150, 90, 90), (160, 160, 160), (120, 160, 90)]):
            if (i+j) % 5 != 0:
                c.rect(5+j*10, y+4, 7, 10, mul(col2, 0.8)); c.rect(5+j*10, y+4, 7, 1, col2)
    s.decal("I", 4.8, 6.5, 0, 2.2, c, zona="armario")
    # cuadro (el clavo; el sprite lo pone el juego) sobre el mostrador del fondo
    c = T(0.12, 0.12); c.rect(0, 0, c.w, c.h, (180, 180, 170))
    s.frontal(0.25, 0.25+0.12, 2.75, 2.87, D, c)
    s.zona("cuadro", [(-0.55, 2.8, D), (1.05, 2.8, D), (1.05, 1.8, D), (-0.55, 1.8, D)])
    # mostrador largo del fondo
    fr = T(6.4, 1.0, 17); fr.rect(0, 0, fr.w, fr.h, (50, 58, 58))
    for x in range(0, fr.w, 52): fr.linea(x, 6, x, fr.h-1, (34, 40, 40))
    fr.rect(0, 0, fr.w, 5, (150, 158, 156)); fr.rect(0, 0, fr.w, 1, (210, 218, 214))
    for x in range(14, fr.w, 52): fr.rect(x, 18, 12, 2, (120, 128, 126))
    s.caja(-3.2, 3.2, 0, 1.0, 7.2, 8.0, (110, 118, 118), frente=fr)
    # archiveros en los extremos
    for x0 in (-3.45, 2.65):
        fr = T(0.8, 1.5, 18); fr.rect(0, 0, fr.w, fr.h, (92, 100, 104)); fr.borde(0, 0, fr.w, fr.h, (50, 56, 58))
        for i in range(4):
            y = 3+i*14; fr.borde(3, y, fr.w-6, 12, (60, 66, 68)); fr.rect(fr.w//2-5, y+4, 10, 3, (30, 30, 34))
        s.caja(x0, x0+0.8, 0, 1.5, 7.3, 8.0, (92, 100, 104), frente=fr)
    # terminal CRT grande (archivos) y ordenadores
    s.frontal(-0.55, 0.65, 1.0, 1.75, 7.9, tex_crt(1.2, 0.75, (34, 140, 82), carcasa=(118, 114, 100)), zona="terminal")
    s.frontal(-2.4, -1.7, 1.0, 1.5, 7.9, tex_crt(0.7, 0.5, (30, 100, 70)))
    s.frontal(1.5, 2.2, 1.0, 1.5, 7.9, tex_crt(0.7, 0.5, (26, 60, 100), lineas=False))
    # frasco sellado sobre el mostrador
    c = Lienzo(18, 30, 3); c.rect(2, 4, 14, 24, (120, 140, 150)); c.rect(3, 6, 12, 20, (36, 44, 48)); c.rect(3, 16, 12, 10, (118, 120, 118))
    c.rect(3, 16, 12, 2, (170, 172, 168)); c.rect(1, 0, 16, 5, (60, 64, 68)); c.rect(5, 20, 8, 4, (214, 210, 190)); c.rect(3, 6, 2, 20, (200, 220, 230))
    s.frontal(-1.35, -0.9, 1.0, 1.75, 7.9, recortar(c), zona="frasco")
    # mesa central de operaciones
    s.caja(-1.3, 1.3, 0, 0.9, 5.0, 6.6, (112, 120, 120))
    t = T(1.8, 1.0); t.rect(0, 0, t.w, t.h, (176, 180, 172)); t.linea(4, t.h//2, t.w-4, t.h//2, (160, 164, 156))
    for sx in (10, 34, 56): t.rect(sx, 4, 2, t.h-8, (60, 40, 30))
    s.horiz(-0.9, 0.9, 5.3, 6.3, 0.905, t)
    # casco neuronal sobre soporte, a la derecha
    s.caja(1.75, 2.05, 0, 0.9, 5.4, 5.7, (80, 86, 88))
    c = Lienzo(36, 34, 4); c.elipse(1, 2, 34, 28, (84, 90, 100)); c.elipse(3, 4, 30, 24, (60, 66, 76)); c.rect(1, 16, 34, 14, (20, 26, 30)); c.rect(1, 16, 34, 1, (110, 116, 126))
    for ex in (5, 12, 19, 26): c.rect(ex, 4, 3, 3, (210, 190, 90))
    s.frontal(1.45, 2.35, 0.9, 1.75, 5.45, recortar(c), zona="casco")
    for z in (3.0, 5.4):
        for x in (-1.8, 1.8):
            s.lampara(x, z, 0.9, 0.25, (190, 235, 215), 0.45, radio=1.4)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(0, 1.4, 7.9), 90, 40, (80, 220, 140), 0.28)
    s.zona_pantalla("volver", 118, 160, 84, 20)
    s.eric = {"pose": "de_espaldas", "X": -2.0, "Z": 4.4, "alto_m": 1.75}
    return lz.final(ambiente=1.5, vineta=0.6), s

# ---------------------------------------------------------------- OFICINA (sala 5)
def oficina():
    W, H, D = 5.0, 2.8, 6.5
    s = Sala(W, H, D, 1.5, 190, cy=84, seed=51, niebla=(2.5, 9.0, 0.5))
    col = (92, 80, 66)
    s.base(tex_pared(D, H, col, "panel", seed=1, zocalo=(60, 48, 38)), tex_pared(D, H, col, "panel", seed=2, zocalo=(60, 48, 38)),
           tex_pared(W, H, col, "panel", seed=3, zocalo=(60, 48, 38)), tex_suelo(W, D, (58, 48, 40), "madera", seed=4),
           tex_techo(W, D, (64, 56, 48)))
    # ventana al pasillo secreto (vista a la puerta morada)
    c = T(2.0, 1.0, 12); c.rect(0, 0, c.w, c.h, (60, 52, 44)); c.rect(3, 3, c.w-6, c.h-6, (20, 16, 28))
    x0, y0, x1, y1 = 3, 3, c.w-4, c.h-4
    cx, cy = c.w//2, c.h//2-1
    fx0, fx1, fy0, fy1 = cx-9, cx+9, cy-9, cy+10        # pared del fondo
    c.poli([(x0, y0), (x1, y0), (fx1, fy0), (fx0, fy0)], (62, 54, 78))     # techo
    c.poli([(x0, y1), (x1, y1), (fx1, fy1), (fx0, fy1)], (74, 64, 92))     # suelo
    c.poli([(x0, y0), (fx0, fy0), (fx0, fy1), (x0, y1)], (50, 42, 66))     # pared izquierda
    c.poli([(x1, y0), (fx1, fy0), (fx1, fy1), (x1, y1)], (50, 42, 66))     # pared derecha
    c.rect(fx0, fy0, fx1-fx0, fy1-fy0, (90, 78, 112))
    c.rect(cx-5, fy0+3, 10, fy1-fy0-3, (150, 70, 200)); c.rect(cx-5, fy0+3, 10, 1, (220, 170, 250))
    c.rect(cx+2, cy+3, 1, 2, (240, 220, 160))
    c.rect(cx-4, fy0+5, 8, 3, (30, 24, 40))
    c.rect(cx-6, fy1, 12, 3, (130, 100, 160))                              # luz sobre el suelo
    c.linea(cx-14, y0, cx-14, y0+1, (230, 220, 255)); c.rect(cx-6, y0, 12, 1, (230, 220, 255))   # lámpara
    c.linea(x0, y1, fx0, fy1, (90, 78, 112)); c.linea(x1, y1, fx1, fy1, (90, 78, 112))
    s.frontal(-2.1, -0.1, 1.45, 2.45, D, c, zona="ventana_secreta")
    # mostrador con documentos
    fr = T(2.5, 0.95, 13); fr.rect(0, 0, fr.w, fr.h, (78, 60, 44)); fr.rect(0, 0, fr.w, 4, (170, 150, 120)); fr.ruido(0, 0, fr.w, fr.h, 0.12, 0.15)
    for x in (32, 66): fr.linea(x, 5, x, fr.h-1, (56, 42, 30))
    s.caja(-2.3, 0.2, 0, 0.95, 5.7, 6.5, (120, 96, 72), frente=fr, zona="mostrador")
    for (x, z, w, d) in [(-1.9, 5.9, 0.5, 0.3), (-1.2, 5.85, 0.45, 0.3), (-0.5, 5.95, 0.55, 0.28)]:
        t = T(w, d); t.rect(0, 0, t.w, t.h, (228, 226, 212)); t.rect(0, 0, t.w, 1, (250, 248, 235))
        s.horiz(x, x+w, z, z+d, 0.955, t)
    # puerta azul sin picaporte en la pared del fondo
    s.frontal(1.05, 2.0, 0, 2.1, D, tex_puerta(AZUL, picaporte=False), m=2, zona="puerta_azul")
    # tablón de avisos en la pared izquierda (sin nada de la historia)
    c = T(1.5, 1.1, 13); c.rect(0, 0, c.w, c.h, (70, 54, 40)); c.rect(2, 2, c.w-4, c.h-4, (150, 112, 76)); c.ruido(2, 2, c.w-4, c.h-4, 0.15, 0.2)
    for (x, y, w, h, col) in [(6, 6, 16, 20, (225, 222, 208)), (28, 8, 14, 12, (214, 190, 120)), (46, 5, 10, 14, (200, 215, 225)), (8, 31, 20, 11, (225, 222, 208))]:
        c.rect(x, y, w, h, col); lineas_texto(c, x+2, y+3, w-5, max(1, (h-4)//3), (110, 110, 118), 3, x)
    c.rect(36, 30, 2, 2, (200, 30, 30))      # una chincheta sola, sin nada que sujetar
    s.decal("I", 3.6, 5.1, 1.0, 2.1, c, zona="tablero")
    # reloj y archivadores en la pared derecha
    c = Lienzo(22, 22, 3); reloj(c, 11, 11, 9, 10, 10)
    s.decal("D", 4.2, 4.75, 2.0, 2.55, c)
    fr = T(0.8, 1.3, 18); fr.rect(0, 0, fr.w, fr.h, (98, 86, 70)); fr.borde(0, 0, fr.w, fr.h, (60, 50, 40))
    for i in range(3):
        y = 3+i*16; fr.borde(3, y, fr.w-6, 14, (60, 50, 40)); fr.rect(fr.w//2-5, y+5, 10, 3, (30, 26, 22))
    s.caja(1.7, 2.5, 0, 1.3, 4.2, 5.0, (98, 86, 70), frente=fr)
    # lámpara de mesa
    c = Lienzo(14, 20, 3); c.rect(4, 9, 6, 10, (60, 62, 68)); c.rect(0, 2, 14, 7, (200, 160, 70))
    s.frontal(-0.15, 0.2, 0.95, 1.45, 6.3, recortar(c))
    s.lampara(-1.0, 3.6, 0.9, 0.25, (255, 220, 160), 0.45, radio=1.3)
    s.lampara(1.2, 3.6, 0.9, 0.25, (255, 220, 160), 0.35, radio=1.3)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(0.0, 1.4, 6.2), 40, 28, (255, 210, 120), 0.5)
    s.zona_pantalla("volver", 118, 160, 84, 20)
    s.eric = {"pose": "perfil", "X": 0.2, "Z": 4.6, "alto_m": 1.75}
    return lz.final(ambiente=1.5, vineta=0.6), s

# ---------------------------------------------------------------- HABITACIÓN (sala 5, interior)
def habitacion_secreta():
    W, H, D = 5.0, 2.8, 6.5
    s = Sala(W, H, D, 1.5, 160, cy=84, seed=61, niebla=(2.5, 9.0, 0.5))
    col = (84, 96, 92)
    s.base(tex_pared(D, H, col, "panel", seed=1, azulejo_h=2.8, zocalo=(50, 58, 56)), tex_pared(D, H, col, "panel", seed=2, azulejo_h=2.8, zocalo=(50, 58, 56)),
           tex_pared(W, H, col, "panel", seed=3, azulejo_h=2.8, zocalo=(50, 58, 56)), tex_suelo(W, D, (60, 64, 62), seed=4, lado=0.5),
           tex_techo(W, D, (74, 84, 80)))
    # puerta morada al pasillo (fondo, centrada)
    c = tex_puerta(MORADO, cristal=(8, 8, 19, 20))
    s.frontal(-0.48, 0.47, 0, 2.1, D, c, m=2, zona="puerta_morada")
    s.frontal(-0.7, -0.5, 0.9, 1.0, D, tex_color(0.2, 0.08, (230, 40, 40), borde=False))
    # reloj y calendario que no coinciden (pared del fondo)
    c = Lienzo(24, 24, 3); reloj(c, 12, 12, 10, 4, 47)
    s.frontal(-2.0, -1.4, 1.85, 2.45, D, c, zona="reloj")
    c = Lienzo(30, 38, 3); c.rect(0, 0, 30, 38, (216, 212, 196)); c.rect(0, 0, 30, 8, (170, 40, 40))
    c.texto_px(3, 2, "MAR", (240, 220, 220)); c.texto_px(11, 14, "3", (40, 40, 44), 3)
    s.frontal(1.2, 1.95, 1.7, 2.65, D, c, zona="calendario")
    # marcas rascadas (pared izquierda, sobre y detrás de la mesita)
    c = T(1.1, 0.5)
    c.rect(0, 0, c.w, c.h, (84, 96, 92))
    for i in range(14):
        x = 4+(i//5)*14+(i % 5)*2; c.linea(x, 6, x, 18, (40, 46, 44))
    for g in range(3): c.linea(2+g*14, 18, 12+g*14, 6, (40, 46, 44))
    s.decal("I", 4.4, 5.5, 1.1, 1.6, c)
    # cámara en el rincón derecho del fondo
    c = Lienzo(12, 8, 3); c.rect(0, 0, 12, 8, (30, 30, 34)); c.rect(2, 2, 4, 4, (200, 30, 30))
    s.decal("D", 5.6, 5.9, 2.4, 2.6, c)

    # ---- IZQUIERDA: mesita con utensilios y la ficha clínica
    fr = T(0.65, 0.85, 22); fr.rect(0, 0, fr.w, fr.h, (150, 156, 158)); fr.rect(0, 0, fr.w, 2, (214, 218, 220)); fr.borde(0, 0, fr.w, fr.h, (84, 90, 92))
    for y in (6, 20):
        fr.rect(3, y, fr.w-6, 12, (166, 172, 174)); fr.borde(3, y, fr.w-6, 12, (90, 96, 98)); fr.rect(fr.w//2-5, y+5, 10, 2, (60, 64, 66))
    tp = T(0.65, 0.6, 23); tp.rect(0, 0, tp.w, tp.h, (170, 176, 178)); tp.borde(0, 0, tp.w, tp.h, (110, 116, 118))
    tp.rect(3, 2, 8, 2, (90, 94, 98)); tp.rect(3, 6, 10, 1, (200, 204, 206))                          # pinzas y bisturí
    tp.rect(15, 3, 3, 6, (90, 130, 150)); tp.rect(15, 3, 3, 1, (210, 220, 226)); tp.rect(20, 2, 2, 8, (200, 200, 190))   # frasco, jeringa
    tp.rect(3, 12, 20, 11, (92, 66, 44)); tp.rect(4, 13, 18, 9, (226, 222, 204)); tp.rect(4, 13, 18, 3, (170, 40, 40)); tp.rect(10, 11, 6, 2, (150, 150, 156))   # ficha
    s.caja(-1.45, -0.8, 0.0, 0.85, 3.0, 3.6, (150, 156, 158), frente=fr, tapa=tp, zona="mesita")
    s.zona("ficha", [(-1.45, 0.85, 3.6), (-0.8, 0.85, 3.6), (-0.8, 0.85, 3.0), (-1.45, 0.85, 3.0)])

    # ---- IZQUIERDA: soporte con monitor de pulso y bolsa de gotero (un solo conjunto)
    c = Lienzo(36, 84, 3)
    PM = (150, 156, 158)
    c.rect(17, 6, 2, 72, PM)                                     # poste
    c.rect(6, 4, 24, 2, PM); c.rect(6, 2, 2, 3, PM); c.rect(28, 2, 2, 3, PM)   # brazo con ganchos
    c.rect(5, 78, 26, 2, PM); c.rect(3, 80, 3, 3, (90, 94, 96)); c.rect(30, 80, 3, 3, (90, 94, 96)); c.rect(16, 80, 4, 3, (90, 94, 96))
    c.rect(23, 6, 9, 17, (196, 218, 230)); c.rect(23, 6, 9, 2, (232, 242, 247)); c.rect(24, 9, 7, 6, (150, 190, 214))   # bolsa
    c.linea(27, 23, 27, 30, (196, 218, 230)); c.linea(27, 30, 20, 34, (196, 218, 230))
    c.rect(5, 33, 24, 17, (40, 42, 46)); c.borde(5, 33, 24, 17, (120, 126, 130)); c.rect(7, 35, 20, 11, (6, 18, 10))   # monitor
    for a_, b_ in zip([(7, 41), (11, 41), (13, 36), (15, 45), (17, 39), (19, 41), (27, 41)], [(11, 41), (13, 36), (15, 45), (17, 39), (19, 41), (27, 41), (27, 41)]):
        c.linea(a_[0], a_[1], b_[0], b_[1], (80, 255, 120))
    c.rect(8, 47, 4, 2, (200, 40, 40)); c.rect(14, 47, 3, 2, (220, 190, 60))
    c.linea(24, 50, 24, 62, (196, 218, 230)); c.rect(23, 62, 3, 2, (196, 218, 230))     # tubo que cuelga sin aguja
    s.frontal(-2.45, -1.55, 0.0, 2.1, 2.6, recortar(c))
    X0, Y1 = -2.45, 2.1
    def zr(px0, py0, px1, py1, Z=2.6):
        return [(X0+px0/PPM, Y1-py0/PPM, Z), (X0+px1/PPM, Y1-py0/PPM, Z), (X0+px1/PPM, Y1-py1/PPM, Z), (X0+px0/PPM, Y1-py1/PPM, Z)]
    s.zona("monitor_pulso", zr(5, 33, 29, 50))
    s.zona("gotero", zr(22, 5, 33, 24))

    # ---- DERECHA: camilla con el largo hacia el fondo (cabeza al fondo)
    zc0, zc1, xc0, xc1 = 2.1, 4.3, 1.35, 2.35
    fr = T(1.0, 0.85, 20); fr.rect(0, 0, fr.w, fr.h, (14, 16, 18)); fr.rect(0, 0, fr.w, 12, (96, 102, 104)); fr.rect(0, 0, fr.w, 2, (190, 196, 198))
    for lx in (4, fr.w-8): fr.rect(lx, 12, 4, fr.h-12, (80, 86, 88))
    lado = T(2.2, 0.85, 24); lado.rect(0, 0, lado.w, lado.h, (14, 16, 18)); lado.rect(0, 0, lado.w, 12, (96, 102, 104)); lado.rect(0, 0, lado.w, 2, (190, 196, 198))
    for lx in (4, lado.w-8): lado.rect(lx, 12, 4, lado.h-12, (80, 86, 88))
    lado.rect(8, 20, lado.w-16, 2, (60, 64, 66))
    tp = T(1.0, 2.2, 25); tp.rect(0, 0, tp.w, tp.h, (174, 178, 168)); tp.rect(0, 0, tp.w, 2, (150, 154, 146))
    tp.rect(5, 3, 30, 16, (206, 210, 204)); tp.rect(5, 3, 30, 2, (230, 234, 228))                  # almohada
    tp.elipse(8, 32, 24, 36, (150, 154, 146)); tp.elipse(11, 36, 18, 28, (140, 144, 136))           # hueco donde estuvo
    tp.rect(0, 62, tp.w, 1, (146, 150, 142)); tp.rect(0, 22, tp.w, 1, (190, 194, 186))
    tp.rect(0, 40, 3, 22, (50, 44, 40)); tp.rect(tp.w-3, 28, 3, 20, (50, 44, 40))                   # correas sueltas
    s.caja(xc0, xc1, 0.0, 0.85, zc0, zc1, (96, 102, 104), frente=fr, lado=lado, tapa=tp)
    s.zona("camilla", [(xc0, 0.85, zc1), (xc1, 0.85, zc1), (xc1, 0.0, zc0), (xc0, 0.0, zc0)])

    s.lampara(0, 3.6, 1.1, 0.28, (210, 235, 220), 0.55, radio=1.8)
    s.lampara(-1.8, 2.4, 0.7, 0.2, (210, 235, 220), 0.12, apagada=True)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(1.8, 0.9, 3.4), 40, 24, (220, 240, 225), 0.15)
    lz.foco(*s.p(-2.0, 1.4, 2.6), 14, 12, (80, 255, 120), 0.3)
    s.eric = {"pose": "tumbado", "X": 1.8, "Z": 2.3, "Y": 0.9, "alto_m": 0.5}
    return lz.final(ambiente=1.5, vineta=0.6), s

# ---------------------------------------------------------------- PASILLO SALA 5 (tras salir de la habitación)
def pasillo_alterado():
    W, H, D = 5.0, 2.8, 5.4          # mismo ancho que la oficina: es el mismo tramo de la sala 5
    s = Sala(W, H, D, 1.5, 190, cy=84, seed=22, niebla=(2.5, 8.0, 0.55), color_niebla=(12, 10, 8))
    col = (92, 92, 66)
    s.base(tex_pared(D, H, col, "panel", seed=1, azulejo_h=2.8, zocalo=(52, 52, 38), manchas=14), tex_pared(D, H, col, "panel", seed=2, azulejo_h=2.8, zocalo=(52, 52, 38), manchas=14),
           tex_pared(W, H, col, "panel", seed=3, azulejo_h=2.8, zocalo=(52, 52, 38)), tex_suelo(W, D, (52, 50, 44), seed=4, lado=0.5),
           tex_techo(W, D, (62, 60, 50)))
    # muro divisorio con la oficina, visto desde este lado (la oficina lo ve espejado):
    # oficina: ventana x -2.1..-0.1 y puerta azul x 1.05..2.0  ->  aquí: ventana x 0.1..2.1 y puerta x -2.0..-1.05
    s.frontal(-2.0, -1.05, 0, 2.1, D, tex_puerta(AZUL, picaporte=False), m=2, zona="puerta_azul")
    c = T(2.0, 1.0, 12); c.rect(0, 0, c.w, c.h, (110, 100, 70)); c.rect(3, 3, c.w-6, c.h-6, (14, 12, 18)); c.linea(3, c.h-4, c.w//2, 3, (40, 38, 50))
    s.frontal(0.1, 2.1, 1.45, 2.45, D, c, zona="ventana")
    # placa 14-B en la pared derecha
    c = T(0.95, 0.4, 3); c.rect(0, 0, c.w, c.h, (90, 84, 60)); c.borde(0, 0, c.w, c.h, (160, 150, 110)); c.texto_px(c.w//2-15, 4, "14-B", (230, 225, 190), 2)
    s.decal("D", 3.4, 4.35, 1.65, 2.05, c, zona="placa")
    # huellas azules hacia la puerta azul
    for i in range(10):
        z = 3.0+i*0.22; x = 0.25-i*0.16+(0.15 if i % 2 else -0.15)
        t = T(0.3, 0.55, 3); t.elipse(1, 4, t.w-2, t.h-8, (22, 34, 66)); t.elipse(2, 6, t.w-4, t.h-12, (70, 110, 190))
        s.horiz(x-0.15, x+0.15, z, z+0.55, 0.006, recortar(t))
    s.zona("huellas", [(-1.5, 0, 5.2), (-0.75, 0, 5.2), (0.6, 0, 2.9), (-0.2, 0, 2.9)])
    s.lampara(0, 2.4, 1.0, 0.22, (230, 225, 160), 0.45, radio=1.3)
    s.lampara(0, 4.2, 1.0, 0.22, (230, 225, 160), 0.2, apagada=True)
    s.aplicar_luces()
    lz = s.componer()
    s.zona_pantalla("puerta_morada", 118, 160, 84, 20)
    return lz.final(ambiente=1.4, tinte=(1.0, 0.95, 0.8)), s

# ---------------------------------------------------------------- PASILLO SECRETO (visto por la ventana desde la oficina)
def pasillo_secreto():
    W, H, D = 3.2, 2.8, 4.2
    s = Sala(W, H, D, 1.5, 165, cy=58, tam=(220, 130), seed=71, niebla=(3.0, 9.0, 0.3), color_niebla=(20, 12, 28))
    col = (86, 72, 106)
    s.base(tex_pared(D, H, col, "panel", seed=1, azulejo_h=1.1), tex_pared(D, H, col, "panel", seed=2, azulejo_h=1.1),
           tex_pared(W, H, col, "panel", seed=3, azulejo_h=1.1), tex_suelo(W, D, (62, 54, 76), seed=4, lado=0.5),
           tex_techo(W, D, (62, 56, 76)))
    s.frontal(-0.5, 0.5, 0, 2.1, D, tex_puerta(MORADO), m=2, zona="puerta_morada")
    c = T(0.8, 0.4, 3); c.rect(0, 0, c.w, c.h, (150, 146, 168)); c.borde(0, 0, c.w, c.h, (70, 62, 90))
    s.frontal(-0.4, 0.4, 2.2, 2.55, D, c, zona="placa")
    s.lampara(0, 1.6, 0.9, 0.22, (200, 185, 240), 0.5, radio=1.6)
    s.lampara(0, 3.4, 0.9, 0.22, (200, 185, 240), 0.35, radio=1.6)
    s.aplicar_luces()
    lz = s.componer()
    lz.foco(*s.p(0, 1.0, D), 40, 50, (190, 110, 240), 0.45)
    return lz.final(ambiente=1.45, vineta=0.5), s

TODAS = {"recepcion": recepcion, "recepcion_reverso": recepcion_reverso, "pasillo": pasillo, "vigilancia": vigilancia,
         "laboratorio": laboratorio, "oficina": oficina, "habitacion_secreta": habitacion_secreta,
         "pasillo_alterado": pasillo_alterado, "pasillo_secreto": pasillo_secreto}

if __name__ == "__main__":
    import sys
    nombres = sys.argv[1:] or list(TODAS)
    for n in nombres:
        im, s = TODAS[n](); im.save(f"p3_{n}.png"); print(n, "ok")
