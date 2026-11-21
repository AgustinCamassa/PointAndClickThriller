"""Genera assets/sprites/entidad_a.png (modos 1 y 2) y entidad_b.png (modo 3, más deteriorada) a partir de las
siluetas negras sobre blanco de fuentes/entidad_{a,b}_fuente.png. Blanco -> transparente; los ojos (blanco encerrado
dentro del cuerpo, en la cabeza) se conservan brillantes. Ambos sprites salen con el mismo lienzo (misma proporción).
Uso: python3 sprites_entidad.py"""
import os, numpy as np, cv2
from collections import deque
AQUI = os.path.dirname(__file__)
DST = os.path.join(AQUI, "..", "..", "assets", "sprites")
ESC = 0.5

def cargar(n):
    g = cv2.imread(os.path.join(AQUI, "fuentes", f"entidad_{n}_fuente.png"), cv2.IMREAD_GRAYSCALE)
    oscuro = (255 - g).astype(np.float32) / 255.0
    blanco = (g > 128).astype(np.uint8)
    # blanco conectado con el borde = fondo; blanco encerrado en la cabeza = ojos
    _, lab = cv2.connectedComponents(blanco, connectivity=4)
    fondo = lab == lab[0, 0]
    ojos = (blanco == 1) & ~fondo
    ojos[320:] = False
    n_c, lc, st, _ = cv2.connectedComponentsWithStats(ojos.astype(np.uint8))
    grandes = sorted(range(1, n_c), key=lambda i: -st[i, cv2.CC_STAT_AREA])[:2]   # solo los dos ojos
    ojos = np.isin(lc, grandes)
    ojos = cv2.dilate(ojos.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool)
    return oscuro, ojos

datos = {n: cargar(n) for n in "ab"}
union = np.zeros_like(datos["a"][0], bool)
for o, _ in datos.values():
    union |= o > 0.5
ys, xs = np.where(union)
x0, x1, y0, y1 = xs.min() - 12, xs.max() + 12, ys.min() - 12, ys.max() + 12
for n, (oscuro, ojos) in datos.items():
    a = oscuro.copy()
    a[ojos] = 1.0
    rgb = np.zeros(a.shape + (3,), np.float32)
    rgb[ojos] = 1.0
    rgb = cv2.GaussianBlur(rgb, (0, 0), 1.5)
    rgb[~ojos & (cv2.GaussianBlur(ojos.astype(np.float32), (0, 0), 3) < 0.05)] = 0
    rgba = np.dstack([rgb, a])[y0:y1, x0:x1]
    rgba = cv2.resize(rgba, None, fx=ESC, fy=ESC, interpolation=cv2.INTER_AREA)
    out = (rgba[..., [2, 1, 0, 3]] * 255).astype(np.uint8)
    cv2.imwrite(os.path.join(DST, f"entidad_{n}.png"), out)
    print("ok", n, out.shape[1], "x", out.shape[0], "aspecto", round(out.shape[1] / out.shape[0], 4))
