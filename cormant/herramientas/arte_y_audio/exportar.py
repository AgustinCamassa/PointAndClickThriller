"""Solo sprites provisionales (mancha y cuadro; Alicia sale de importar_personaje.py). Los fondos y cámaras los genera exportar3d.py (salas en perspectiva)."""
import os
import sprites as sp
DEST = "../../assets"
os.makedirs(DEST+"/sprites", exist_ok=True)
def guardar(img, ruta):
    img.save(os.path.join(DEST, ruta), optimize=True)
spr = {"mancha_suelo": sp.mancha()}
for n, im in spr.items():
    guardar(im, f"sprites/{n}.png")
print({n: im.size for n, im in spr.items()})
