"""Recorta a Alicia de las ilustraciones del autor y genera sus sprites con transparencia.

Uso:  python3 importar_personaje.py espaldas.png silla.png [CARPETA_SPRITES]
  espaldas.png : Alicia de pie, de espaldas (fondo negro)  -> alicia_de_espaldas.png (186x640)
  silla.png    : Alicia sentada en la silla de oficina, de espaldas -> alicia_sentada.png (335x674)
Las ilustraciones son casi negras: se segmentan por luminosidad (espaldas) y con GrabCut sobre una versión
amplificada con un contorno grueso dibujado a mano (silla). Se aclaran x1,7 para que se lean en las salas.
La habitación secreta no usa sprites: hab_tumbada.png / hab_sentada.png entran como fondos (importar_fondos.py).
"""
import sys, os
import numpy as np, cv2

GANANCIA = 1.7


def suavizar(mask, k, s):
    m = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, l, st, _ = cv2.connectedComponentsWithStats(m)
    if n > 1:
        m = ((l == 1 + np.argmax(st[1:, 4])) * 255).astype(np.uint8)
    return cv2.GaussianBlur(cv2.erode(m, np.ones((k, k), np.uint8)), (0, 0), s)


def recortar(img, alpha, alto, pad=6):
    ys, xs = np.where(alpha > 8)
    x0, x1, y0, y1 = max(xs.min() - pad, 0), min(xs.max() + pad, img.shape[1]), max(ys.min() - pad, 0), min(ys.max() + pad, img.shape[0])
    rgb = np.clip(img[y0:y1, x0:x1].astype(np.float32) * GANANCIA, 0, 255).astype(np.uint8)
    out = np.dstack([rgb, alpha[y0:y1, x0:x1]])
    w = round(out.shape[1] * alto / out.shape[0])
    return cv2.resize(out, (w, alto), interpolation=cv2.INTER_AREA)


def de_espaldas(img):
    g = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    m = cv2.morphologyEx((g > 2).astype(np.uint8) * 255, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    cnt, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    f = np.zeros_like(m)
    cv2.drawContours(f, cnt, -1, 255, -1)
    return recortar(img, suavizar(f, 5, 1.2), 640)


def sentada(img):
    """Coordenadas del contorno medidas sobre silla.png de 1672x941 (vista a media escala x2)."""
    H, W = img.shape[:2]
    S = W / 836.0
    amp = np.clip(img.astype(np.float32) * 7, 0, 255).astype(np.uint8)

    def P(pts): return (np.array(pts, np.float32) * S).astype(np.int32)
    contorno = P([(410, 34), (388, 48), (380, 100), (343, 135), (328, 185), (328, 230), (314, 231), (314, 246), (326, 252), (329, 312), (338, 325), (338, 345), (352, 345), (354, 392), (372, 398), (396, 398),
                  (404, 400), (404, 408), (318, 418), (310, 432), (316, 446), (332, 446), (338, 432), (404, 432), (404, 446), (418, 446), (418, 432), (486, 432), (492, 446), (512, 446), (516, 432), (508, 420), (424, 410),
                  (424, 398), (444, 398), (470, 396), (472, 350), (488, 346), (490, 325), (498, 312), (497, 254), (512, 246), (512, 231), (500, 230), (500, 185), (488, 140), (470, 130), (440, 108), (436, 50), (425, 36)])
    m = np.full((H, W), cv2.GC_BGD, np.uint8)
    dil = np.zeros((H, W), np.uint8)
    cv2.fillPoly(dil, [contorno], 255)
    m[cv2.dilate(dil, np.ones((29, 29), np.uint8)) > 0] = cv2.GC_PR_BGD
    m[dil > 0] = cv2.GC_PR_FGD
    cv2.fillPoly(m, [P([(380, 150), (480, 150), (490, 300), (340, 300)])], cv2.GC_FGD)
    x, y, w, h = cv2.boundingRect(cv2.dilate(dil, np.ones((29, 29), np.uint8)))
    sub, ms = amp[y:y + h, x:x + w], m[y:y + h, x:x + w].copy()
    cv2.grabCut(sub, ms, None, np.zeros((1, 65)), np.zeros((1, 65)), 6, cv2.GC_INIT_WITH_MASK)
    res = np.zeros((H, W), np.uint8)
    res[y:y + h, x:x + w] = ((ms == 1) | (ms == 3)) * 255
    for x0, x1 in [(777, 806), (854, 878)]:   # hueco entre las piernas, bajo el asiento
        res[665:790, x0:x1] = 0
    return recortar(img, suavizar(res, 3, 1.0), 674)


if __name__ == "__main__":
    dest = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
    cv2.imwrite(os.path.join(dest, "alicia_de_espaldas.png"), de_espaldas(cv2.imread(sys.argv[1])))
    cv2.imwrite(os.path.join(dest, "alicia_sentada.png"), sentada(cv2.imread(sys.argv[2])))
