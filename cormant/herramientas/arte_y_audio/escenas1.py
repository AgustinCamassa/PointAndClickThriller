from lib import *

ROJO = (122, 30, 34); MARRON = (96, 66, 42); AZUL = (38, 76, 140); MORADO = (104, 44, 128)

def planta(c, x, y):
    c.rect(x+3, y+16, 10, 10, (104, 66, 48)); c.rect(x+3, y+16, 10, 1, (150, 100, 70))
    for dx, dy, w, h in [(0, 4, 8, 14), (6, 0, 8, 18), (9, 6, 9, 12), (2, 8, 6, 8)]:
        c.elipse(x+dx, y+dy, w, h, (38, 84, 52))
        c.elipse(x+dx+1, y+dy+1, w-3, h-4, (58, 112, 66))

def reloj(c, cx, cy, r, h, m, borde=(150, 150, 150)):
    c.elipse(cx-r, cy-r, 2*r+1, 2*r+1, borde)
    c.elipse(cx-r+1, cy-r+1, 2*r-1, 2*r-1, (212, 208, 190))
    ah = math.radians((h % 12)*30 + m*0.5 - 90); am = math.radians(m*6 - 90)
    c.linea(cx, cy, int(cx+math.cos(ah)*r*0.5), int(cy+math.sin(ah)*r*0.5), (30, 30, 30))
    c.linea(cx, cy, int(cx+math.cos(am)*r*0.8), int(cy+math.sin(am)*r*0.8), (30, 30, 30))

def recepcion():
    c = Lienzo(seed=11)
    habitacion(c, (74, 86, 98), (54, 60, 68), 140)
    for x in (80, 160, 240):
        lampara_techo(c, x, 8, 44, (200, 225, 240), 0.55)
    # cartel CORMANT (cristal unidireccional)
    c.rect(115, 18, 90, 27, (96, 102, 110)); c.rect(117, 20, 85, 22, (10, 14, 20))
    c.borde(117, 20, 85, 22, (40, 46, 54))
    c.linea(125, 41, 150, 21, (22, 30, 40)); c.linea(150, 41, 175, 21, (22, 30, 40))
    t = "CORMANT"; tw = c.ancho_texto(t, 11)
    c.texto(160-tw//2, 22, t, (150, 160, 172), 11)
    c.texto_px(160-c.ancho_px("MEDICAL SYSTEMS")//2, 36, "MEDICAL SYSTEMS", (96, 106, 118))
    # tablón y reloj
    c.rect(62, 38, 38, 26, (96, 72, 50)); c.rect(64, 40, 34, 22, (150, 110, 74)); c.ruido(64, 40, 34, 22, 0.15, 0.2)
    c.rect(68, 43, 10, 13, (222, 220, 205)); c.rect(81, 45, 12, 9, (210, 200, 160)); c.rect(72, 52, 8, 9, (200, 215, 225))
    reloj(c, 228, 30, 8, 3, 14)
    # puerta izquierda (radio) y derecha (lector)
    puerta(c, 17, 55, 38, 85, MARRON)
    c.rect(19, 138, 34, 2, (240, 200, 100)); c.foco(36, 143, 26, 8, (255, 200, 90), 0.6)
    puerta(c, 205, 60, 30, 75, MARRON)
    c.rect(238, 84, 8, 13, (26, 28, 32)); c.rect(239, 85, 6, 5, (60, 64, 70)); c.rect(241, 92, 2, 2, (255, 40, 40))
    c.foco(242, 93, 16, 14, (255, 40, 40), 0.7)
    # puerta al pasillo
    rotulo(c, 271, 41, "PASILLO")
    puerta(c, 252, 52, 38, 88, ROJO)
    # extintor
    c.rect(193, 100, 7, 17, (170, 30, 30)); c.rect(194, 97, 5, 3, (40, 40, 40)); c.rect(194, 102, 2, 12, (220, 90, 90))
    # mostrador
    c.rect(80, 118, 136, 6, (156, 142, 120)); c.rect(80, 118, 136, 1, (200, 190, 168))
    c.rect(82, 124, 132, 21, (76, 62, 50))
    for x in range(82, 214, 22):
        c.linea(x, 124, x, 144, (58, 46, 38))
    c.rect(82, 144, 132, 2, (20, 18, 16)); c.ruido(82, 124, 132, 21, 0.1, 0.15)
    # ordenadores
    crt(c, 96, 96, 38, 23, (30, 120, 74), brillo=0.55, base=False)
    lineas_texto(c, 101, 101, 24, 5, (120, 230, 150), 3, 4)
    crt(c, 146, 96, 38, 23, (26, 42, 126), brillo=0.4, base=False)
    c.rect(160, 105, 10, 1, (150, 170, 255)); c.rect(163, 108, 4, 1, (150, 170, 255))
    c.rect(100, 120, 30, 2, (180, 176, 160)); c.rect(150, 120, 30, 2, (180, 176, 160))
    # teléfono y papeles
    c.rect(190, 112, 16, 6, (30, 32, 36)); c.rect(192, 110, 12, 3, (44, 46, 52)); c.rect(139, 118, 6, 1, (230, 230, 220))
    c.rect(186, 117, 10, 1, (230, 228, 215))
    planta(c, 60, 118)
    c.foco(115, 108, 40, 24, (110, 255, 150), 0.25)
    return c.final(ambiente=1.0)

def recepcion_reverso():
    c = Lienzo(seed=12)
    habitacion(c, (70, 82, 94), (52, 58, 66), 140)
    for x in (70, 160, 250):
        lampara_techo(c, x, 8, 44, (200, 225, 240), 0.5)
    # ventanales laterales con niebla
    for x in (88, 206):
        c.rect(x-2, 48, 30, 66, (58, 64, 72))
        c.degradado(x, 50, 26, 62, (170, 190, 205), (110, 130, 148))
        c.linea(x+13, 50, x+13, 111, (58, 64, 72))
        c.foco(x+13, 100, 30, 40, (150, 190, 220), 0.35)
    # puerta de entrada de cristal
    c.rect(136, 48, 48, 95, (50, 56, 64))
    c.degradado(140, 52, 18, 88, (190, 205, 218), (120, 140, 156))
    c.degradado(162, 52, 18, 88, (186, 202, 216), (116, 136, 152))
    c.rect(158, 52, 4, 88, (40, 44, 52))
    c.rect(150, 92, 2, 14, (190, 190, 190)); c.rect(166, 92, 2, 14, (190, 190, 190))
    c.foco(160, 112, 70, 50, (160, 200, 235), 0.5)
    c.rect(150, 40, 20, 5, (26, 30, 34)); c.texto_px(152, 41, "SALIDA", (80, 230, 120))
    # reflejo de luz en el suelo
    c.cono(160, 140, 178, 40, 120, (150, 190, 225), 0.35)
    # bancos de espera
    for bx in (18, 232):
        c.rect(bx, 118, 72, 5, (60, 62, 70)); c.rect(bx, 118, 72, 1, (110, 112, 124))
        for i in range(3):
            c.rect(bx+3+i*23, 110, 18, 9, (44, 62, 92)); c.rect(bx+3+i*23, 110, 18, 1, (90, 112, 150))
        c.rect(bx+4, 123, 3, 17, (30, 32, 36)); c.rect(bx+65, 123, 3, 17, (30, 32, 36))
    planta(c, 108, 118); planta(c, 196, 118)
    c.rect(26, 52, 24, 32, (190, 190, 180)); c.rect(28, 56, 20, 2, (80, 80, 90)); lineas_texto(c, 29, 62, 17, 6, (110, 110, 120), 3, 8)
    c.rect(270, 52, 24, 32, (200, 198, 188)); lineas_texto(c, 273, 57, 18, 7, (110, 110, 120), 3, 9)
    return c.final()

def pasillo(alterado=False):
    c = Lienzo(seed=21 if not alterado else 22)
    if not alterado:
        habitacion(c, (82, 90, 100), (60, 66, 74), 140, panel=True)
    else:
        habitacion(c, (92, 92, 66), (52, 50, 44), 140, panel=True, zocalo=(52, 52, 38))
    # tubería superior
    c.rect(0, 20, 320, 5, (96, 102, 108)); c.rect(0, 20, 320, 1, (170, 176, 182)); c.rect(0, 25, 320, 1, (40, 44, 48))
    for x in range(20, 320, 70):
        c.rect(x, 18, 3, 9, (60, 64, 70))
    lamparas = [50, 150, 250]
    for i, x in enumerate(lamparas):
        if alterado and i == 1:
            lampara_techo(c, x, 8, 40, (230, 230, 170), 0.2, apagada=True)
        else:
            lampara_techo(c, x, 8, 40, (210, 230, 235) if not alterado else (230, 225, 160),
                          0.5 if not (i == 1 and not alterado) else 0.38)
    if not alterado:
        rotulo(c, 36, 41, "RECEPCION"); puerta(c, 15, 50, 43, 90, ROJO)
        puerta(c, 75, 52, 35, 85, MARRON, cristal=(6, 8, 23, 34))
        # cristal empañado
        c.rect(81, 60, 23, 34, (170, 195, 212)); c.ruido(81, 60, 23, 34, 0.25, 0.15)
        for i in range(9):
            gx = 82+c.rng.randint(0, 21); gy = 62+c.rng.randint(0, 28)
            c.linea(gx, gy, gx, gy+c.rng.randint(2, 6), (230, 240, 248))
        c.foco(93, 77, 24, 28, (150, 200, 235), 0.3)
        rotulo(c, 146, 41, "VIGILANCIA"); puerta(c, 125, 50, 43, 90, ROJO)
        puerta(c, 190, 52, 35, 85, MARRON)
        # pared sucia con rectángulo limpio (donde hubo una placa)
        c.rect(230, 60, 20, 40, mul((82, 90, 100), 0.82)); c.ruido(230, 60, 20, 40, 0.3, 0.2)
        c.rect(234, 70, 12, 18, (110, 120, 132)); c.rect(235, 71, 1, 1, (30, 30, 34)); c.rect(244, 86, 1, 1, (30, 30, 34))
        rotulo(c, 272, 41, "LABORATORIO"); puerta(c, 250, 50, 45, 90, ROJO)
        c.rect(115, 90, 7, 18, (170, 30, 30)); c.rect(116, 87, 5, 3, (40, 40, 40))
    else:
        # estética alterada: azulejo sucio, puertas sin pintar, goteras
        puerta(c, 15, 50, 43, 90, MORADO)
        c.rect(115, 27, 36, 17, (90, 84, 60)); c.borde(115, 27, 36, 17, (160, 150, 110))
        c.texto_px(122, 32, "14-B", (230, 225, 190), 2)
        puerta(c, 252, 47, 38, 92, AZUL)
        c.rect(255+25, 92, 4, 3, (200, 200, 190))
        # manchas de humedad y azulejos rotos
        for i in range(8):
            mx = c.rng.randint(70, 240); my = c.rng.randint(30, 110)
            c.elipse(mx, my, c.rng.randint(8, 24), c.rng.randint(10, 30), mul((92, 92, 66), 0.7))
        for x in range(0, 320, 14):
            c.linea(x, 30, x, 136, mul((92, 92, 66), 0.9))
        for y in range(30, 136, 14):
            c.linea(0, y, 320, y, mul((92, 92, 66), 0.9))
        c.rect(180, 8, 40, 14, (20, 18, 16))                 # placa de techo caída
        c.linea(190, 22, 196, 40, (30, 30, 30)); c.linea(206, 22, 202, 48, (30, 30, 30))
        # camilla abandonada
        c.rect(100, 118, 70, 4, (130, 130, 134)); c.rect(104, 122, 3, 20, (80, 80, 86)); c.rect(163, 122, 3, 20, (80, 80, 86))
        c.rect(100, 114, 70, 4, (150, 146, 130))
        # huellas hacia la puerta azul (sobre el suelo)
        for i in range(11):
            fx = 40 + i*19; fy = 150 - int(i*0.9) + (4 if i % 2 else 0)
            c.elipse(fx, fy, 7, 4, (22, 34, 66)); c.elipse(fx+1, fy+1, 5, 2, (70, 110, 190))
            c.elipse(fx+7, fy-3 if i % 2 else fy+3, 3, 2, (70, 110, 190))
    return c.final(ambiente=0.9 if not alterado else 0.75, tinte=None if not alterado else (1.0, 0.95, 0.8))

def vigilancia():
    c = Lienzo(seed=31)
    habitacion(c, (44, 50, 62), (28, 32, 40), 142)
    lampara_techo(c, 160, 8, 36, (170, 200, 230), 0.22)
    # ventana a la recepción (cristal unidireccional)
    c.rect(12, 37, 66, 63, (78, 84, 94)); c.rect(15, 40, 60, 57, (10, 16, 24))
    c.rect(15, 78, 60, 19, (24, 32, 42)); c.rect(25, 62, 10, 16, (22, 30, 40)); c.rect(52, 66, 16, 12, (20, 28, 38))
    c.rect(36, 48, 14, 34, (96, 114, 130)); c.rect(36, 48, 14, 1, (150, 170, 188))
    c.linea(15, 97, 75, 40, (40, 52, 66)); c.linea(15, 85, 62, 40, (32, 42, 54))
    c.rect(12, 99, 66, 3, (60, 66, 76))
    c.foco(45, 70, 50, 40, (110, 140, 170), 0.35)
    # papeles en la pared
    c.rect(84, 24, 12, 16, (208, 204, 188)); lineas_texto(c, 86, 27, 8, 4, (90, 90, 96), 3, 3)
    c.rect(246, 22, 14, 10, (214, 190, 120))
    # banco de monitores
    c.rect(90, 53, 142, 54, (26, 28, 32)); c.rect(90, 53, 142, 1, (60, 64, 70))
    tonos = [(60, 120, 90), (50, 100, 84), (66, 124, 96), (46, 96, 80), (14, 20, 18), (58, 112, 90)]
    k = 0
    for j in range(2):
        for i in range(3):
            x, y = 94+i*46, 57+j*24
            crt(c, x, y, 42, 22, tonos[k], carcasa=(70, 72, 76), brillo=0.28, base=False)
            sx, sy = x+4, y+4
            if k == 4:
                c.ruido(sx, sy, 34, 11, 0.5, 0.4)
            else:
                c.rect(sx, sy+8, 34, 3, mul(tonos[k], 0.7))
                c.rect(sx+10+k*2, sy+2, 5, 7, mul(tonos[k], 0.5))
                c.rect(sx, sy+5, 34, 1, mul(tonos[k], 1.4))
            k += 1
    # escritorio
    c.rect(78, 108, 164, 6, (74, 76, 84)); c.rect(78, 108, 164, 1, (120, 124, 134))
    c.rect(80, 114, 160, 30, (38, 40, 48)); c.rect(80, 144, 160, 2, (10, 10, 12))
    c.rect(150, 109, 32, 3, (46, 48, 54)); c.rect(190, 107, 4, 2, (60, 60, 66))
    c.rect(210, 104, 7, 5, (200, 200, 190)); c.rect(217, 105, 2, 3, (200, 200, 190))   # taza
    c.rect(100, 106, 18, 2, (30, 30, 34))
    # mesa auxiliar con cuaderno
    c.rect(226, 120, 52, 4, (74, 76, 84)); c.rect(230, 124, 3, 20, (46, 48, 54)); c.rect(271, 124, 3, 20, (46, 48, 54))
    c.rect(238, 113, 28, 7, (28, 80, 56)); c.rect(238, 113, 28, 1, (70, 140, 100)); c.rect(244, 115, 14, 1, (210, 206, 190))
    c.rect(268, 114, 7, 1, (200, 60, 50))
    # archivero
    c.rect(272, 37, 38, 107, (86, 92, 100))
    c.rect(272, 37, 2, 107, (140, 148, 158)); c.rect(308, 37, 2, 107, (52, 56, 62)); c.rect(272, 37, 38, 2, (150, 156, 166))
    for i in range(4):
        y = 41+i*26
        c.rect(276, y, 30, 23, (100, 106, 114)); c.borde(276, y, 30, 23, (60, 64, 70))
        c.rect(284, y+4, 14, 5, (200, 200, 188)); c.rect(286, y+6, 10, 1, (80, 80, 84))
        c.rect(286, y+14, 10, 3, (36, 36, 40))
    c.rect(276, 119, 30, 3, (14, 14, 16))          # cajón entreabierto
    c.foco(160, 78, 120, 60, (80, 150, 140), 0.3)
    c.foco(45, 70, 50, 40, (100, 130, 170), 0.2)
    c.oscurecer(0, 0, 320, 180, 0.95)
    return c.final(ambiente=1.08, vineta=0.6)

if __name__ == "__main__":
    import sys
    for n, f in [("recepcion", recepcion), ("recepcion_reverso", recepcion_reverso), ("pasillo", pasillo), ("vigilancia", vigilancia)]:
        f().save(f"prev_{n}.png")
    pasillo(True).save("prev_pasillo_alterado.png")
