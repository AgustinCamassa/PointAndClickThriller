"""Pega la vista de `ventana_recepcion` (y la `_macabro`) en el cristal de la ventana de Vigilancia (y de `vigilancia_macabro`),
para que lo que se ve desde la sala sea exactamente lo mismo que al hacer clic en la ventana y ampliarla.

Uso:  python3 ventana_en_vigilancia.py [CARPETA_FONDOS]        (por defecto assets/fondos)
Toma la zona interior del cristal de ventana_recepcion (sin el marco) y la encaja, reducida, en el hueco del cristal de
Vigilancia (más ancho que alto: la imagen se aplasta en vertical, como ya lo estaba la vista original). Es idempotente.
Orden: importar_macabros.py (si se vuelve a generar el fondo macabro) -> este script -> fondos_apagon.py.
Requiere opencv-python y numpy."""
import os, sys
import numpy as np, cv2

# Cristal de cada fondo de Vigilancia (x0, y0, x1, y1) en 1280x720
VIDRIO = {"vigilancia": (356, 153, 897, 306), "vigilancia_macabro": (358, 149, 925, 306)}
# Zona interior del cristal en ventana_recepcion (la que el panel tampoco tapa con el marco)
INTERIOR = (15, 86, 1265, 619)
ORIGEN = {"vigilancia": "ventana_recepcion", "vigilancia_macabro": "ventana_recepcion_macabro"}


def pegar(fondo, ventana, rect):
    x0, y0, x1, y1 = rect
    v = ventana[INTERIOR[1]:INTERIOR[3], INTERIOR[0]:INTERIOR[2]]
    t = cv2.resize(v, (x1 - x0, y1 - y0), interpolation=cv2.INTER_AREA).astype(np.float32)
    # sombra suave en el borde (el cristal se mete en el marco)
    h, w = t.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy])
    t *= (0.72 + 0.28 * np.clip(d / 4.0, 0, 1))[..., None]
    out = fondo.copy()
    out[y0:y1, x0:x1] = t.clip(0, 255).astype(np.uint8)
    return out


def main(carpeta):
    for nombre, origen in ORIGEN.items():
        f = cv2.imread(os.path.join(carpeta, nombre + ".png"))
        v = cv2.imread(os.path.join(carpeta, origen + ".png"))
        cv2.imwrite(os.path.join(carpeta, nombre + ".png"), pegar(f, v, VIDRIO[nombre]), [cv2.IMWRITE_PNG_COMPRESSION, 9])
        print(nombre, "<-", origen)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "fondos"))
