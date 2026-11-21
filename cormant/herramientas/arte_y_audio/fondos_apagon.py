"""Genera las versiones de apagón de los fondos: assets/fondos/<nombre>_apagon.png.
Baja el brillo de las zonas de iluminación (lámparas, reflejos, pantallas encendidas) con una máscara de altas luces suavizada,
oscurece toda la imagen con una curva (más sombra que luz), le da un leve tono frío y una viñeta, y apaga las pantallas
de los ordenadores. No toca los originales.
Uso: python3 fondos_apagon.py [CARPETA_FONDOS]"""
import sys, os
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

carpeta = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "fondos")
# fondo -> rectángulos (x0, y0, x1, y1) de pantallas de ordenador que se apagan del todo
FONDOS = {
    "recepcion": [], "recepcion_reverso": [], "pasillo": [], "oficina": [], "pasillo_alterado": [],
    "vigilancia": [(386, 322, 830, 426)],
    "laboratorio": [(494, 318, 742, 376)],
    "ventana_recepcion": [], "pasillo_secreto": [],
    # fondos macabros (importar_macabros.py): mismas pantallas que sus salas normales
    "pasillo_macabro": [], "recepcion_macabro": [], "recepcion_reverso_macabro": [], "oficina_macabro": [], "pasillo_secreto_macabro": [],
    "ventana_recepcion_macabro": [],
    "vigilancia_macabro": [(386, 322, 850, 426)],
    "laboratorio_macabro": [(494, 318, 742, 376)],
}
BRILLO_GLOBAL = 0.58       # multiplicador general tras la curva
GAMMA = 1.05               # >1 hunde más las sombras
REDUCCION_LUCES = 0.82     # cuánto se apaga la zona de iluminación


def suavizado(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


for nombre, pantallas in FONDOS.items():
    ruta = os.path.join(carpeta, nombre + ".png")
    if not os.path.exists(ruta):
        print("falta", ruta)
        continue
    im = np.asarray(Image.open(ruta).convert("RGB"), np.float32) / 255.0
    h, w = im.shape[:2]
    lum = im @ np.array([0.299, 0.587, 0.114], np.float32)
    # Zonas de iluminación: altas luces y su halo
    luces = suavizado(gaussian_filter(lum, 1.5), 0.42, 0.78)
    luces = np.clip(gaussian_filter(luces, 9) * 1.6, 0, 1)
    out = im * (1.0 - REDUCCION_LUCES * luces[..., None])
    out = np.power(np.clip(out, 0, 1), GAMMA) * BRILLO_GLOBAL
    out *= np.array([0.86, 0.93, 1.08], np.float32)      # tono frío de emergencia
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    vig = 1.0 - 0.35 * np.clip(((xx - w / 2) / (w / 1.5)) ** 2 + ((yy - h / 2) / (h / 1.4)) ** 2, 0, 1)
    out *= vig[..., None]
    for (x0, y0, x1, y1) in pantallas:
        sx, sy = w / 1280.0, h / 720.0
        caja = (slice(int(y0 * sy), int(y1 * sy)), slice(int(x0 * sx), int(x1 * sx)))
        out[caja] *= 0.18
    Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(
        os.path.join(carpeta, nombre + "_apagon.png"), optimize=True)
    print("ok", nombre + "_apagon.png", "luces medias:", round(float(luces.mean()), 3))
