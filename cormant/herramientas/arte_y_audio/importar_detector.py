"""Prepara assets/sprites/detector.png a partir del modelo recortado del detector de señales (468x1040).
Uso: python3 importar_detector.py DETECTOR.png [DESTINO.png]
 - Invierte de lugar la antena (a la derecha) y la ruleta (a la izquierda): se refleja la parte superior, por encima del
   cuerpo, que es simétrico.
 - Apaga los 9 LEDs (el juego los enciende por encima según la compatibilidad: LEDS_X / LEDS_Y en interfaz.gd).
 - Borra la pantalla y pinta otra más grande: el marco lateral se reduce ~40 % y la pantalla crece un poco hacia arriba y
   abajo (el juego escribe encima las señales). Los botones ◀ ■ ▶ del dibujo quedan tal cual.
Imprime el rectángulo del LCD relativo al sprite (0-1), que usa interfaz.gd (const LCD_REL)."""
import sys
import numpy as np, cv2

LEDS_X = [107, 138, 169, 200, 231, 262, 293, 325, 356]
LEDS_Y = 528
CORTE_ANTENA = 468            # por encima: antena y ruleta (se reflejan); por debajo: cuerpo
BISEL = (43, 574, 441, 902)   # marco negro de la pantalla nueva (x0, y0, x1, y1)
LCD_INSET = 12
ANCHO_SALIDA = 360

src = cv2.imread(sys.argv[1], cv2.IMREAD_UNCHANGED)
dst = sys.argv[2] if len(sys.argv) > 2 else "../../assets/sprites/detector.png"
if src.shape[2] == 3:
    src = np.dstack([src, np.full(src.shape[:2], 255, np.uint8)])
h, w = src.shape[:2]

# 1) antena a la derecha, ruleta a la izquierda
src[:CORTE_ANTENA] = src[:CORTE_ANTENA, ::-1].copy()

# 2) LEDs apagados
oscuro = np.array([10, 15, 12], np.float32)
mglow = np.zeros((h, w), np.float32)
for lx in LEDS_X:
    cv2.rectangle(mglow, (lx - 17, LEDS_Y - 19), (lx + 17, LEDS_Y + 19), 1.0, -1)
mglow = cv2.GaussianBlur(mglow, (0, 0), 5)[..., None]
src[..., :3] = (src[..., :3] * (1 - mglow * 0.93) + oscuro * mglow * 0.93).clip(0, 255).astype(np.uint8)
for lx in LEDS_X:
    cv2.rectangle(src, (lx - 8, LEDS_Y - 9), (lx + 8, LEDS_Y + 9), (28, 36, 31, 255), -1)
    cv2.rectangle(src, (lx - 8, LEDS_Y - 9), (lx + 8, LEDS_Y + 9), (16, 22, 18, 255), 1)


# 3) pantalla grande (supermuestreo x4 para bordes suaves)
def rect_redondo(x0, y0, x1, y1, r):
    S = 4
    m = np.zeros((h * S, w * S), np.uint8)
    cv2.rectangle(m, ((x0 + r) * S, y0 * S), ((x1 - r) * S, y1 * S), 255, -1)
    cv2.rectangle(m, (x0 * S, (y0 + r) * S), (x1 * S, (y1 - r) * S), 255, -1)
    for cx, cy in [(x0 + r, y0 + r), (x1 - r, y0 + r), (x0 + r, y1 - r), (x1 - r, y1 - r)]:
        cv2.circle(m, (cx * S, cy * S), r * S, 255, -1)
    return cv2.resize(m, (w, h), interpolation=cv2.INTER_AREA).astype(np.float32)[..., None] / 255


bx0, by0, bx1, by1 = BISEL
mb = rect_redondo(bx0, by0, bx1, by1, 24)
src[..., :3] = (src[..., :3] * (1 - mb) + np.array([6, 8, 7], np.float32) * mb).clip(0, 255).astype(np.uint8)
lx0, ly0, lx1, ly1 = bx0 + LCD_INSET, by0 + LCD_INSET, bx1 - LCD_INSET, by1 - LCD_INSET
ml = rect_redondo(lx0, ly0, lx1, ly1, 14)
yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
cx, cy = (lx0 + lx1) / 2, (ly0 + ly1) / 2
rad = np.sqrt(((xx - cx) / ((lx1 - lx0) / 2)) ** 2 + ((yy - cy) / ((ly1 - ly0) / 2)) ** 2)
base = np.stack([8 + 6 * (1 - rad), 38 + 22 * (1 - rad), 14 + 8 * (1 - rad)], -1)   # BGR verde oscuro con brillo central
base[::3] *= 0.85
src[..., :3] = (src[..., :3] * (1 - ml) + base * ml).clip(0, 255).astype(np.uint8)
src[..., 3] = np.maximum(src[..., 3], (mb[..., 0] * 255).astype(np.uint8))

out = cv2.resize(src, (ANCHO_SALIDA, round(h * ANCHO_SALIDA / w)), interpolation=cv2.INTER_AREA)
cv2.imwrite(dst, out)
print("sprite", out.shape[1], "x", out.shape[0])
print("LCD rel:", (round(lx0 / w, 4), round(ly0 / h, 4), round((lx1 - lx0) / w, 4), round((ly1 - ly0) / h, 4)))
print("LEDs (px del original %dx%d):" % (w, h), LEDS_X, LEDS_Y)
