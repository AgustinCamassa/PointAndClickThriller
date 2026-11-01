from lib import *
from escenas1 import ROJO, MARRON, AZUL, MORADO, reloj, planta

def laboratorio(camara=None):
    """camara: None = vista normal; 'a'/'b' = ángulos de cámara (sin cuadro)."""
    c = Lienzo(seed=41)
    habitacion(c, (58, 78, 72), (40, 52, 50), 140)
    for x in (70, 160, 250):
        lampara_techo(c, x, 8, 44, (190, 235, 215), 0.5)
    # puerta roja a la oficina
    puerta(c, 22, 47, 37, 95, ROJO)
    rotulo(c, 40, 38, "OFICINA")
    # encimera del fondo con el terminal CRT
    c.rect(96, 74, 158, 5, (150, 158, 156)); c.rect(96, 74, 158, 1, (210, 218, 214))
    c.rect(98, 79, 154, 22, (50, 58, 58)); c.linea(150, 79, 150, 100, (34, 40, 40)); c.linea(200, 79, 200, 100, (34, 40, 40))
    for x in (110, 160, 210):
        c.rect(x, 86, 12, 2, (120, 128, 126))
    crt(c, 126, 34, 60, 40, (34, 140, 82), carcasa=(118, 114, 100), brillo=0.7, base=False)
    lineas_texto(c, 133, 42, 44, 8, (130, 250, 170), 3, 7)
    c.rect(133, 69, 5, 1, (240, 250, 240))
    # estantería con muestras a la derecha del terminal
    c.rect(196, 58, 52, 3, (150, 158, 156))
    for i, col in enumerate([(120, 160, 90), (170, 150, 80), (90, 140, 170), (150, 90, 90), (160, 160, 160)]):
        c.rect(200+i*9, 50, 6, 8, mul(col, 0.8)); c.rect(200+i*9, 50, 6, 1, col)
    # cuadro: solo el clavo (el sprite se coloca desde el juego)
    if camara is None:
        c.rect(235, 22, 3, 3, (180, 180, 170))
    # frasco en la mesita izquierda
    c.rect(70, 132, 50, 4, (140, 146, 144)); c.rect(74, 136, 3, 24, (70, 76, 74)); c.rect(113, 136, 3, 24, (70, 76, 74))
    c.rect(86, 100, 22, 32, (120, 140, 150)); c.rect(88, 102, 18, 28, (36, 44, 48))
    c.rect(88, 112, 18, 18, (118, 120, 118)); c.rect(88, 112, 18, 2, (170, 172, 168))
    c.rect(85, 96, 24, 6, (60, 64, 68)); c.rect(86, 96, 22, 1, (110, 116, 120))
    c.rect(90, 118, 14, 8, (214, 210, 190)); lineas_texto(c, 91, 120, 11, 2, (70, 60, 60), 3, 2)
    c.rect(88, 102, 3, 28, (200, 220, 230))
    c.foco(97, 118, 24, 28, (150, 160, 160), 0.2)
    # mesa central de operaciones
    c.rect(118, 112, 108, 9, (176, 184, 184)); c.rect(118, 112, 108, 1, (230, 238, 238))
    c.rect(118, 121, 108, 2, (90, 96, 96))
    for x in (122, 166, 218):
        c.rect(x, 123, 4, 20, (90, 98, 98))
    c.rect(140, 106, 56, 6, (210, 214, 206))          # sábana
    c.linea(142, 108, 192, 108, (160, 164, 156))
    for sx in (134, 198, 208):
        c.rect(sx, 108, 2, 4, (60, 40, 30))             # correas
    c.foco(172, 108, 66, 14, (200, 240, 220), 0.4)
    # casco neuronal sobre soporte
    c.rect(251, 118, 3, 24, (110, 116, 118)); c.rect(244, 141, 17, 3, (80, 86, 88))
    c.elipse(236, 92, 34, 28, (84, 90, 100)); c.elipse(238, 94, 30, 24, (60, 66, 76))
    c.rect(236, 106, 34, 14, (20, 26, 30)); c.rect(236, 106, 34, 1, (110, 116, 126))
    for ex in (240, 247, 254, 261):
        c.rect(ex, 94, 3, 3, (210, 190, 90))
    c.linea(252, 118, 252, 138, (30, 30, 34)); c.linea(262, 116, 275, 130, (30, 30, 34)); c.linea(275, 130, 282, 142, (30, 30, 34))
    c.foco(253, 100, 24, 20, (190, 220, 255), 0.2)
    # extras: armario, cables
    c.rect(284, 60, 28, 82, (92, 100, 104)); c.rect(284, 60, 2, 82, (150, 158, 160)); c.borde(284, 60, 28, 82, (50, 56, 58))
    c.linea(298, 60, 298, 141, (50, 56, 58)); c.rect(293, 100, 3, 4, (20, 20, 20)); c.rect(300, 100, 3, 4, (20, 20, 20))
    c.rect(236, 150, 60, 1, (24, 28, 28))
    c.foco(155, 56, 100, 40, (80, 220, 140), 0.25)
    if camara:
        return c
    return c.final(ambiente=1.0, vineta=0.6)

def oficina():
    c = Lienzo(seed=51)
    habitacion(c, (92, 80, 66), (58, 48, 40), 142, zocalo=(60, 48, 38))
    lampara_techo(c, 90, 8, 36, (255, 220, 160), 0.45)
    lampara_techo(c, 230, 8, 36, (255, 220, 160), 0.35)
    # puerta roja al laboratorio (izquierda)
    puerta(c, 7, 95, 27, 60, ROJO)
    c.rect(5, 90, 31, 4, (60, 30, 30))
    # tablero INCIDENTE 14-B
    c.rect(45, 38, 59, 46, (70, 54, 40)); c.rect(47, 40, 55, 42, (150, 112, 76)); c.ruido(47, 40, 55, 42, 0.15, 0.2)
    c.rect(49, 43, 40, 29, (225, 222, 208)); c.texto_px(51, 46, "INCIDENTE", (160, 30, 30)); c.texto_px(51, 54, "14-B", (50, 40, 40), 2)
    lineas_texto(c, 51, 63, 22, 2, (120, 120, 120), 3, 5)
    c.poli([(49, 72), (89, 72), (84, 76), (78, 72), (70, 77), (62, 72), (55, 76)], (225, 222, 208))   # borde arrancado
    c.rect(92, 46, 9, 11, (220, 210, 150)); c.rect(92, 60, 9, 12, (200, 215, 225))
    c.rect(66, 41, 2, 2, (200, 30, 30))
    # reloj de la oficina
    reloj(c, 125, 30, 8, 10, 10)
    # ventana al pasillo secreto
    c.rect(198, 40, 66, 54, (60, 52, 44)); c.rect(201, 43, 60, 48, (14, 12, 20))
    c.rect(201, 74, 60, 17, (24, 20, 30)); c.rect(236, 54, 14, 34, (60, 30, 76)); c.rect(236, 54, 14, 1, (130, 80, 150))
    c.linea(201, 91, 250, 43, (40, 36, 50)); c.rect(198, 94, 66, 3, (80, 70, 58))
    c.foco(232, 70, 40, 34, (130, 90, 170), 0.25)
    # puerta azul sin picaporte
    puerta(c, 272, 47, 32, 95, AZUL, picaporte=False)
    c.rect(293, 92, 3, 3, (30, 40, 70))     # solo el hueco
    # mostrador con documentos
    c.rect(92, 108, 100, 5, (170, 150, 120)); c.rect(92, 108, 100, 1, (220, 205, 175))
    c.rect(94, 113, 96, 29, (78, 60, 44)); c.linea(94, 113, 94, 141, (110, 84, 60))
    for x in (126, 158):
        c.linea(x, 113, x, 141, (56, 42, 30))
    c.ruido(94, 113, 96, 29, 0.12, 0.15)
    for (x, y, w, col) in [(100, 103, 22, (228, 226, 212)), (112, 101, 20, (216, 214, 198)), (146, 104, 24, (230, 224, 205)), (158, 105, 18, (206, 200, 180))]:
        c.rect(x, y, w, 5, col); c.rect(x, y, w, 1, mul(col, 1.15))
    c.rect(176, 96, 8, 12, (60, 62, 68)); c.rect(172, 92, 16, 5, (200, 160, 70))   # lámpara de mesa
    c.foco(180, 98, 40, 30, (255, 210, 120), 0.5)
    c.rect(106, 99, 5, 4, (200, 60, 50))
    # archivadores / sillas
    c.rect(50, 112, 30, 30, (98, 86, 70)); c.rect(50, 112, 30, 2, (150, 134, 110)); c.rect(58, 120, 14, 3, (30, 26, 22))
    c.foco(150, 70, 110, 60, (255, 200, 140), 0.18)
    return c.final(ambiente=1.0, vineta=0.6)

def habitacion_secreta():
    c = Lienzo(seed=61)
    habitacion(c, (84, 96, 92), (60, 64, 62), 142, zocalo=(50, 58, 56))
    # azulejos clínicos
    for x in range(0, 320, 10):
        c.linea(x, 10, x, 138, (74, 86, 82))
    for y in range(10, 138, 10):
        c.linea(0, y, 320, y, (74, 86, 82))
    c.ruido(0, 10, 320, 130, 0.10, 0.18)
    lampara_techo(c, 150, 8, 50, (210, 235, 220), 0.55)
    lampara_techo(c, 40, 8, 30, (210, 235, 220), 0.12, apagada=True)
    # reloj y calendario que no coinciden con los de la oficina
    reloj(c, 155, 36, 7, 4, 47)
    c.rect(180, 22, 27, 32, (216, 212, 196)); c.rect(180, 22, 27, 7, (170, 40, 40))
    c.texto_px(183, 24, "MAR", (240, 220, 220)); c.texto_px(184, 34, "3", (40, 40, 44), 3)
    # marcas rascadas en la pared
    for i in range(14):
        c.linea(20+(i//5)*14+(i % 5)*2, 100, 20+(i//5)*14+(i % 5)*2, 112, (40, 46, 44))
    for g in range(3):
        c.linea(18+g*14, 112, 28+g*14, 100, (40, 46, 44))
    # monitor de pulso en soporte
    c.rect(60, 90, 3, 52, (110, 116, 118)); c.rect(52, 140, 19, 3, (80, 86, 88))
    c.rect(44, 52, 40, 38, (36, 38, 42)); c.borde(44, 52, 40, 38, (110, 116, 120))
    c.rect(47, 55, 34, 22, (6, 18, 10))
    pts = [(47, 66), (54, 66), (56, 60), (58, 71), (60, 64), (62, 66), (81, 66)]
    for a, b in zip(pts, pts[1:]):
        c.linea(a[0], a[1], b[0], b[1], (80, 255, 120))
    c.texto_px(48, 56, "72", (80, 255, 120)); c.rect(50, 82, 6, 3, (200, 40, 40)); c.rect(60, 82, 6, 3, (60, 60, 66))
    c.foco(64, 66, 34, 28, (80, 255, 120), 0.4)
    # camilla con sábana hundida y correas sueltas
    c.rect(104, 124, 108, 6, (130, 136, 138)); c.rect(104, 124, 108, 1, (200, 206, 208))
    for x in (108, 204):
        c.rect(x, 130, 4, 12, (90, 96, 98))
    c.rect(106, 116, 104, 9, (206, 202, 186)); c.rect(106, 116, 104, 1, (236, 232, 214))
    c.rect(150, 120, 40, 4, (176, 172, 156))          # hundimiento
    c.rect(108, 112, 24, 6, (226, 222, 206))          # almohada
    for sx in (140, 170, 196):
        c.linea(sx, 116, sx+4, 128, (60, 44, 34)); c.linea(sx+4, 128, sx+3, 134, (60, 44, 34))
    c.foco(158, 118, 60, 20, (220, 240, 225), 0.35)
    # gotero
    c.rect(214, 86, 2, 56, (150, 156, 158)); c.rect(208, 86, 14, 2, (150, 156, 158)); c.rect(210, 88, 8, 12, (200, 220, 230))
    # puerta morada (hacia el pasillo)
    puerta(c, 265, 45, 35, 95, MORADO, cristal=(8, 8, 19, 20))
    c.rect(268, 54, 29, 20, (14, 12, 20))
    c.rect(262, 90, 3, 2, (230, 40, 40))
    # algo que no va bien: mancha y cámara en el rincón
    c.elipse(120, 70, 18, 26, (60, 70, 66)); c.ruido(120, 70, 18, 26, 0.3, 0.2)
    c.rect(300, 14, 12, 8, (30, 30, 34)); c.rect(302, 16, 4, 4, (200, 30, 30))
    return c.final(ambiente=1.0, vineta=0.6)

def pasillo_secreto():
    c = Lienzo(220, 130, seed=71)
    habitacion(c, (58, 50, 70), (36, 32, 44), 98, panel=True)
    lampara_techo(c, 60, 4, 30, (190, 170, 230), 0.4)
    lampara_techo(c, 150, 4, 30, (190, 170, 230), 0.2, apagada=True)
    puerta(c, 155, 22, 38, 90, MORADO)
    c.rect(158, 28, 32, 15, (40, 36, 46)); c.borde(158, 28, 32, 15, (110, 100, 130))   # placa en blanco (el juego escribe el texto)
    c.foco(174, 70, 40, 50, (160, 90, 200), 0.3)
    c.cono(60, 7, 100, 30, 90, (190, 170, 230), 0.35)
    c.rect(10, 70, 30, 3, (110, 100, 130))
    return c.final(ambiente=1.0, vineta=0.6)

def titulo():
    c = Lienzo(seed=81)
    c.degradado(0, 0, 320, 120, (8, 12, 22), (30, 40, 62))
    rng = random.Random(3)
    for i in range(70):
        c.px(rng.randint(0, 319), rng.randint(0, 60), (200, 210, 235) if rng.random() < 0.3 else (110, 120, 150))
    # niebla y suelo
    c.degradado(0, 120, 320, 60, (22, 28, 42), (6, 8, 12))
    # edificio principal (administrativo)
    c.rect(20, 94, 280, 62, (22, 26, 36)); c.rect(20, 94, 280, 2, (60, 68, 86))
    c.rect(10, 70, 90, 86, (26, 30, 42)); c.rect(10, 70, 90, 2, (70, 78, 98))
    c.rect(230, 60, 70, 96, (24, 28, 40)); c.rect(230, 60, 70, 2, (66, 74, 94))
    # ventanas
    for bx, by, ncol, nfil in [(14, 76, 7, 6), (30, 100, 15, 4), (234, 66, 5, 7)]:
        for j in range(nfil):
            for i in range(ncol):
                x, y = bx+i*(12 if bx != 30 else 17), by+j*(12)
                lit = rng.random() < 0.06
                c.rect(x, y, 7, 7, (232, 190, 96) if lit else (12, 16, 24))
                if lit:
                    c.foco(x+3, y+3, 18, 16, (255, 200, 100), 0.5)
    # ventana encendida más grande (la oficina)
    c.rect(268, 100, 12, 9, (240, 200, 110)); c.foco(274, 104, 40, 30, (255, 200, 100), 0.7)
    # puerta con luz
    c.rect(150, 128, 20, 28, (210, 200, 160)); c.foco(160, 140, 60, 40, (255, 240, 190), 0.6)
    c.rect(130, 124, 60, 4, (50, 54, 66)); c.texto_px(143, 116, "CORMANT", (150, 160, 180))
    # valla
    for x in range(0, 320, 8):
        c.rect(x, 146, 1, 28, (6, 8, 10))
    c.rect(0, 150, 320, 1, (6, 8, 10)); c.rect(0, 168, 320, 1, (6, 8, 10))
    c.foco(160, 150, 180, 40, (120, 140, 180), 0.25)
    return c.final(ambiente=0.9, vineta=0.75)

if __name__ == "__main__":
    laboratorio().save("prev_laboratorio.png"); oficina().save("prev_oficina.png")
    habitacion_secreta().save("prev_habitacion_secreta.png"); pasillo_secreto().save("prev_pasillo_secreto.png"); titulo().save("prev_titulo.png")
