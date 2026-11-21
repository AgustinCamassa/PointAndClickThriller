"""Genera el fondo del título con el cartel del edificio («CORMANT / MEDICAL SYSTEMS») borroso y sus niveles de nitidez.
Uso: python3 fondo_titulo.py [FUENTE_1280x720.png] [CARPETA_FONDOS]
Por defecto lee fuentes/titulo_nitido.png (el render original a 1280x720) y escribe en assets/fondos:
  titulo.png          fondo con el cartel muy borroso (ningún modo superado)
  titulo_cartel_1.png recorte RGBA del cartel algo menos borroso (1 modo superado)
  titulo_cartel_2.png                                          casi legible (2 modos)
  titulo_cartel_3.png                                          nítido (los 3 modos superados)
Los recortes se colocan encima del fondo en CARTEL_POS (el borde está difuminado, no se nota el corte).
Requiere Pillow, numpy y scipy."""
import sys, os
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

aqui = os.path.dirname(os.path.abspath(__file__))
fuente = sys.argv[1] if len(sys.argv) > 1 else os.path.join(aqui, "fuentes", "titulo_nitido.png")
carpeta = sys.argv[2] if len(sys.argv) > 2 else os.path.join(aqui, "..", "..", "assets", "fondos")

CAJA = (574, 340, 752, 388)      # x0, y0, x1, y1 del logo y las letras (espacio 1280x720)
NIVELES = {0: 6.5, 1: 4.8, 2: 3.0, 3: 0.0}   # desviación del desenfoque por nivel
GANANCIA = {0: 2.4, 1: 1.8, 2: 1.3, 3: 1.0}  # contraste de la mancha respecto al fondo del cartel (para que siga viéndose)

img = np.asarray(Image.open(fuente).convert("RGB"), np.float32)
H, W = img.shape[:2]
mascara = np.zeros((H, W), np.float32)
mascara[CAJA[1]:CAJA[3], CAJA[0]:CAJA[2]] = 1.0
mascara = np.clip(gaussian_filter(mascara, 3.0) * 1.6, 0, 1)[..., None]


def nivel(n):
    sigma = NIVELES[n]
    if sigma <= 0:
        return img
    borroso = np.stack([gaussian_filter(img[..., c], sigma) for c in range(3)], -1)
    medio = np.median(img[CAJA[1]:CAJA[3], CAJA[0]:CAJA[2]].reshape(-1, 3), axis=0)
    borroso = medio + (borroso - medio) * GANANCIA[n]
    return img * (1 - mascara) + borroso * mascara


base = nivel(0)
Image.fromarray(np.clip(base, 0, 255).astype(np.uint8)).save(os.path.join(carpeta, "titulo.png"))
x0, y0, x1, y1 = CAJA[0] - 24, CAJA[1] - 24, CAJA[2] + 24, CAJA[3] + 24
for n in (1, 2, 3):
    rgb = nivel(n)[y0:y1, x0:x1]
    alfa = (mascara[y0:y1, x0:x1] * 255).astype(np.uint8)
    out = np.concatenate([np.clip(rgb, 0, 255).astype(np.uint8), alfa], -1)
    Image.fromarray(out, "RGBA").save(os.path.join(carpeta, "titulo_cartel_%d.png" % n))
print("ok titulo + 3 niveles; CARTEL_POS =", (x0, y0), "tamaño", (x1 - x0, y1 - y0))
