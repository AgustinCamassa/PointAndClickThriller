"""Importa los fondos fotorrealistas (originales aportados por el autor) y genera todos los assets derivados.

Uso:  python3 importar_fondos.py CARPETA_ORIGINALES [CARPETA_ASSETS]
CARPETA_ORIGINALES debe contener (PNG ~1672x941, la recepción_reverso panorámica 2172x724):
  recepcion, recepcion_reverso, pasillo, pasillo_alterado, pasillo_secreto, laboratorio, oficina,
  habitacion_secreta (opcional: hab_tumbada y hab_sentada la sustituyen), vigilancia, ventana_recepcion (.png)
Genera en assets/fondos: los fondos a 1280x720, cam_1 y cam_2 (filtro verde) y los monitores de Vigilancia.
Retoques: recepción panorámica -> 16:9, placas VIG-01/LAB-04 del pasillo (las puertas conservan su color
original), huellas del pasillo alterado, pantallas de los monitores (laboratorio, pasillo y "sin señal" con
filtro verde) y plantas borradas de la puerta doble de la vista de la ventana.
Requiere Pillow, numpy y opencv-python.
"""
import sys, os
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf"
W, H = 1280, 720
VERDE_BGR = np.array([0.82, 1.0, 0.38], np.float32)  # tono de los monitores del render de Vigilancia


def cargar(carpeta, nombre):
    return cv2.imread(os.path.join(carpeta, nombre + ".png"))


def a1280(img):
    return cv2.resize(img, (W, H), interpolation=cv2.INTER_AREA)


# --- recepción panorámica -> 16:9 -------------------------------------------------------------------
def recepcion_reverso(img):
    """Recorta el marco de la ventana, toma 1300 px centrados en las puertas y estira solo techo y suelo."""
    x_i, y_i0, y_i1, cx, ancho = 88, 84, 644, 1085, 1300
    alto16 = round(ancho * 9 / 16)
    y_techo, y_suelo = 230, 520
    x0 = cx - ancho // 2
    c = img[y_i0:y_i1, x0:x0 + ancho]
    t, m, s = c[:y_techo - y_i0], c[y_techo - y_i0:y_suelo - y_i0], c[y_suelo - y_i0:]
    extra = alto16 - c.shape[0]
    nt = round(t.shape[0] + extra * t.shape[0] / (t.shape[0] + s.shape[0]))
    ns = alto16 - m.shape[0] - nt
    out = np.vstack([cv2.resize(t, (ancho, nt), interpolation=cv2.INTER_LANCZOS4), m,
                     cv2.resize(s, (ancho, ns), interpolation=cv2.INTER_LANCZOS4)])
    return a1280(out)


# --- placas del pasillo -----------------------------------------------------------------------------
def texto_placa(img, quad, texto, blur=0.8):
    """Borra las letras claras dentro del cuadrilátero (TL,TR,BR,BL) y escribe `texto` en perspectiva."""
    quad = np.array(quad, np.float32)
    h, w = img.shape[:2]
    m = np.zeros((h, w), np.uint8)
    c = quad.mean(0)
    cv2.fillConvexPoly(m, ((quad - c) * 1.12 + c).astype(np.int32), 255)
    g = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32)
    gm = cv2.cvtColor(cv2.medianBlur(img, 21), cv2.COLOR_BGR2GRAY).astype(np.float32)
    letras = ((g > gm + 14) & (m > 0)).astype(np.uint8) * 255
    letras = cv2.dilate(letras, np.ones((5, 5), np.uint8), iterations=2) & m
    limpio = cv2.inpaint(img, letras, 5, cv2.INPAINT_TELEA)
    mq = np.zeros((h, w), np.uint8)
    cv2.fillConvexPoly(mq, quad.astype(np.int32), 255)
    gg = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    col = img[(gg >= np.percentile(gg[mq > 0], 98)) & (mq > 0)].mean(0)
    can = Image.new("L", (800, 224), 0)
    d = ImageDraw.Draw(can)
    f = ImageFont.truetype(FONT_B, 200)
    bb = d.textbbox((0, 0), texto, font=f)
    d.text(((800 - (bb[2] - bb[0])) / 2 - bb[0], (224 - (bb[3] - bb[1])) / 2 - bb[1]), texto, font=f, fill=255)
    a = np.array(can)
    ys, xs = np.where(a > 0)
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    th, tw = a.shape
    M = cv2.getPerspectiveTransform(np.float32([[0, 0], [tw, 0], [tw, th], [0, th]]), quad)
    wa = cv2.warpPerspective(a, M, (w, h), flags=cv2.INTER_AREA).astype(np.float32) / 255
    wa = cv2.GaussianBlur(wa, (0, 0), blur)[..., None]
    return (limpio * (1 - wa) + col * wa).clip(0, 255).astype(np.uint8)


def pasillo(orig):
    def q(o, pts, z=4):
        return [(o[0] + x / z, o[1] + y / z) for x, y in pts]
    q1 = q((306, 91), [(160, 88), (392, 236), (358, 343), (158, 224)])
    q4 = q((1174, 104), [(98, 288), (326, 158), (304, 302), (106, 428)])
    # Las coordenadas son del original 1671x941
    esc = orig.shape[1] / 1671.0
    q1 = [(x * esc, y * esc) for x, y in q1]
    q4 = [(x * esc, y * esc) for x, y in q4]
    o = texto_placa(orig, q1, "VIG-01")
    o = texto_placa(o, q4, "LAB-04")
    return a1280(o)


# --- plantas de la vista de la ventana ---------------------------------------------------------------
def rellenar_columnas(img, x0, x1, ya, yb, grano, semilla=1, amp=0.5):
    """Rellena el rectángulo [x0,x1)x[ya,yb) interpolando cada columna entre la fila de arriba y la de abajo
    (el fondo son paneles verticales) y añade el grano de una zona limpia `grano` = (x0,y0,x1,y1)."""
    f = img.astype(np.float32)
    out = f.copy()

    def perfil(r0, r1):
        p = f[r0:r1].mean(0)[None]
        return cv2.GaussianBlur(p, (0, 0), sigmaX=2.5, sigmaY=0.1)[0]
    arriba, abajo = perfil(ya - 6, ya - 1), perfil(yb, yb + 5)
    h = yb - ya
    t = np.linspace(0, 1, h)[:, None, None]
    t = t * t * (3 - 2 * t)
    bloque = arriba[None, x0:x1] * (1 - t) + abajo[None, x0:x1] * t
    gx0, gy0, gx1, gy1 = grano
    g = f[gy0:gy1, gx0:gx1]
    hp = np.clip(g - cv2.GaussianBlur(g, (0, 0), 3), -10, 10)
    gg = np.zeros((h, x1 - x0, 3), np.float32)
    for yy in range(0, h, hp.shape[0]):
        for xx in range(0, x1 - x0, hp.shape[1]):
            p = hp[:h - yy, :x1 - x0 - xx]
            gg[yy:yy + p.shape[0], xx:xx + p.shape[1]] = p
    relleno = bloque + gg * amp
    m = np.zeros((h, x1 - x0), np.float32)
    m[3:-3, 2:-1] = 1.0
    m = cv2.GaussianBlur(m, (0, 0), 1.8)[..., None]
    out[ya:yb, x0:x1] = f[ya:yb, x0:x1] * (1 - m) + relleno * m
    return np.clip(out, 0, 255).astype(np.uint8)


def ventana_recepcion(img):
    """Borra las plantas que se ven tras la puerta doble de la derecha (coordenadas del original 1672x941)."""
    esc = img.shape[1] / 1672.0
    base = cv2.resize(img, (1672, 941), interpolation=cv2.INTER_AREA) if esc != 1 else img
    o = rellenar_columnas(base, 1602, 1654, 452, 532, (1602, 372, 1654, 402))   # hojas
    o = rellenar_columnas(o, 1602, 1646, 562, 618, (1602, 650, 1646, 690), 2)   # maceta
    return a1280(o)


# --- huellas del pasillo alterado --------------------------------------------------------------------
def huellas(img):
    capa = np.zeros((H, W), np.float32)
    n = 8
    for i in range(n):
        t = i / (n - 1)
        y = 690 - t * (690 - 505)
        x = 705 - t * (705 - 530) + (14 if i % 2 else -14) * (1 - t * 0.7)
        k = 1.0 - t * 0.62
        cv2.ellipse(capa, (int(x), int(y)), (int(15 * k), int(7.5 * k)), 8, 0, 360, 1.0, -1)
        cv2.ellipse(capa, (int(x + 2 * k), int(y + 8 * k)), (int(9 * k), int(4 * k)), 8, 0, 360, 1.0, -1)
    capa = cv2.GaussianBlur(capa, (0, 0), 1.3)
    borde = np.clip(cv2.GaussianBlur(capa, (0, 0), 3.0) - capa, 0, 1)[..., None] * 95  # brillo del agua en el borde
    capa = capa[..., None]
    base = img.astype(np.float32) * (1 - capa * 0.92) + borde * np.array([1.0, 0.95, 0.85], np.float32)
    return base.clip(0, 255).astype(np.uint8)


# --- placa 14-B ------------------------------------------------------------------------------------
def placa_14b(img):
    """Dibuja la placa «14-B» sobre la puerta azul del pasillo alterado."""
    x0, y0, x1, y1 = 479, 267, 563, 292
    pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    cap = Image.new("RGB", (x1 - x0, y1 - y0), (26, 29, 28))
    d = ImageDraw.Draw(cap)
    d.rectangle([0, 0, cap.width - 1, cap.height - 1], outline=(92, 100, 94))
    f = ImageFont.truetype(FONT_B, 15)
    bb = d.textbbox((0, 0), "14-B", font=f)
    d.text(((cap.width - (bb[2] - bb[0])) / 2 - bb[0], (cap.height - (bb[3] - bb[1])) / 2 - bb[1]), "14-B", font=f, fill=(186, 192, 176))
    a = np.array(cap).astype(np.float32)
    a = cv2.GaussianBlur(a, (0, 0), 0.6)
    pil.paste(Image.fromarray(a.astype(np.uint8)), (x0, y0))
    out = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
    # sombra suave bajo la placa para integrarla
    return out


# --- filtro verde de cámaras y monitores ----------------------------------------------------------
def verde(img, ganancia=1.0):
    g = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32)
    g = g / max(np.percentile(g, 99.5), 1.0)
    g = np.clip(g, 0, 1) ** 0.75 * ganancia
    out = np.clip(g[..., None] * VERDE_BGR * 235, 0, 255)
    out[::3] *= 0.82  # líneas de barrido
    return out.astype(np.uint8)


def vignette(img, fuerza=0.45):
    h, w = img.shape[:2]
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    r = np.sqrt(((x - w / 2) / (w / 2)) ** 2 + ((y - h / 2) / (h / 2)) ** 2)
    return (img * (1 - fuerza * np.clip(r - 0.4, 0, 1)[..., None])).astype(np.uint8)


def feed_camara(fondo, caja, tam=(1056, 526)):
    x0, y0, x1, y1 = caja
    c = fondo[y0:y1, x0:x1]
    c = cv2.resize(c, tam, interpolation=cv2.INTER_AREA)
    return vignette(verde(c))


PANTALLAS = [(396, 328, 525, 412), (542, 328, 668, 411), (688, 328, 817, 410)]  # monitores del render (1280x720)


def pantallas_vigilancia(img, feed1, feed2):
    """Pega los dos feeds (verdes) y una 'sin señal' en los tres monitores de la sala de vigilancia."""
    out = img.copy()
    rng = np.random.default_rng(3)
    for i, (x0, y0, x1, y1) in enumerate(PANTALLAS):
        w, h = x1 - x0, y1 - y0
        if i < 2:
            p = cv2.resize([feed1, feed2][i], (w, h), interpolation=cv2.INTER_AREA)
        else:
            p = np.clip(rng.normal(60, 38, (h, w)), 0, 255).astype(np.uint8)
            p = cv2.GaussianBlur(p, (0, 0), 0.7)
            p = np.dstack([p * VERDE_BGR[0], p * VERDE_BGR[1], p * VERDE_BGR[2]]).clip(0, 255).astype(np.uint8)
        pil = Image.fromarray(cv2.cvtColor(p, cv2.COLOR_BGR2RGB))
        d = ImageDraw.Draw(pil)
        f = ImageFont.truetype(FONT_B, 9)
        d.text((4, 3), "CAM 0%d" % (i + 1), font=f, fill=(150, 255, 205))
        if i == 2:
            d.text((w // 2 - 24, h // 2 - 5), "SIN SEÑAL", font=f, fill=(170, 255, 215))
        else:
            d.text((w - 46, h - 12), "02:37:16", font=f, fill=(150, 255, 205))
        p = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR).astype(np.float32)
        out[y0:y1, x0:x1] = np.clip(p * 0.95, 0, 255).astype(np.uint8)
    resp = np.zeros((H, W), np.float32)
    for x0, y0, x1, y1 in PANTALLAS:
        resp[y0 - 6:y1 + 6, x0 - 6:x1 + 6] = 1.0
    resp = cv2.GaussianBlur(resp, (0, 0), 14)[..., None] * VERDE_BGR * 22
    return np.clip(out.astype(np.float32) + resp, 0, 255).astype(np.uint8)


# --- principal --------------------------------------------------------------------------------------
def main(orig, dest):
    os.makedirs(dest, exist_ok=True)

    def guardar(nombre, img):
        cv2.imwrite(os.path.join(dest, nombre + ".png"), img, [cv2.IMWRITE_PNG_COMPRESSION, 9])
        print("  ", nombre, img.shape[1], "x", img.shape[0])

    recepcion = a1280(cargar(orig, "recepcion"))
    reverso = recepcion_reverso(cargar(orig, "recepcion_reverso"))
    pas = pasillo(cargar(orig, "pasillo"))
    lab = a1280(cargar(orig, "laboratorio"))
    ofi = a1280(cargar(orig, "oficina"))
    # habitación secreta: con Alicia tumbada bajo la sábana (inicio) y sentada en la camilla (al despertar)
    hab = a1280(cargar(orig, "hab_tumbada"))
    hab_sentada = a1280(cargar(orig, "hab_sentada"))
    alt = a1280(cargar(orig, "pasillo_alterado"))
    alt = huellas(alt)
    # (sin placa: el número del caso no se ve en ninguna puerta ni pasillo)
    sec = a1280(cargar(orig, "pasillo_secreto"))
    ventana = ventana_recepcion(cargar(orig, "ventana_recepcion"))
    feed1 = feed_camara(lab, (80, 60, 1200, 620))
    feed2 = feed_camara(pas, (0, 40, 1280, 680))
    vig = pantallas_vigilancia(a1280(cargar(orig, "vigilancia")), feed1, feed2)
    for n, i in [("recepcion", recepcion), ("recepcion_reverso", reverso), ("pasillo", pas), ("laboratorio", lab),
                 ("oficina", ofi), ("habitacion_secreta", hab), ("pasillo_alterado", alt), ("pasillo_secreto", sec),
                 ("vigilancia", vig), ("cam_1", feed1), ("cam_2", feed2), ("habitacion_secreta_sentada", hab_sentada),
                 ("ventana_recepcion", ventana)]:
        guardar(n, i)


if __name__ == "__main__":
    carpeta = sys.argv[1]
    destino = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "fondos")
    main(carpeta, destino)
