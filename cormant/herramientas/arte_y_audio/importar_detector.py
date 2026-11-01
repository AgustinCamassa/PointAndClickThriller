"""Prepara assets/sprites/detector.png a partir de la imagen del detector de señales aportada por el autor.
Uso: python3 importar_detector.py DETECTOR.png [DESTINO.png]
Borra el contenido de la pantalla LCD (el juego escribe encima la lista de señales) y reduce a 320 px de ancho.
LEDs apagados y botones (el juego dibuja botones propios más grandes encima de los originales).
Imprime el rectángulo del LCD relativo al sprite (0-1), que usa interfaz.gd (const LCD_REL)."""
import sys
import numpy as np, cv2

src = cv2.imread(sys.argv[1], cv2.IMREAD_UNCHANGED)
dst = sys.argv[2] if len(sys.argv) > 2 else "../../assets/sprites/detector.png"
h, w = src.shape[:2]
b, g, r = [src[..., i].astype(np.int32) for i in range(3)]
verde = (g > r + 25) & (g > b + 8) & (g > 70)
caja = np.zeros_like(verde)
caja[int(h * 0.44):int(h * 0.67), int(w * 0.14):int(w * 0.86)] = True
ys, xs = np.where(verde & caja)
x0, x1, y0, y1 = np.percentile(xs, 0.5), np.percentile(xs, 99.5), np.percentile(ys, 0.5), np.percentile(ys, 99.5)
x0, x1, y0, y1 = int(x0) - 3, int(x1) + 3, int(y0) - 3, int(y1) + 3
print("LCD px:", x0, y0, x1, y1)
yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
rad = np.sqrt(((xx - cx) / ((x1 - x0) / 2)) ** 2 + ((yy - cy) / ((y1 - y0) / 2)) ** 2)
base = np.stack([8 + 6 * (1 - rad), 38 + 22 * (1 - rad), 14 + 8 * (1 - rad)], -1)  # BGR verde oscuro con brillo central
base[::3] *= 0.85
src[y0:y1, x0:x1, :3] = np.clip(base, 0, 255).astype(np.uint8)
if src.shape[2] == 4:
    src[y0:y1, x0:x1, 3] = 255
# LEDs apagados: el juego los enciende por encima (LEDS_X / LEDS_Y en interfaz.gd)
LEDS_X = [110, 141, 172, 203, 235, 266, 297, 329, 360]
LEDS_Y = 537
oscuro = np.array([10, 15, 12], np.float32)  # BGR de la cavidad
mglow = np.zeros(src.shape[:2], np.float32)
for lx in LEDS_X:
    cv2.rectangle(mglow, (lx - 17, LEDS_Y - 19), (lx + 17, LEDS_Y + 19), 1.0, -1)
mglow = cv2.GaussianBlur(mglow, (0, 0), 5)[..., None]
src[..., :3] = (src[..., :3] * (1 - mglow * 0.93) + oscuro * mglow * 0.93).clip(0, 255).astype(np.uint8)
for lx in LEDS_X:  # carcasa del LED apagado
    cv2.rectangle(src, (lx - 8, LEDS_Y - 9), (lx + 8, LEDS_Y + 9), (28, 36, 31, 255), -1)
    cv2.rectangle(src, (lx - 8, LEDS_Y - 9), (lx + 8, LEDS_Y + 9), (16, 22, 18, 255), 1)
nw = 320
out = cv2.resize(src, (nw, int(h * nw / w)), interpolation=cv2.INTER_AREA)
cv2.imwrite(dst, out)
print("sprite", out.shape[1], "x", out.shape[0], "LCD rel:", (x0 / w, y0 / h, (x1 - x0) / w, (y1 - y0) / h))
