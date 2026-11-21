"""Genera PUNTOS y LINEAS de scripts/nucleo/glifos.gd a partir de posiciones reales (AR/Dec J2000) de las estrellas.
Seis constelaciones con 4, 5, 6, 7, 8 y 9 estrellas (la cantidad la da el número de pitidos de la CAM 3).
Proyección tangente centrada en la constelación, con el este a la izquierda como en el cielo; se normaliza a la caja unitaria.
Uso: python3 constelaciones.py   (imprime el bloque GDScript; con --escribir lo vuelca en glifos.gd)"""
import math, os, re, sys

H = lambda h, m, s: (h + m / 60 + s / 3600) * 15.0
D = lambda sg, d, m, s: sg * (d + m / 60 + s / 3600)

# id: (estrellas [(nombre, ar_grados, dec_grados, magnitud)], aristas por nombre)
DATOS = {
    "cruz_sur": ([("Gacrux", H(12, 31, 9.9), D(-1, 57, 6, 47), 1.64), ("Acrux", H(12, 26, 35.9), D(-1, 63, 5, 56), 0.77),
                  ("Mimosa", H(12, 47, 43.3), D(-1, 59, 41, 19), 1.25), ("Imai", H(12, 15, 8.7), D(-1, 58, 44, 56), 2.8)],
                 [("Gacrux", "Acrux"), ("Mimosa", "Imai")]),
    "andromeda": ([("Alpheratz", H(0, 8, 23.3), D(1, 29, 5, 26), 2.06), ("Delta", H(0, 39, 19.7), D(1, 30, 51, 40), 3.27),
                   ("Mirach", H(1, 9, 43.9), D(1, 35, 37, 14), 2.05), ("Almach", H(2, 3, 54.0), D(1, 42, 19, 47), 2.1),
                   ("Mu", H(0, 56, 45.2), D(1, 38, 29, 58), 3.87)],
                  [("Alpheratz", "Delta"), ("Delta", "Mirach"), ("Mirach", "Almach"), ("Mirach", "Mu")]),
    "lira": ([("Vega", H(18, 36, 56.3), D(1, 38, 47, 1), 0.03), ("Epsilon", H(18, 44, 20.3), D(1, 39, 40, 12), 4.7),
              ("Zeta", H(18, 44, 46.4), D(1, 37, 36, 18), 4.3), ("Delta", H(18, 54, 30.3), D(1, 36, 53, 55), 4.3),
              ("Sheliak", H(18, 50, 4.8), D(1, 33, 21, 46), 3.5), ("Sulafat", H(18, 58, 56.6), D(1, 32, 41, 22), 3.25)],
             [("Vega", "Epsilon"), ("Vega", "Zeta"), ("Epsilon", "Zeta"), ("Zeta", "Delta"), ("Zeta", "Sheliak"),
              ("Delta", "Sulafat"), ("Sheliak", "Sulafat")]),
    "ofiuco": ([("Rasalhague", H(17, 34, 56.1), D(1, 12, 33, 36), 2.1), ("Cebalrai", H(17, 43, 28.4), D(1, 4, 34, 2), 2.8),
                ("Kappa", H(16, 57, 40.1), D(1, 9, 22, 30), 3.2), ("Marfik", H(16, 30, 54.8), D(1, 1, 59, 2), 3.8),
                ("YedPrior", H(16, 14, 20.7), D(-1, 3, 41, 40), 2.7), ("Zeta", H(16, 37, 9.5), D(-1, 10, 34, 2), 2.6),
                ("Sabik", H(17, 10, 22.7), D(-1, 15, 43, 30), 2.4)],
               [("Kappa", "Rasalhague"), ("Rasalhague", "Cebalrai"), ("Cebalrai", "Sabik"), ("Sabik", "Zeta"),
                ("Zeta", "YedPrior"), ("YedPrior", "Marfik"), ("Marfik", "Kappa")]),
    "geminis": ([("Castor", H(7, 34, 36.0), D(1, 31, 53, 18), 1.6), ("Pollux", H(7, 45, 18.9), D(1, 28, 1, 34), 1.14),
                 ("Alhena", H(6, 37, 42.7), D(1, 16, 23, 57), 1.9), ("Mebsuta", H(6, 43, 55.9), D(1, 25, 7, 52), 3.0),
                 ("Tejat", H(6, 22, 57.6), D(1, 22, 30, 49), 2.9), ("Propus", H(6, 14, 52.7), D(1, 22, 30, 24), 3.3),
                 ("Wasat", H(7, 20, 7.4), D(1, 21, 58, 56), 3.5), ("Mekbuda", H(7, 4, 6.5), D(1, 20, 34, 13), 3.8)],
                [("Castor", "Mebsuta"), ("Mebsuta", "Tejat"), ("Tejat", "Propus"), ("Pollux", "Wasat"), ("Wasat", "Mekbuda"),
                 ("Mekbuda", "Alhena"), ("Mebsuta", "Wasat")]),
    "orion": ([("Meissa", H(5, 35, 8.3), D(1, 9, 56, 3), 3.3), ("Betelgeuse", H(5, 55, 10.3), D(1, 7, 24, 25), 0.5),
               ("Bellatrix", H(5, 25, 7.9), D(1, 6, 20, 59), 1.64), ("Mintaka", H(5, 32, 0.4), D(-1, 0, 17, 57), 2.2),
               ("Alnilam", H(5, 36, 12.8), D(-1, 1, 12, 7), 1.7), ("Alnitak", H(5, 40, 45.5), D(-1, 1, 56, 34), 1.77),
               ("Saiph", H(5, 47, 45.4), D(-1, 9, 40, 11), 2.06), ("Rigel", H(5, 14, 32.3), D(-1, 8, 12, 6), 0.13),
               ("Hatysa", H(5, 35, 26.0), D(-1, 5, 54, 36), 2.75)],
              [("Meissa", "Betelgeuse"), ("Meissa", "Bellatrix"), ("Betelgeuse", "Alnitak"), ("Bellatrix", "Mintaka"),
               ("Mintaka", "Alnilam"), ("Alnilam", "Alnitak"), ("Alnitak", "Saiph"), ("Mintaka", "Rigel"), ("Alnilam", "Hatysa")]),
}
ORDEN = ["cruz_sur", "andromeda", "lira", "ofiuco", "geminis", "orion"]   # de 4 a 9 estrellas
MARGEN = 0.08


def proyectar(estrellas):
    ar0 = sum(e[1] for e in estrellas) / len(estrellas)
    de0 = sum(e[2] for e in estrellas) / len(estrellas)
    pts = []
    for _, ar, de, _m in estrellas:
        d_ar = math.radians(ar - ar0); d = math.radians(de); d0 = math.radians(de0)
        c = math.sin(d0) * math.sin(d) + math.cos(d0) * math.cos(d) * math.cos(d_ar)
        x = math.cos(d) * math.sin(d_ar) / c
        y = (math.cos(d0) * math.sin(d) - math.sin(d0) * math.cos(d) * math.cos(d_ar)) / c
        pts.append((-x, -y))   # este a la izquierda, norte arriba (y de pantalla hacia abajo)
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    ancho = max(xs) - min(xs); alto = max(ys) - min(ys)
    esc = (1 - 2 * MARGEN) / max(ancho, alto)
    ox = 0.5 - (min(xs) + ancho / 2) * esc; oy = 0.5 - (min(ys) + alto / 2) * esc
    return [(p[0] * esc + ox, p[1] * esc + oy) for p in pts]


def generar():
    puntos, lineas = [], []
    for id_ in ORDEN:
        estrellas, aristas = DATOS[id_]
        assert len(estrellas) == 4 + ORDEN.index(id_), id_
        xy = proyectar(estrellas)
        nombres = [e[0] for e in estrellas]
        ps = ", ".join("Vector3(%.2f, %.2f, %.1f)" % (x, y, max(0.7, min(1.5, 1.55 - 0.22 * e[3]))) for (x, y), e in zip(xy, estrellas))
        ls = ", ".join("[%d, %d]" % (nombres.index(a), nombres.index(b)) for a, b in aristas)
        puntos.append('\t"%s": [%s],' % (id_, ps)); lineas.append('\t"%s": [%s],' % (id_, ls))
    return "const PUNTOS := {\n" + "\n".join(puntos) + "\n}\n", "const LINEAS := {\n" + "\n".join(lineas) + "\n}\n"


if __name__ == "__main__":
    p, l = generar()
    if "--escribir" in sys.argv:
        ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "scripts", "nucleo", "glifos.gd")
        s = open(ruta).read()
        s = re.sub(r"const PUNTOS := \{.*?\n\}\n", lambda m: p, s, flags=re.S)
        s = re.sub(r"const LINEAS := \{.*?\n\}\n", lambda m: l, s, flags=re.S)
        open(ruta, "w").write(s)
        print("escrito", ruta)
    else:
        print(p); print(l)
