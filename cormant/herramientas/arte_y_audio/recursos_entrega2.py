"""Genera:
  assets/sprites/alicia_perfil.png  -> Alicia de perfil, recortada al cuerpo (fondo negro a transparente) y volteada
                                       para que mire a la derecha (en el laboratorio está a la izquierda).
  assets/fondos/pasillo_mancha.png  -> fondo del pasillo con la anomalía de la sangre (1280x720).
Uso: python3 recursos_entrega2.py   (lee fuentes/alicia_perfil_fuente.png y fuentes/pasillo_mancha_fuente.png)"""
import os
import numpy as np, cv2

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.join(AQUI, "..", "..", "assets")
UMBRAL_FONDO = 2  # el fondo es negro puro (0-2); la ropa oscura de Alicia queda por encima


def perfil():
    g = cv2.imread(os.path.join(AQUI, "fuentes", "alicia_perfil_fuente.png"), cv2.IMREAD_GRAYSCALE)
    rgb = cv2.imread(os.path.join(AQUI, "fuentes", "alicia_perfil_fuente.png"), cv2.IMREAD_COLOR)
    oscuro = (g <= UMBRAL_FONDO).astype(np.uint8)
    # fondo = lo oscuro conectado con el borde; el resto es la figura (incluidas sus sombras interiores)
    n, lab = cv2.connectedComponents(oscuro, connectivity=4)
    bordes = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])).tolist())
    fondo = np.isin(lab, [b for b in bordes if b != 0])
    fig = (~fondo).astype(np.uint8)
    # quedarse con la componente principal (la figura) y rellenar huecos pequeños
    n, lab, st, _ = cv2.connectedComponentsWithStats(fig, connectivity=8)
    principal = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    fig = (lab == principal).astype(np.uint8)
    fig = cv2.morphologyEx(fig, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    alfa = cv2.GaussianBlur(fig.astype(np.float32) * 255, (0, 0), 1.0)
    x, y, w, h = cv2.boundingRect(fig)
    m = 10
    x0, y0, x1, y1 = max(0, x - m), max(0, y - m), min(g.shape[1], x + w + m), min(g.shape[0], y + h + m)
    out = np.dstack([rgb[..., ::-1], alfa.astype(np.uint8)])[y0:y1, x0:x1]
    out = cv2.resize(out, None, fx=0.5, fy=0.5, interpolation=cv2.INTER_AREA)  # 0,5 para el tamaño de juego
    out = cv2.flip(out, 1)  # mira a la derecha
    dst = os.path.join(RAIZ, "sprites", "alicia_perfil.png")
    cv2.imwrite(dst, cv2.cvtColor(out, cv2.COLOR_RGBA2BGRA))
    print("ok perfil", out.shape[1], "x", out.shape[0], "aspecto", round(out.shape[1] / out.shape[0], 4))


def fondo():
    img = cv2.imread(os.path.join(AQUI, "fuentes", "pasillo_mancha_fuente.png"), cv2.IMREAD_COLOR)
    img = cv2.resize(img, (1280, 720), interpolation=cv2.INTER_AREA)
    dst = os.path.join(RAIZ, "fondos", "pasillo_mancha.png")
    cv2.imwrite(dst, img)
    print("ok fondo", dst)


perfil()
fondo()
