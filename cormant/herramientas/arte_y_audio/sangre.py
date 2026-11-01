"""Texto escrito con sangre para el final del modo 3 -> assets/sprites/sangre_sabes_quien_soy.png
Letras irregulares (rotación/desplazamiento por letra), trazo grueso, goteo y brillo húmedo. Sin shaders."""
import os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

TEXTO = "Sabes quién soy..."
FUENTE = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-BoldItalic.ttf"
random.seed(14)
W, H = 1300, 260
capa = Image.new("RGBA", (W, H), (0, 0, 0, 0))
fuente = ImageFont.truetype(FUENTE, 96)
x = 28
posiciones = []
for ch in TEXTO:
    g = Image.new("RGBA", (170, 200), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    d.text((30, 30), ch, font=fuente, fill=(120, 6, 8, 255), stroke_width=2, stroke_fill=(92, 3, 5, 255))
    g = g.rotate(random.uniform(-9, 9), resample=Image.BICUBIC)
    dy = random.randint(-7, 7)
    capa.alpha_composite(g, (int(x - 30), 22 + dy))
    ancho = fuente.getlength(ch) + 7
    posiciones.append((x, ancho))
    x += ancho
# goteo: hilos finos con gota al final, sobre algunas letras
d = ImageDraw.Draw(capa)
for (px, ancho) in posiciones:
    if random.random() < 0.5 and ancho > 30:
        gx = int(px + random.uniform(0.25, 0.75) * ancho)
        y0 = 150
        largo = random.randint(20, 80)
        r = random.randint(3, 5)
        d.rectangle([gx - 2, y0, gx + 1, y0 + largo], fill=(112, 5, 7, 255))
        d.ellipse([gx - r, y0 + largo - r, gx + r - 1, y0 + largo + r + 2], fill=(112, 5, 7, 255))
# salpicaduras
for _ in range(26):
    sx, sy = random.randint(10, W - 10), random.randint(10, H - 40)
    r = random.randint(1, 4)
    d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(105, 4, 6, 220))
# bordes un poco blandos y brillo húmedo en el borde superior de cada trazo
suave = capa.filter(ImageFilter.GaussianBlur(0.9))
brillo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
a = suave.split()[3]
desplazada = a.transform((W, H), Image.AFFINE, (1, 0, 3, 0, 1, 4))
from PIL import ImageChops
borde = ImageChops.subtract(a, desplazada).point(lambda v: min(255, v * 2))
brillo.putalpha(borde)
brillo_color = Image.new("RGBA", (W, H), (210, 50, 40, 255))
brillo_color.putalpha(borde.point(lambda v: v // 2))
suave.alpha_composite(brillo_color)
recorte = suave.crop(suave.getbbox())
destino = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites", "sangre_sabes_quien_soy.png")
recorte.save(destino)
print(recorte.size)
