"""Fondo del título en versión macabra (edificio de Cormant deteriorado).
Fuentes (1280x720, ya reencuadradas para coincidir con titulo.png): fuentes/titulo_macabro_nitido.png (farola encendida)
y fuentes/titulo_macabro_apagado_nitido.png (farola apagada).
Escribe en assets/fondos: titulo_macabro.png, titulo_macabro_apagado.png (cartel desenfocado) y
titulo_macabro_cartel_1/2/3.png (recortes RGBA del cartel por nivel de nitidez; se colocan en CARTEL_POS_MACABRO).
Requiere Pillow, numpy y scipy."""
import os
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

aqui = os.path.dirname(os.path.abspath(__file__))
carpeta = os.path.join(aqui, "..", "..", "assets", "fondos")
CAJA = (566, 308, 758, 372)
NIVELES = {0: 6.5, 1: 4.8, 2: 3.0, 3: 0.0}
GANANCIA = {0: 2.4, 1: 1.8, 2: 1.3, 3: 1.0}


def cargar(n):
    return np.asarray(Image.open(os.path.join(aqui, "fuentes", n)).convert("RGB"), np.float32)


mascara = np.zeros((720, 1280), np.float32)
mascara[CAJA[1]:CAJA[3], CAJA[0]:CAJA[2]] = 1.0
mascara = np.clip(gaussian_filter(mascara, 3.0) * 1.6, 0, 1)[..., None]


def nivel(img, n):
    s = NIVELES[n]
    if s <= 0:
        return img
    b = np.stack([gaussian_filter(img[..., c], s) for c in range(3)], -1)
    medio = np.median(img[CAJA[1]:CAJA[3], CAJA[0]:CAJA[2]].reshape(-1, 3), axis=0)
    b = medio + (b - medio) * GANANCIA[n]
    return img * (1 - mascara) + b * mascara


for fuente, salida in (("titulo_macabro_nitido.png", "titulo_macabro.png"), ("titulo_macabro_apagado_nitido.png", "titulo_macabro_apagado.png")):
    Image.fromarray(np.clip(nivel(cargar(fuente), 0), 0, 255).astype(np.uint8)).save(os.path.join(carpeta, salida))
img = cargar("titulo_macabro_nitido.png")
x0, y0, x1, y1 = CAJA[0] - 24, CAJA[1] - 24, CAJA[2] + 24, CAJA[3] + 24
for n in (1, 2, 3):
    rgb = nivel(img, n)[y0:y1, x0:x1]
    alfa = (mascara[y0:y1, x0:x1] * 255).astype(np.uint8)
    Image.fromarray(np.concatenate([np.clip(rgb, 0, 255).astype(np.uint8), alfa], -1), "RGBA").save(os.path.join(carpeta, "titulo_macabro_cartel_%d.png" % n))
print("ok; CARTEL_POS_MACABRO =", (x0, y0))
