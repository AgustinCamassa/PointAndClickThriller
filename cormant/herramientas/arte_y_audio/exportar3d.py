# OBSOLETO: generador de fondos provisionales (usa «Eric»). Los fondos actuales salen de importar_fondos.py y las zonas se escriben a mano.
import os, numpy as np
from PIL import Image, ImageOps, ImageDraw
from scipy.ndimage import map_coordinates, gaussian_filter
import salas3d as S
import escenas2 as e2
from persp import *

DEST = "../../assets"
GD = "../../scripts/nucleo/zonas_fondos.gd"
os.makedirs(DEST+"/fondos", exist_ok=True)

TAM_ERIC = {"de_espaldas": (120, 252), "sentado": (120, 200), "perfil": (112, 244), "tumbado": (104, 104), "levantandose": (148, 228)}

def v2(p):  # Vector2 en GDScript (recortado a la pantalla)
    return "Vector2(%.0f, %.0f)" % (min(1280, max(0, p[0])), min(720, max(0, p[1])))

def poly_gd(pts):
    return "[" + ", ".join(v2(p) for p in pts) + "]"

def eric_datos(s, pose=None):
    e = s.eric
    pose = e["pose"]
    if pose == "tumbado":
        x, y = s.p(e["X"], e["Y"], e["Z"])
        escala = e["alto_m"]*s.f/e["Z"]*4/TAM_ERIC[pose][1]
    else:
        x, y = s.p(e["X"], 0, e["Z"])
        escala = e["alto_m"]*s.f/e["Z"]*4/TAM_ERIC[pose][1]
    return pose, (x*4, y*4), escala

def aplicar_geom(im, caja, incl, voltear=False, resample=Image.LANCZOS):
    im = im.crop(caja)
    if voltear:
        im = ImageOps.mirror(im)
    im = im.resize((1000, 438), resample).rotate(incl, resample=Image.BICUBIC, expand=False)
    return im

def barril(a, k=-0.10):
    h, w = a.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    nx = (xs-w/2)/(w/2); ny = (ys-h/2)/(h/2)
    r2 = nx**2+ny**2
    sx = (nx*(1+k*r2))*(w/2)+w/2; sy = (ny*(1+k*r2))*(h/2)+h/2
    if a.ndim == 2:
        return map_coordinates(a, [sy, sx], order=1, mode="constant")
    return np.stack([map_coordinates(a[..., c], [sy, sx], order=1, mode="constant") for c in range(3)], axis=-1)

def posicion_en_camara(punto, caja, incl, tam_src=(1280, 720)):
    m = Image.new("L", tam_src, 0)
    ImageDraw.Draw(m).ellipse([punto[0]-10, punto[1]-10, punto[0]+10, punto[1]+10], fill=255)
    g = aplicar_geom(m, caja, incl, resample=Image.BILINEAR)
    a = barril(np.asarray(g, np.float32)/255.0)
    a = gaussian_filter(a, 3)
    y, x = np.unravel_index(np.argmax(a), a.shape)
    return x/a.shape[1], y/a.shape[0]

def camara(img, caja, incl=2.0, seed=0):
    im = aplicar_geom(img, caja, incl)
    a = barril(np.asarray(im, np.float32)/255.0)
    h, w = a.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    nx = (xs-w/2)/(w/2); ny = (ys-h/2)/(h/2)
    lum = (a[..., 0]*0.3+a[..., 1]*0.59+a[..., 2]*0.11)
    lum = np.clip((lum-0.03)*1.7, 0, 1)**0.85
    rng = np.random.RandomState(seed)
    lum += (rng.rand(h, w)-0.5)*0.05
    lum *= (1-0.12*((np.arange(h) % 3) == 0))[:, None]
    vign = 1-0.6*np.clip(np.sqrt(nx**2*0.6+ny**2*0.9)-0.5, 0, 1)
    lum = np.clip(lum*vign, 0, 1)
    out = np.stack([lum*0.62, lum*1.0, lum*0.7], axis=-1)
    return Image.fromarray((np.clip(out, 0, 1)*255).astype(np.uint8))

imgs, salas = {}, {}
for n, f in S.TODAS.items():
    im, s = f()
    imgs[n] = im; salas[n] = s
imgs["titulo"] = e2.titulo()
for n, im in imgs.items():
    if n == "pasillo_secreto":
        im = im  # ya es 880x520
    im.save(os.path.join(DEST, "fondos", n+".png"), optimize=True)

# ---- cámaras
CAJAS = {"cam_1": ("laboratorio", (250, 110, 1030, 452), 1.5, 3),
         "cam_2": ("pasillo", (0, 80, 1280, 561), -1.5, 2)}
camdat = {}
for n, (sala, caja, incl, sd) in CAJAS.items():
    camara(imgs[sala], (caja[0], caja[1], caja[0]+caja[2], caja[1]+caja[3]), incl, sd).save(os.path.join(DEST, "fondos", n+".png"), optimize=True)
    caja4 = (caja[0], caja[1], caja[0]+caja[2], caja[1]+caja[3])
    d = {}
    if sala == "laboratorio":
        z = salas[sala].zonas["cuadro"]
        cx = sum(p[0] for p in z)/4; cy = sum(p[1] for p in z)/4
        d["cuadro_centro"] = posicion_en_camara((cx, cy), caja4, incl)
        d["cuadro_ancho"] = (max(p[0] for p in z)-min(p[0] for p in z))/caja[2]
    if sala == "pasillo":
        mx, my = salas[sala].p(0.0, 0, 5.2)
        d["mancha_centro"] = posicion_en_camara((mx*4, my*4), caja4, incl)
        d["mancha_ancho"] = 1.2*salas[sala].f/5.2*4/caja[2]
    camdat[n] = d

# ---- silueta para la ventana de Vigilancia (vista de la recepción)
sr = salas["recepcion_reverso"]
pie = sr.p(0.0, 0, 7.2); cab = sr.p(0.0, 1.8, 7.2)
silueta_ventana = (pie[0]*4/1280, pie[1]*4/720, (pie[1]-cab[1])*4/720)

# ---- GDScript con zonas
L = ["class_name ZonasFondos",
     "## GENERADO por herramientas/arte_y_audio/exportar3d.py a partir de las salas en perspectiva. No editar a mano.",
     "## Polígonos en el espacio 1280x720 de cada fondo, posiciones de Eric y datos de las cámaras.", "",
     "const ZONAS := {"]
for n, s in salas.items():
    L.append('\t"%s": {' % n)
    for k, pts in s.zonas.items():
        L.append('\t\t"%s": %s,' % (k, poly_gd(pts)))
    L.append("\t},")
L.append("}\n")
L.append("## Eric por sala: pose, punto de los pies (1280x720) y escala respecto al tamaño base del sprite.")
L.append("const ERIC := {")
for n, s in salas.items():
    if hasattr(s, "eric"):
        pose, pies, esc = eric_datos(s)
        L.append('\t"%s": {"pose": "%s", "pos": %s, "escala": %.3f},' % (n, pose, v2(pies), esc))
L.append("}\n")
# Eric al despertar (de pie junto a la camilla)
sh = salas["habitacion_secreta"]
x, y = sh.p(1.0, 0, 3.0); esc = 1.75*sh.f/3.0*4/228
L.append("const ERIC_DESPIERTO := {\"pos\": %s, \"escala\": %.3f}\n" % (v2((x*4, y*4)), esc))
L.append("## Cámaras: posición relativa (0-1) del cuadro dentro de la vista del laboratorio.")
L.append("const CAMARAS := {")
for n, d in camdat.items():
    items = []
    for k, v in d.items():
        items.append('"%s": %s' % (k, ("Vector2(%.4f, %.4f)" % v) if isinstance(v, tuple) else "%.4f" % v))
    L.append('\t"%s": {%s},' % (n.replace("cam_", ""), ", ".join(items)))
L.append("}\n")
_pp = salas["pasillo"]; _mx, _my = _pp.p(0.0, 0, 5.2)
L.append("## Mancha del suelo del pasillo en el fondo de 1280x720: centro y ancho en píxeles.")
L.append("const MANCHA_PASILLO := {\"centro\": Vector2(%.1f, %.1f), \"ancho\": %.1f}\n" % (_mx*4, _my*4, 1.2*_pp.f/5.2*4))
L.append("## Silueta vista por la ventana de Vigilancia: pies (x, y) y alto, relativos (0-1) al cristal.")
L.append("const SILUETA_VENTANA := Vector3(%.4f, %.4f, %.4f)\n" % silueta_ventana)
sp = salas["pasillo_secreto"]
pie = sp.p(-0.45, 0, 3.8); cab = sp.p(-0.45, 1.8, 3.8)
L.append("## Silueta que asoma en el pasillo secreto (pies x, y y alto, relativos al cristal).")
L.append("const SILUETA_SECRETO := Vector3(%.4f, %.4f, %.4f)\n" % (pie[0]/sp.w, pie[1]/sp.h, (pie[1]-cab[1])/sp.h))
L.append("static func poligono(sala: String, zona: String) -> PackedVector2Array:\n\treturn PackedVector2Array(ZONAS.get(sala, {}).get(zona, []))\n")
L.append("static func rect(sala: String, zona: String) -> Rect2:\n\tvar p := poligono(sala, zona)\n\tif p.is_empty():\n\t\treturn Rect2()\n\tvar r := Rect2(p[0], Vector2.ZERO)\n\tfor v in p:\n\t\tr = r.expand(v)\n\treturn r\n")
open(GD, "w").write("\n".join(L))
print("hecho", camdat, silueta_ventana)
