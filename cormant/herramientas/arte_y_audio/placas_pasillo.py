"""Placas de las puertas del pasillo principal (carteles sobre las puertas).

Tres versiones, todas sobre la misma imagen de partida:
  - normal (`pasillo`):          VIG · (ilegible) · ACCESO · LAB   (sin números)
  - macabra (`pasillo_macabro`): las cuatro placas rasguñadas, ilegibles (modos 1 y 2, anomalía de la mancha)
  - macabra con frase (la frase se escribe palabra a palabra en las placas, de izquierda a derecha: Vigilancia, puerta pequeña, puerta del fondo, Laboratorio):
      `pasillo_macabro_haces`  SABES · LO · QUE · HACES   (modo 1, mancha con compatibilidad >= 80 % tras una muerte)  + «aquí» en el cuadro
      `pasillo_macabro_quieres` NO · HACES · LO · QUE     (modo 2, misma condición)                                    + «quieres» en el cuadro
      `pasillo_macabro_m3_eres` NO · ERES · QUIEN · CREES (modo 3, primera anomalía)                                   + «ser» en el cuadro
      `pasillo_macabro_m3`      SABES · LO · QUE · PASÓ   (modo 3, al solicitar el 3.er glifo)
      `pasillo_macabro_m3_previo` carteles normales sobre la base macabra (modo 3, antes de cualquier frase)

Las placas se editan en el espacio de una placa «plana» (lienzo CW x CH) y se pasan a la imagen con la perspectiva de cada una,
así los rasguños y las letras siguen la inclinación del cartel. Los cuadriláteros (TL, TR, BR, BL) son el interior de cada placa, dentro
del marco, medidos sobre las imágenes de 1280x720.

Uso:  python3 placas_pasillo.py            -> regenera pasillo_macabro*.png desde `base/pasillo_macabro_base.png`
(la normal la genera importar_fondos.py, que importa este módulo). Después hay que ejecutar fondos_apagon.py.
Requiere numpy, opencv-python y Pillow.
"""
import os
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
AQUI = os.path.dirname(os.path.abspath(__file__))

# Interior de cada placa (TL, TR, BR, BL) en el espacio 1280x720, y proporción real (ancho/alto) de la placa plana.
PLACAS_NORMAL = [
    ([(251, 67), (318, 113), (318, 152), (250, 112)], 2.6),     # 1: puerta de Vigilancia
    ([(424, 203), (456, 226), (456, 251), (424, 234)], 2.3),    # 2: puerta pequeña (la de la derecha de Vigilancia)
    ([(589, 262), (666, 262), (666, 283), (589, 283)], 3.7),    # 3: puerta del fondo
    ([(910, 137), (973, 91), (977, 140), (909, 176)], 2.6),     # 4: puerta del laboratorio
]
# En el fondo macabro las placas están en otro sitio (otro encuadre).
PLACAS_MACABRO = [
    ([(265, 62), (347, 119), (347, 162), (264, 113)], 2.6),
    ([(442, 204), (473, 227), (473, 252), (441, 233)], 2.3),
    ([(601, 261), (681, 261), (681, 280), (601, 280)], 4.0),
    ([(949, 134), (1030, 75), (1030, 128), (949, 172)], 2.6),
]
FRASE_MODO3 = ["SABES", "LO", "QUE", "PASÓ"]   # de izquierda a derecha: Vigilancia, puerta pequeña, puerta del fondo, Laboratorio
FRASE_HACES = ["SABES", "LO", "QUE", "HACES"]   # modo 1
FRASE_QUIERES = ["NO", "HACES", "LO", "QUE"]    # modo 2
FRASE_ERES = ["NO", "ERES", "QUIEN", "CREES"]   # modo 3 (a la vez se escribe «ser» en el cuadro)
TEXTOS_NORMAL = ["VIG", None, "ACCESO", "LAB"]  # None = ilegible

CH = 160   # alto del lienzo plano de cada placa


def _cuadro(quad):
    return np.array(quad, np.float32)


def borrar_letras(img, quad, umbral=12):
    """Borra lo claro (las letras) del interior de la placa rellenándolo con el entorno."""
    h, w = img.shape[:2]
    q = _cuadro(quad)
    c = q.mean(0)
    m = np.zeros((h, w), np.uint8)
    cv2.fillConvexPoly(m, ((q - c) * 0.96 + c).astype(np.int32), 255)
    g = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32)
    gm = cv2.cvtColor(cv2.medianBlur(img, 21), cv2.COLOR_BGR2GRAY).astype(np.float32)
    letras = ((g > gm + umbral) & (m > 0)).astype(np.uint8) * 255
    letras = cv2.dilate(letras, np.ones((5, 5), np.uint8), iterations=2) & m
    return cv2.inpaint(img, letras, 5, cv2.INPAINT_TELEA)


def color_letra(img, quad):
    q = _cuadro(quad)
    mq = np.zeros(img.shape[:2], np.uint8)
    cv2.fillConvexPoly(mq, q.astype(np.int32), 255)
    gg = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    return img[(gg >= np.percentile(gg[mq > 0], 98)) & (mq > 0)].mean(0)


def _lienzo(aspecto):
    cw = int(CH * aspecto)
    return cw, CH


def _texto(texto, cw, ch, alto_rel=0.56, ancho_max=0.86):
    """Alfa (0..1) del texto centrado en el lienzo plano, con la proporción real de la fuente."""
    can = Image.new("L", (cw * 2, ch * 2), 0)
    d = ImageDraw.Draw(can)
    tam = int(ch * 2 * alto_rel * 1.35)
    f = ImageFont.truetype(FONT_B, tam)
    bb = d.textbbox((0, 0), texto, font=f)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    k = min(1.0, cw * 2 * ancho_max / tw)
    if k < 1.0:
        f = ImageFont.truetype(FONT_B, int(tam * k))
        bb = d.textbbox((0, 0), texto, font=f)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
    d.text(((cw * 2 - tw) / 2 - bb[0], (ch * 2 - th) / 2 - bb[1]), texto, font=f, fill=255)
    return cv2.resize(np.array(can), (cw, ch), interpolation=cv2.INTER_AREA).astype(np.float32) / 255


def _poner(img, quad, cw, ch, alfa_claro, alfa_oscuro, col, blur=0.7):
    """Pasa los dos mapas del lienzo plano a la imagen con la perspectiva de la placa y los compone."""
    h, w = img.shape[:2]
    M = cv2.getPerspectiveTransform(np.float32([[0, 0], [cw, 0], [cw, ch], [0, ch]]), _cuadro(quad))
    mq = np.zeros((h, w), np.uint8)
    cv2.fillConvexPoly(mq, _cuadro(quad).astype(np.int32), 255)
    mq = cv2.erode(mq, np.ones((3, 3), np.uint8)).astype(np.float32)[..., None] / 255
    al = cv2.warpPerspective(alfa_claro, M, (w, h), flags=cv2.INTER_AREA)
    ao = cv2.warpPerspective(alfa_oscuro, M, (w, h), flags=cv2.INTER_AREA)
    al = cv2.GaussianBlur(al, (0, 0), blur)[..., None] * mq
    ao = cv2.GaussianBlur(ao, (0, 0), blur)[..., None] * mq
    out = img.astype(np.float32)
    out = out * (1 - ao) + out * 0.35 * ao
    out = out * (1 - al) + np.array(col, np.float32) * al
    return out.clip(0, 255).astype(np.uint8)


def escribir(img, quad, aspecto, texto, desgaste=0.0, semilla=0, brillo=1.0):
    """Borra lo que hubiera en la placa y escribe `texto` legible, con la proporción correcta de la letra.
    `desgaste` (0..1) le quita trozos y le pasa unos pocos arañazos, como pintura vieja."""
    limpio = borrar_letras(img, quad)
    col = np.clip(color_letra(img, quad) * 0.95 * brillo, 0, 255)
    cw, ch = _lienzo(aspecto)
    a = _texto(texto, cw, ch)
    oscuro = np.zeros_like(a)
    if desgaste > 0:
        r = np.random.RandomState(semilla)
        ruido = cv2.GaussianBlur(r.rand(ch, cw).astype(np.float32), (0, 0), 2.2)
        ruido = (ruido - ruido.min()) / (ruido.max() - ruido.min())
        a *= np.clip(1.15 - desgaste * (ruido > 0.62) * 1.6, 0, 1)
        for _ in range(int(3 + 6 * desgaste)):
            x0, y0 = r.randint(0, cw), r.randint(0, ch)
            ang = r.uniform(-0.6, 0.6)
            ln = r.randint(cw // 6, cw // 2)
            cv2.line(oscuro, (x0, y0), (int(x0 + ln * np.cos(ang)), int(y0 + ln * np.sin(ang))), 0.9, 1)
    return _poner(limpio, quad, cw, ch, a, oscuro, col)


def ilegible(img, quad, aspecto, semilla=1, fuerza=1.0, texto="HAB-02", opacidad=0.9):
    """Placa rasguñada: las letras originales emborronadas y cruzadas de arañazos, de modo que no se puedan leer."""
    limpio = borrar_letras(img, quad)
    col = color_letra(img, quad) * 0.9
    cw, ch = _lienzo(aspecto)
    r = np.random.RandomState(semilla)
    q = _cuadro(quad)
    k = max(1.0, cw / (0.5 * (np.linalg.norm(q[1] - q[0]) + np.linalg.norm(q[2] - q[3]))) * 0.55)   # grosor mínimo: ~medio píxel de imagen
    a = _texto(texto, cw, ch)
    a = cv2.GaussianBlur(a, (0, 0), ch * 0.07 * (0.8 + 0.5 * fuerza))
    # trozos que se pierden del todo: la placa raspada deja ver el metal
    ruido = cv2.GaussianBlur(r.rand(ch, cw).astype(np.float32), (0, 0), ch * 0.05)
    ruido = (ruido - ruido.min()) / (ruido.max() - ruido.min())
    a *= opacidad * np.clip(1.3 - 1.0 * fuerza * (ruido > 0.55), 0, 1)
    claro = a.copy()
    oscuro = np.zeros_like(a)
    for _ in range(int(30 * fuerza) + 8):          # arañazos claros (metal al descubierto) y oscuros (surcos)
        x0, y0 = r.randint(-cw // 10, cw), r.randint(0, ch)
        ang = r.uniform(-0.9, 0.9) + (np.pi / 2 if r.rand() < 0.25 else 0)
        ln = r.randint(ch // 2, int(cw * 0.55))
        p1 = (int(x0 + ln * np.cos(ang)), int(y0 + ln * np.sin(ang)))
        cv2.line(claro, (x0, y0), p1, float(r.uniform(0.45, 0.9)), int(r.choice([1, 2, 2, 3]) * k))
        cv2.line(oscuro, (x0 + 2, y0 + 1), (p1[0] + 2, p1[1] + 1), float(r.uniform(0.5, 0.9)), int(k))
    for _ in range(int(3 * fuerza) + 1):           # manchas oscuras que tapan trozos
        x0, y0 = r.randint(0, cw), r.randint(0, ch)
        cv2.ellipse(oscuro, (x0, y0), (r.randint(ch // 5, ch // 2), r.randint(ch // 8, ch // 3)), r.randint(0, 180), 0, 360, 0.75, -1)
    oscuro = cv2.GaussianBlur(oscuro, (0, 0), 1.6)
    return _poner(limpio, quad, cw, ch, np.clip(claro, 0, 1), np.clip(oscuro, 0, 1), col, blur=0.9)


def normal(img):
    """Pasillo normal: VIG · (ilegible) · ACCESO · LAB."""
    for i, ((quad, asp), txt) in enumerate(zip(PLACAS_NORMAL, TEXTOS_NORMAL)):
        if txt is None:
            img = ilegible(img, quad, asp, semilla=4, fuerza=0.35, texto="HAB-02", opacidad=1.0)
        else:
            img = escribir(img, quad, asp, txt)
    return img


def macabro(img):
    """Pasillo macabro (modos 1 y 2): las cuatro placas rasguñadas."""
    for i, (quad, asp) in enumerate(PLACAS_MACABRO):
        img = ilegible(img, quad, asp, semilla=10 + i, fuerza=1.0, texto=["HAB-01", "HAB-02", "HAB-03", "HAB-04"][i])
    return img


def _frase(img, palabras, semilla=20):
    """Una palabra en cada placa (izquierda a derecha), con la pintura desgastada."""
    for i, ((quad, asp), palabra) in enumerate(zip(PLACAS_MACABRO, palabras)):
        img = escribir(img, quad, asp, palabra, desgaste=0.3, semilla=semilla + i, brillo=1.45)   # más claras: la vista macabra va muy oscura
    return img


def macabro_modo3(img):
    """SABES · LO · QUE · PASÓ (modo 3, tras solicitar el 3.er glifo)."""
    return _frase(img, FRASE_MODO3, 20)


def macabro_haces(img):
    return _frase(img, FRASE_HACES, 30)


def macabro_quieres(img):
    return _frase(img, FRASE_QUIERES, 50)


def macabro_eres(img):
    return _frase(img, FRASE_ERES, 40)


def macabro_previo(img):
    """Modo 3 antes de cualquier frase: los carteles normales (VIG · ilegible · ACCESO · LAB) sobre la base macabra, claros para que se lean."""
    for i, ((quad, asp), txt) in enumerate(zip(PLACAS_MACABRO, TEXTOS_NORMAL)):
        if txt is None:
            img = ilegible(img, quad, asp, semilla=4, fuerza=0.35, texto="HAB-02", opacidad=1.0)
        else:
            img = escribir(img, quad, asp, txt, brillo=3.2)
    return img


if __name__ == "__main__":
    dest = os.path.join(AQUI, "..", "..", "assets", "fondos")
    base = cv2.imread(os.path.join(AQUI, "base", "pasillo_macabro_base.png"))
    for nombre, f in [("pasillo_macabro", macabro), ("pasillo_macabro_m3", macabro_modo3), ("pasillo_macabro_m3_previo", macabro_previo),
                      ("pasillo_macabro_haces", macabro_haces), ("pasillo_macabro_quieres", macabro_quieres), ("pasillo_macabro_m3_eres", macabro_eres)]:
        cv2.imwrite(os.path.join(dest, nombre + ".png"), f(base.copy()), [cv2.IMWRITE_PNG_COMPRESSION, 9])
        print("ok", nombre)
