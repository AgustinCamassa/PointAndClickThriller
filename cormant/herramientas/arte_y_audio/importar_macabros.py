"""Importa los fondos «macabros» (los que se muestran mientras hay una anomalía) y los dos cuadros del laboratorio.

Uso:  python3 importar_macabros.py CARPETA_ORIGINALES [CARPETA_ASSETS]
CARPETA_ORIGINALES (PNG 1672x941; los cuadros, 1376x768):
  recepcion, recepcion_reverso, laboratorio, ventana_recepcion, oficina, pasillo_secreto, vigilancia (.png)
  cuadro, cuadro_macabro (.jpg o .png)
Genera:
  assets/fondos/<sala>_macabro.png (1280x720) y assets/fondos/cam_1_macabro.png (laboratorio macabro con el filtro verde de la CAM 1)
  assets/sprites/cuadro.png y cuadro_macabro.png (los dos cuadros, con la paleta del juego y un marco)
Retoques:
  1. Alinea cada fondo con el original de la sala (misma posición de puertas, mostradores y monitores): perfil vertical de
     desplazamientos con flujo óptico, para que al pasar a la versión macabra la sala no «salte» y las zonas clicables sigan valiendo.
  2. Gradúa el color al de la sala normal: ajusta el brillo medio y desplaza los tonos neutros hacia el gris frío del juego;
     la sangre y los colores saturados no se tocan.
  3. Vigilancia: repinta los tres monitores con los feeds del juego y los rótulos CAM 01 / CAM 02 / CAM 03 (la imagen traía CAM 01 / 03 / 04).
  4. Cuadros: pasa la pintura a la paleta fría y apagada del laboratorio y le pone marco.
Después, `python3 fondos_apagon.py` genera las versiones de apagón (<sala>_macabro_apagon.png).
Requiere Pillow, numpy, scipy y opencv-python."""
import sys, os
import numpy as np, cv2
from scipy.ndimage import gaussian_filter1d

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importar_fondos as imp

W, H = 1280, 720
SALAS = ["recepcion", "recepcion_reverso", "laboratorio", "ventana_recepcion", "oficina", "pasillo_secreto", "vigilancia"]
UMBRAL_ALINEAR = 10.0   # px: si el desplazamiento vertical máximo no llega a esto, no se alinea
# Pantallas de los tres monitores de Vigilancia en el fondo macabro (1280x720)
PANTALLAS_MACABRO = [(396, 326, 536, 417), (551, 326, 694, 417), (708, 328, 845, 414)]


def leer(carpeta, nombre):
    for ext in (".png", ".jpg", ".jpeg"):
        ruta = os.path.join(carpeta, nombre + ext)
        if os.path.exists(ruta):
            return cv2.imread(ruta)
    raise FileNotFoundError(os.path.join(carpeta, nombre + ".png"))


# --- alineación ------------------------------------------------------------------------------------
def _prep(im):
    g = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY)
    return cv2.GaussianBlur(cv2.createCLAHE(3.0, (8, 8)).apply(g), (0, 0), 2.0)


def perfil_dy(ref, nuevo, sigma=18):
    """Desplazamiento vertical medio por fila (flujo óptico de la sala normal a la macabra), suavizado."""
    a, b = _prep(ref), _prep(nuevo)
    flujo = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM).calc(a, b, None)
    v = flujo[..., 1]
    peso = np.hypot(cv2.Sobel(a, cv2.CV_32F, 1, 0), cv2.Sobel(a, cv2.CV_32F, 0, 1))
    dy = np.full(a.shape[0], np.nan, np.float32)
    for y in range(a.shape[0]):
        if peso[y].sum() < 1e-3:
            continue
        idx = np.argsort(v[y])
        acum = np.cumsum(peso[y][idx])
        dy[y] = v[y][idx][np.searchsorted(acum, acum[-1] / 2)]   # mediana ponderada por el contraste
    malos = np.isnan(dy)
    if malos.any():
        dy[malos] = np.interp(np.flatnonzero(malos), np.flatnonzero(~malos), dy[~malos])
    return gaussian_filter1d(dy, sigma, mode="nearest")


def alinear(ref, nuevo):
    dy = perfil_dy(ref, nuevo)
    if np.abs(dy).max() < UMBRAL_ALINEAR:
        return nuevo, dy
    h, w = nuevo.shape[:2]
    mapa_y = (np.arange(h, dtype=np.float32) + dy)[:, None].repeat(w, 1)
    mapa_x = np.arange(w, dtype=np.float32)[None, :].repeat(h, 0)
    return cv2.remap(nuevo, mapa_x, mapa_y, cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT), dy


# --- graduación de color ---------------------------------------------------------------------------
def _lab(im):
    lab = cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(np.float32)
    return lab[..., 0] * 100 / 255, lab[..., 1] - 128, lab[..., 2] - 128


def estadisticas(im):
    L, a, b = _lab(im)
    neutro = np.hypot(a, b) < 10
    return L.mean(), a[neutro].mean(), b[neutro].mean()


def graduar(nuevo, ref):
    """Brillo medio y tono de los neutros como los de `ref`; lo saturado (la sangre) se queda como está."""
    Lr, ar, br = estadisticas(ref)
    _, an, bn = estadisticas(nuevo)
    L, a, b = _lab(nuevo)
    lo, hi = 0.4, 2.5
    for _ in range(30):                       # gamma que iguala el brillo medio
        g = (lo * hi) ** 0.5
        if (100 * (L / 100) ** g).mean() > Lr:
            lo = g
        else:
            hi = g
    L2 = 100 * (L / 100) ** g
    w = 1 - np.clip((np.hypot(a, b) - 8) / 14, 0, 1)
    w = w * w * (3 - 2 * w)                   # 1 en los neutros, 0 en la sangre
    out = np.dstack([L2 * 255 / 100, a + w * (ar - an) + 128, b + w * (br - bn) + 128]).clip(0, 255).astype(np.uint8)
    return cv2.cvtColor(out, cv2.COLOR_LAB2BGR)


# --- Vigilancia: monitores -------------------------------------------------------------------------
def repintar_monitores(img, cam1, cam2):
    imp.PANTALLAS = PANTALLAS_MACABRO
    return imp.pantallas_vigilancia(img, cam1, cam2)


# --- cuadros ---------------------------------------------------------------------------------------
CUADRO_W, CUADRO_H, MARCO = 280, 152, 5   # 140x76 px en pantalla (zona «cuadro» del laboratorio), a 2x


def graduar_cuadro(img, ref_lab, params=None):
    """Pintura cálida y brillante -> paleta apagada del laboratorio. `params` (gamma, ganancia) se reutiliza en el cuadro hermano."""
    L, a, b = _lab(img)
    _, ar, br = estadisticas(ref_lab)
    if params is None:
        gamma, ganancia = 1.35, 0.86
        # brillo medio objetivo: algo más claro que la pared (L~10) para que se lea, sin parecer una pantalla
        for _ in range(30):
            if (100 * (L / 100) ** gamma * ganancia).mean() > 17.0:
                gamma += 0.03
            else:
                break
        params = (gamma, ganancia)
    gamma, ganancia = params
    L2 = 100 * (L / 100) ** gamma * ganancia
    a2 = a * 0.30 + ar + 1.5      # casi gris, con el verde-grisáceo de la sala
    b2 = b * 0.30 + br + 1.0
    out = np.dstack([L2 * 255 / 100, a2 + 128, b2 + 128]).clip(0, 255).astype(np.uint8)
    return cv2.cvtColor(out, cv2.COLOR_LAB2BGR), params


def con_marco(pintura):
    """Recorta la pintura a la proporción del marco, la escala y dibuja un marco oscuro con bisel."""
    iw, ih = CUADRO_W - 2 * MARCO, CUADRO_H - 2 * MARCO
    h, w = pintura.shape[:2]
    alto = round(w * ih / iw)
    y0 = max(0, (h - alto) // 2)
    p = cv2.resize(pintura[y0:y0 + alto], (iw, ih), interpolation=cv2.INTER_AREA)
    out = np.zeros((CUADRO_H, CUADRO_W, 3), np.uint8)
    out[:] = (24, 26, 28)                                  # marco
    cv2.rectangle(out, (0, 0), (CUADRO_W - 1, CUADRO_H - 1), (52, 55, 58), 1)    # bisel exterior claro
    cv2.rectangle(out, (MARCO - 2, MARCO - 2), (CUADRO_W - MARCO + 1, CUADRO_H - MARCO + 1), (10, 11, 12), 1)  # sombra interior
    out[MARCO:MARCO + ih, MARCO:MARCO + iw] = p
    # viñeta suave dentro del cuadro (la luz de la sala no llega a las esquinas)
    yy, xx = np.mgrid[0:ih, 0:iw].astype(np.float32)
    r = np.sqrt(((xx - iw / 2) / (iw / 2)) ** 2 + ((yy - ih / 2) / (ih / 2)) ** 2)
    v = (1 - 0.32 * np.clip(r - 0.55, 0, 1))[..., None]
    out[MARCO:MARCO + ih, MARCO:MARCO + iw] = (out[MARCO:MARCO + ih, MARCO:MARCO + iw] * v).astype(np.uint8)
    return out


# --- principal -------------------------------------------------------------------------------------
def main(orig, dest):
    fondos = os.path.join(dest, "fondos")
    sprites = os.path.join(dest, "sprites")
    os.makedirs(fondos, exist_ok=True)
    os.makedirs(sprites, exist_ok=True)

    def guardar(carpeta, nombre, img):
        cv2.imwrite(os.path.join(carpeta, nombre + ".png"), img, [cv2.IMWRITE_PNG_COMPRESSION, 9])
        print("  ", nombre, img.shape[1], "x", img.shape[0])

    salida = {}
    for sala in SALAS:
        ref = cv2.imread(os.path.join(fondos, sala + ".png"))
        nuevo = cv2.resize(leer(orig, sala), (W, H), interpolation=cv2.INTER_AREA)
        nuevo, dy = alinear(ref, nuevo)
        salida[sala] = graduar(nuevo, ref)
        print(sala, "desplazamiento vertical máx.: %.0f px" % np.abs(dy).max())
    # Vigilancia: monitores con los mismos feeds que el fondo normal
    cam1 = cv2.imread(os.path.join(fondos, "cam_1.png"))
    cam2 = cv2.imread(os.path.join(fondos, "cam_2.png"))
    salida["vigilancia"] = repintar_monitores(salida["vigilancia"], cam1, cam2)
    for sala, img in salida.items():
        guardar(fondos, sala + "_macabro", img)
    # CAM 1 macabra (mismo recorte que la normal)
    guardar(fondos, "cam_1_macabro", imp.feed_camara(salida["laboratorio"], (80, 60, 1200, 620)))
    # Cuadros
    ref_lab = cv2.imread(os.path.join(fondos, "laboratorio.png"))
    normal, params = graduar_cuadro(leer(orig, "cuadro"), ref_lab)
    macabro, _ = graduar_cuadro(leer(orig, "cuadro_macabro"), ref_lab, params)
    guardar(sprites, "cuadro", con_marco(normal))
    guardar(sprites, "cuadro_macabro", con_marco(macabro))


if __name__ == "__main__":
    carpeta = sys.argv[1]
    destino = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets")
    main(carpeta, destino)
