"""Palabra «de sangre» del cuadro del pasillo macabro: la 5.ª palabra de la acusación de cada modo (las otras 4 van en las placas de las puertas, placas_pasillo.py).

  Modo 1: SABES · LO · QUE · HACES + «aquí»      Modo 2: NO · HACES · LO · QUE + «quieres»      Modo 3: NO · ERES · QUIEN · CREES + «ser»
  (frase oculta con las palabras del cuadro, 1 -> 2 -> 3: AQUÍ QUIERES SER)

Genera assets/sprites/sangre_cuadro_aqui.png, sangre_cuadro_quieres.png y sangre_cuadro_ser.png: imágenes de 1280x720 con transparencia (el tamaño de los
fondos) con la palabra ya puesta en perspectiva sobre el cristal del cuadro; el juego solo las superpone al fondo macabro.

LETRA PROPIA: no usa ninguna fuente. Cada letra es un esqueleto de trazos (lista de puntos, `GLIFOS`) que aquí se «escribe con el dedo»: un pincel gordo y redondo
que se desliza dejando el trazo irregular, con surcos paralelos de los dedos que se van secando hacia el final, el principio más cargado de pintura, el pulso
tembloroso, cada letra con su inclinación y su altura, y goterones. Al ser código propio no hay licencias que respetar (se puede vender el juego).
Solo están las letras que se usan (a, e, i, í, q, r, s, u); para otra palabra hay que añadir sus esqueletos.

Uso:  python3 sangre_mensajes.py  (requiere numpy, opencv-python y Pillow)
"""
import os
import numpy as np, cv2
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.join(AQUI, "..", "..")
DESTINO = os.path.join(RAIZ, "assets", "sprites")

# (archivo, texto, semilla)
PALABRAS = [("sangre_cuadro_aqui", "aquí", 15), ("sangre_cuadro_quieres", "quieres", 16), ("sangre_cuadro_ser", "ser", 33)]

# Cristal del cuadro del pasillo macabro en la imagen de 1280x720 (TL, TR, BR, BL) y proporción real (ancho/alto) estimada del cristal.
CUADRO = [(819, 264), (900, 224), (903, 411), (819, 398)]
CUADRO_ASPECTO = 0.8
ANCHO_REL = 0.94           # ancho máximo de la palabra respecto al del cristal
ALTO_REL = 0.30            # alto máximo de la palabra respecto al del cristal
CENTRO_V = 0.40            # altura del centro de la palabra dentro del cristal (0 = arriba, 1 = abajo)

# Esqueletos de las letras: x de 0 a 1 (ancho de la letra), y de 0 (parte alta de las minúsculas) a 1 (línea base); y < 0 por encima, y > 1 por debajo.
# Cada letra: (ancho relativo a la altura de las minúsculas, [trazos]); un trazo es una lista de puntos que se suaviza con una spline.
_BOLA = [(0.95, 0.15), (0.5, 0.0), (0.06, 0.3), (0.08, 0.75), (0.5, 1.0), (0.95, 0.82)]
GLIFOS = {
    "a": (0.78, [_BOLA, [(0.96, 0.0), (0.96, 0.55), (0.96, 1.0)]]),
    "q": (0.78, [_BOLA, [(0.96, 0.0), (0.96, 0.8), (0.97, 1.6)]]),
    "u": (0.74, [[(0.05, 0.0), (0.05, 0.55), (0.3, 0.94), (0.68, 0.98), (0.95, 0.72)], [(0.97, 0.0), (0.97, 0.5), (0.97, 1.0)]]),
    "i": (0.22, [[(0.5, 0.12), (0.5, 0.55), (0.5, 1.0)], [(0.5, -0.62), (0.52, -0.54)]]),
    "í": (0.22, [[(0.5, 0.12), (0.5, 0.55), (0.5, 1.0)], [(0.25, -0.42), (0.6, -0.68), (0.98, -0.9)]]),
    "e": (0.74, [[(0.05, 0.56), (0.5, 0.52), (0.95, 0.47), (0.88, 0.16), (0.5, 0.0), (0.14, 0.14), (0.04, 0.5), (0.12, 0.8), (0.5, 1.0), (0.92, 0.86)]]),
    "r": (0.6, [[(0.15, 0.0), (0.15, 0.5), (0.15, 1.0)], [(0.15, 0.42), (0.4, 0.1), (0.9, 0.04)]]),
    "s": (0.66, [[(0.92, 0.15), (0.5, 0.0), (0.1, 0.2), (0.5, 0.5), (0.9, 0.78), (0.5, 1.0), (0.06, 0.85)]]),
}
GLIFOS.update({
    "S": (0.8, [[(0.9, -0.28), (0.5, -0.46), (0.1, -0.26), (0.5, 0.2), (0.92, 0.62), (0.5, 1.0), (0.05, 0.82)]]),
    "b": (0.78, [[(0.12, -0.55), (0.12, 0.25), (0.12, 1.0)], [(0.12, 0.4), (0.58, 0.04), (0.95, 0.5), (0.6, 1.0), (0.1, 0.9)]]),
    "n": (0.74, [[(0.1, 0.0), (0.1, 0.5), (0.1, 1.0)], [(0.1, 0.3), (0.42, 0.0), (0.86, 0.15), (0.92, 0.55), (0.92, 1.0)]]),
    "o": (0.78, [[(0.52, 0.0), (0.1, 0.3), (0.1, 0.75), (0.5, 1.0), (0.92, 0.7), (0.9, 0.28), (0.5, 0.0), (0.38, 0.04)]]),
    "y": (0.78, [[(0.05, 0.0), (0.3, 0.5), (0.5, 0.95)], [(0.95, 0.0), (0.7, 0.5), (0.45, 1.0), (0.2, 1.55)]]),
    "é": (0.74, GLIFOS["e"][1] + [[(0.35, -0.25), (0.65, -0.5), (0.96, -0.68)]]),
    ".": (0.12, [[(0.5, 0.9), (0.52, 0.97)]]),
    "N": (0.9, [[(0.1, 1.0), (0.1, 0.3), (0.1, -0.45)], [(0.1, -0.4), (0.5, 0.3), (0.9, 0.95)], [(0.9, 1.0), (0.9, 0.25), (0.9, -0.45)]]),
    "v": (0.7, [[(0.05, 0.0), (0.3, 0.5), (0.5, 1.0)], [(0.95, 0.0), (0.72, 0.5), (0.5, 1.0)]]),
    "p": (0.76, [[(0.12, 0.0), (0.12, 0.8), (0.12, 1.6)], [(0.12, 0.15), (0.6, 0.0), (0.95, 0.4), (0.6, 0.92), (0.12, 0.82)]]),
    "t": (0.56, [[(0.45, -0.32), (0.45, 0.5), (0.55, 0.95), (0.92, 0.9)], [(0.08, 0.08), (0.5, 0.05), (0.92, 0.08)]]),
    "d": (0.78, [_BOLA, [(0.96, -0.55), (0.96, 0.5), (0.96, 1.0)]]),
    "+": (0.7, [[(0.08, 0.5), (0.5, 0.5), (0.92, 0.5)], [(0.5, 0.08), (0.5, 0.5), (0.5, 0.92)]]),
})
SEPARACION = 0.4
ESPACIO = 0.55   # ancho de un espacio, en alturas de minúscula


def _spline(pts, paso=1.0):
    """Curva suave (Catmull-Rom) por los puntos, muestreada cada `paso` píxeles."""
    p = np.array(pts, np.float32)
    p = np.vstack([p[0] - (p[1] - p[0]), p, p[-1] + (p[-1] - p[-2])])
    seg = []
    for i in range(1, len(p) - 2):
        n = max(8, int(np.linalg.norm(p[i + 1] - p[i]) / paso))
        t = np.linspace(0, 1, n, endpoint=False)[:, None]
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        seg.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ** 2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    seg.append(p[-2][None])
    c = np.vstack(seg)
    # remuestreo a paso constante
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(c, axis=0), axis=1))]
    if d[-1] < 1:
        return c
    u = np.arange(0, d[-1], paso)
    return np.stack([np.interp(u, d, c[:, 0]), np.interp(u, d, c[:, 1])], axis=1)


def _ruido(rng, n, escala):
    """Ruido suave 1D de n muestras entre 0 y 1."""
    k = max(2, int(n / escala) + 2)
    return np.interp(np.linspace(0, k - 1, n), np.arange(k), rng.rand(k))


def _trazo(lienzo, pts, rng, radio, gotas):
    """Un trazo con el dedo: pincel redondo y gordo que se seca hacia el final y deja surcos."""
    c = _spline(pts)
    n = len(c)
    if n < 3:
        return
    t = np.linspace(0, 1, n)
    tang = np.gradient(c, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True) + 1e-6
    nor = np.stack([-tang[:, 1], tang[:, 0]], axis=1)
    r = radio * (1.05 - 0.38 * t ** 1.2) * (0.88 + 0.24 * _ruido(rng, n, 30))        # más ancho al empezar, se afina al final
    r[:max(1, n // 12)] *= 1.12                                                       # la pasada empieza con un manchón de pintura
    # surcos paralelos: cada «carril» del dedo se queda sin pintura antes o después
    L = 5
    grosor = max(2, int(round(2.0 * radio / (2 * L + 1) * 1.9)))
    seco = 0.08 + 0.7 * t ** 1.4
    for j in range(-L, L + 1):
        ruido = _ruido(rng, n, 14 + 10 * rng.rand())
        umbral = seco * (0.55 + 0.9 * abs(j) / L)
        vivo = ruido > umbral
        vivo[:max(2, n // 10)] = True
        p = c + nor * (j / L * r * 0.86)[:, None]
        i = 0
        while i < n:
            if not vivo[i]:
                i += 1
                continue
            k = i
            while k < n and vivo[k]:
                k += 1
            if k - i >= 2:
                cv2.polylines(lienzo, [np.round(p[i:k] * 4).astype(np.int32)], False, 255, grosor, cv2.LINE_AA, shift=2)
            i = k
    # manchón inicial macizo
    cv2.circle(lienzo, tuple(np.round(c[0] * 4).astype(int)), int(r[0] * 4 * 0.95), 255, -1, cv2.LINE_AA, shift=2)
    return c, r


def _letra_a_trazos(lienzo, ch, x0, base, alto, rng, radio, bajos):
    ancho, trazos = GLIFOS[ch]
    ang = np.radians(rng.uniform(-4, 4) + 7)                   # cada letra algo torcida, con la inclinación de quien escribe deprisa
    esc_y = alto * rng.uniform(0.94, 1.08)
    desp_y = rng.uniform(-0.05, 0.05) * alto
    for tr in trazos:
        pts = []
        for (x, y) in tr:
            x += rng.normal(0, 0.03)                           # pulso tembloroso
            y += rng.normal(0, 0.03)
            px = x * ancho * alto
            py = y * esc_y
            # inclinación y giro alrededor de la línea base
            qx = px + (1 - y) * np.tan(ang) * esc_y * 0.5
            pts.append((x0 + qx, base + desp_y + py - esc_y))
        res = _trazo(lienzo, pts, rng, radio * rng.uniform(0.94, 1.06), 0)
        if res is not None:
            c, r = res
            i0 = np.argsort(c[:, 1])[-max(3, len(c) // 6):]
            bajos.extend(tuple(c[i]) for i in i0)   # candidatos a goterón: la parte baja de cada trazo


def _gotas(lienzo, bajos, rng, alto, radio, cuantas):
    """Unos pocos goterones, finos y de largo distinto, que bajan desde la parte baja de las letras."""
    for _ in range(cuantas):
        x, y = bajos[int(rng.randint(len(bajos)))]
        largo = rng.uniform(0.2, 0.6) * alto
        gr = max(1.5, radio * rng.uniform(0.14, 0.22))
        x2 = x + rng.uniform(-1.2, 1.2)
        cv2.line(lienzo, (int(x * 4), int((y - radio * 0.5) * 4)), (int(x2 * 4), int((y + largo) * 4)), 255, int(gr * 2 * 4), cv2.LINE_AA, shift=2)
        cv2.circle(lienzo, (int(x2 * 4), int((y + largo) * 4)), int(gr * 1.6 * 4), 255, -1, cv2.LINE_AA, shift=2)


def sangre(texto, tam, semilla, gotas=1.0, vivo=False):
    """Palabra escrita con el dedo, en rojo sangre sobre transparente. `tam` = altura de las minúsculas en píxeles."""
    rng = np.random.RandomState(semilla)
    radio = tam * 0.098                                         # el dedo: ancho de trazo ≈ 0.23 de la altura de las minúsculas
    gap = SEPARACION * tam
    ancho_total = sum((ESPACIO * tam) if ch == " " else (GLIFOS[ch][0] * tam + gap) for ch in texto)
    pad = int(tam * 0.9)
    w, h = int(ancho_total) + 2 * pad, int(tam * 1.75) + 2 * pad + int(tam * 1.3)
    lienzo = np.zeros((h, w), np.uint8)
    x = pad
    base = pad + int(tam * 1.3)
    bajos = []
    for ch in texto:
        if ch == " ":
            x += ESPACIO * tam
            continue
        _letra_a_trazos(lienzo, ch, x, base, tam, rng, radio, bajos)
        x += GLIFOS[ch][0] * tam + gap * rng.uniform(0.8, 1.25)
    _gotas(lienzo, bajos, rng, tam, radio, max(1, int(round(len(texto) * 0.4 * gotas))))
    m = cv2.GaussianBlur(lienzo.astype(np.float32) / 255, (0, 0), 0.9)
    return _colorear(m, rng, vivo)


def _colorear(alfa, rng, vivo=False):
    h, w = alfa.shape
    k = lambda sigma, esc: cv2.GaussianBlur(rng.rand(h, w).astype(np.float32), (0, 0), sigma) * esc
    # sangre espesa: un poco más oscura donde hay más pintura y más clara en los bordes finos
    brillo = np.clip((k(9, 1.0) / 0.1) * 0.0 + (cv2.GaussianBlur(rng.rand(h, w).astype(np.float32), (0, 0), 9) - 0.4) * 4 + 0.5, 0, 1)
    rojo = np.zeros((h, w, 3), np.float32)
    # mismo tono que las manchas de sangre del fondo (medido en pasillo_macabro: rojo apagado y algo terroso, no un carmesí vivo, ~ (49, 29, 24) en lo más rojo),
    # solo algo más claro para que se lea sobre el cristal oscuro del cuadro
    if vivo:   # para el menú (sobre fondo oscuro): el mismo rojo pero más vivo para que se lea
        rojo[..., 0] = 165 + 50 * brillo
        rojo[..., 1] = 22 + 12 * brillo
        rojo[..., 2] = 20 + 10 * brillo
    else:
        rojo[..., 0] = 92 + 34 * brillo
        rojo[..., 1] = 30 + 10 * brillo
        rojo[..., 2] = 26 + 9 * brillo
    halo = cv2.GaussianBlur(alfa, (0, 0), 3.2) * 0.8
    alfa_total = np.clip(np.maximum(alfa, halo * 0.45), 0, 1)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = rojo.clip(0, 255).astype(np.uint8)
    rgba[..., 3] = (alfa_total * 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def palabra_en_perspectiva(texto, semilla):
    """La palabra sobre el cristal del cuadro: se escribe plana y se pasa a la perspectiva del cuadro (hacia el punto de fuga central)."""
    flat = sangre(texto, 260, semilla, gotas=0.8)
    a = np.array(flat).astype(np.float32)
    bb = Image.fromarray(a[..., 3].astype(np.uint8)).point(lambda v: 255 if v > 40 else 0).getbbox()
    a = a[bb[1]:bb[3], bb[0]:bb[2]]
    W, H = 400, int(400 / CUADRO_ASPECTO)            # lienzo plano del cristal con su proporción real
    tw = min(W * ANCHO_REL, H * ALTO_REL * a.shape[1] / a.shape[0])
    th = tw * a.shape[0] / a.shape[1]
    alfa = a[..., 3:4] / 255.0
    pre = np.concatenate([a[..., :3] * alfa, alfa * 255], axis=2)   # premultiplicado: el remuestreo no ensucia los bordes
    pre = cv2.resize(pre, (int(tw), int(th)), interpolation=cv2.INTER_AREA)
    lienzo = np.zeros((H, W, 4), np.float32)
    x0 = int((W - pre.shape[1]) / 2)
    y0 = int(CENTRO_V * H - pre.shape[0] / 2)
    lienzo[y0:y0 + pre.shape[0], x0:x0 + pre.shape[1]] = pre
    M = cv2.getPerspectiveTransform(np.float32([(0, 0), (W, 0), (W, H), (0, H)]), np.float32(CUADRO))
    out = cv2.warpPerspective(lienzo, M, (1280, 720), flags=cv2.INTER_LINEAR)
    al = out[..., 3:4] / 255.0
    rgb = np.where(al > 1e-3, out[..., :3] / np.maximum(al, 1e-3), 0)
    rgba = np.concatenate([rgb.clip(0, 255), out[..., 3:4].clip(0, 255)], axis=2).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def prueba_plana(destino):
    """Para ver las letras sin perspectiva (solo para revisar el diseño)."""
    im = [sangre(t, 220, s) for _, t, s in PALABRAS]
    W = max(i.width for i in im); H = sum(i.height for i in im)
    hoja = Image.new("RGBA", (W, H), (20, 20, 22, 255))
    y = 0
    for i in im:
        hoja.alpha_composite(i, (0, y)); y += i.height
    hoja.convert("RGB").save(destino)


def sprite_final(semilla=8, ancho_final=1210):
    """«Sabes quién soy...» para el documento final del modo 3 (assets/sprites/sangre_sabes_quien_soy.png), con la misma letra de dedo.
    Se escala a `ancho_final` píxeles de ancho (como el sprite anterior, para que quepa en la hoja: final.gd lo pinta al 50 %)."""
    img = sangre("Sabes quién soy...", 170, semilla, gotas=0.8)
    img = img.crop(img.getbbox())
    alto = int(img.height * ancho_final / img.width)
    img = img.resize((ancho_final, alto), Image.LANCZOS)
    img.save(os.path.join(DESTINO, "sangre_sabes_quien_soy.png"), compress_level=9)
    return img


def sprite_menu(semilla=9):
    """«Nueva partida +» en rojo, con la letra de dedo, para el botón del menú de inicio (modo 3) -> assets/sprites/menu_nueva_partida_mas.png."""
    img = sangre("Nueva partida +", 64, semilla, gotas=0.6, vivo=True)
    img = img.crop(img.getbbox())
    img.save(os.path.join(DESTINO, "menu_nueva_partida_mas.png"), compress_level=9)
    return img


if __name__ == "__main__":
    print("ok menu", sprite_menu().size)
    sprite_final()
    print("ok sangre_sabes_quien_soy")
    os.makedirs(DESTINO, exist_ok=True)
    for nombre, texto, semilla in PALABRAS:
        img = palabra_en_perspectiva(texto, semilla)
        img.save(os.path.join(DESTINO, nombre + ".png"), compress_level=9)
        print("ok", nombre, img.size, img.getbbox())
