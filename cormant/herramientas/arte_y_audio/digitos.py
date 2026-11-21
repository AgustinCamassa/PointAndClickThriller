"""Genera assets/sprites/digitos.png: los dígitos 0-9 en una sola tira (10 casillas de 64x96) con aspecto de pantalla CRT.
Se usan para el correo de la recepción y el teclado de la puerta de Vigilancia: una sola textura sirve para cualquier PIN.
Uso: python3 digitos.py [DESTINO.png]"""
import sys, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

CW, CH = 64, 96
dst = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites", "digitos.png")
fuente = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", 84)
tira = Image.new("RGBA", (CW * 10, CH), (0, 0, 0, 0))
for n in range(10):
    capa = Image.new("L", (CW, CH), 0)
    d = ImageDraw.Draw(capa)
    caja = d.textbbox((0, 0), str(n), font=fuente)
    d.text(((CW - (caja[2] - caja[0])) / 2 - caja[0], (CH - (caja[3] - caja[1])) / 2 - caja[1]), str(n), font=fuente, fill=255)
    brillo = np.array(capa.filter(ImageFilter.GaussianBlur(3)), np.float32) / 255.0
    nitido = np.array(capa, np.float32) / 255.0
    a = np.clip(nitido + brillo * 0.55, 0, 1)
    rgb = np.zeros((CH, CW, 3), np.float32)
    rgb[..., 0] = 0.55 + 0.4 * nitido
    rgb[..., 1] = 1.0 * (0.75 + 0.25 * nitido)
    rgb[..., 2] = 0.6 + 0.3 * nitido
    img = np.dstack([np.clip(rgb, 0, 1), a]) * 255
    tira.paste(Image.fromarray(img.astype(np.uint8), "RGBA"), (n * CW, 0))
tira.save(dst)
print("ok", dst)
