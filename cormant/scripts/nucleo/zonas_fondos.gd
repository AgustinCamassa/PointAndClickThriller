class_name ZonasFondos
## Escrito a mano para los fondos fotorrealistas (ya no lo genera exportar3d.py).
## Polígonos en el espacio 1280x720 de cada fondo, posiciones de Alicia y datos de las cámaras.
## Las zonas son invisibles con los fondos reales: para ajustarlas, mide sobre assets/fondos/<sala>.png.

const ZONAS := {
	"recepcion": {
		"letrero": [Vector2(416, 258), Vector2(702, 258), Vector2(702, 336), Vector2(416, 336)],
		"numero": [Vector2(470, 412), Vector2(600, 412), Vector2(600, 470), Vector2(470, 470)],
		"pc1": [Vector2(428, 346), Vector2(480, 346), Vector2(480, 390), Vector2(428, 390)],
		"pc2": [Vector2(608, 348), Vector2(662, 348), Vector2(662, 388), Vector2(608, 388)],
		"puerta_pasillo": [Vector2(766, 282), Vector2(875, 282), Vector2(875, 482), Vector2(766, 482)],
		"puerta_izq": [Vector2(38, 188), Vector2(192, 242), Vector2(192, 540), Vector2(38, 598)],
		"puerta_der": [Vector2(1112, 226), Vector2(1222, 194), Vector2(1222, 600), Vector2(1112, 562)],
		"vuelta": [Vector2(472, 640), Vector2(808, 640), Vector2(808, 720), Vector2(472, 720)],
	},
	"recepcion_reverso": {
		"puerta_entrada": [Vector2(428, 302), Vector2(820, 302), Vector2(820, 560), Vector2(428, 560)],
		"vuelta": [Vector2(472, 640), Vector2(808, 640), Vector2(808, 720), Vector2(472, 720)],
	},
	"pasillo": {
		"puerta_vigilancia": [Vector2(245, 150), Vector2(324, 172), Vector2(324, 600), Vector2(246, 684)],
		"puerta_bloq1": [Vector2(418, 252), Vector2(460, 264), Vector2(460, 520), Vector2(418, 538)],
		"puerta_bloq2": [Vector2(582, 290), Vector2(670, 290), Vector2(670, 468), Vector2(582, 468)],
		"puerta_lab": [Vector2(910, 190), Vector2(984, 148), Vector2(984, 668), Vector2(920, 612)],
		"puerta_recepcion": [Vector2(472, 632), Vector2(808, 632), Vector2(808, 720), Vector2(472, 720)],
	},
	"vigilancia": {
		"puerta_pasillo": [Vector2(24, 108), Vector2(168, 182), Vector2(168, 636), Vector2(24, 716)],
		"ventana": [Vector2(342, 138), Vector2(910, 138), Vector2(910, 318), Vector2(342, 318)],
		"monitores": [Vector2(390, 324), Vector2(826, 324), Vector2(826, 424), Vector2(390, 424)],
		"cuaderno": [Vector2(806, 424), Vector2(876, 424), Vector2(876, 442), Vector2(806, 442)],
		"archivero": [Vector2(910, 296), Vector2(1076, 296), Vector2(1076, 606), Vector2(910, 606)],
	},
	"laboratorio": {
		"puerta_oficina": [Vector2(1143, 222), Vector2(1240, 190), Vector2(1240, 572), Vector2(1143, 520)],
		"armario": [Vector2(0, 202), Vector2(204, 244), Vector2(204, 518), Vector2(0, 596)],
		"cuadro": [Vector2(562, 222), Vector2(702, 222), Vector2(702, 298), Vector2(562, 298)],
		"terminal": [Vector2(583, 318), Vector2(667, 318), Vector2(667, 372), Vector2(583, 372)],
		"frasco": [Vector2(708, 378), Vector2(762, 378), Vector2(762, 418), Vector2(708, 418)],
		"casco": [Vector2(875, 315), Vector2(972, 315), Vector2(972, 382), Vector2(875, 382)],
		"volver": [Vector2(472, 640), Vector2(808, 640), Vector2(808, 720), Vector2(472, 720)],
	},
	"oficina": {
		"ventana_secreta": [Vector2(342, 163), Vector2(706, 163), Vector2(706, 332), Vector2(342, 332)],
		"mostrador": [Vector2(245, 402), Vector2(700, 402), Vector2(700, 555), Vector2(245, 555)],
		"puerta_azul": [Vector2(800, 208), Vector2(914, 208), Vector2(914, 484), Vector2(800, 484)],
		"tablero": [Vector2(45, 100), Vector2(245, 178), Vector2(245, 392), Vector2(45, 396)],
		"volver": [Vector2(472, 640), Vector2(808, 640), Vector2(808, 720), Vector2(472, 720)],
	},
	"habitacion_secreta": {
		"puerta_morada": [Vector2(538, 226), Vector2(674, 226), Vector2(674, 474), Vector2(538, 474)],
		"reloj": [Vector2(426, 208), Vector2(484, 208), Vector2(484, 264), Vector2(426, 264)],
		"calendario": [Vector2(731, 229), Vector2(799, 229), Vector2(799, 318), Vector2(731, 318)],
		"mesita": [Vector2(0, 380), Vector2(214, 380), Vector2(214, 640), Vector2(0, 640)],
		"ficha": [Vector2(38, 150), Vector2(98, 150), Vector2(98, 274), Vector2(38, 274)],
		"monitor_pulso": [Vector2(304, 284), Vector2(372, 284), Vector2(372, 346), Vector2(304, 346)],
		"gotero": [Vector2(236, 160), Vector2(300, 160), Vector2(300, 300), Vector2(236, 300)],
		"camilla": [Vector2(842, 395), Vector2(1280, 372), Vector2(1280, 720), Vector2(1030, 720), Vector2(1010, 560), Vector2(845, 455)],
	},
	"pasillo_alterado": {
		"puerta_azul": [Vector2(480, 306), Vector2(562, 306), Vector2(562, 484), Vector2(480, 484)],
		"ventana": [Vector2(592, 305), Vector2(780, 305), Vector2(780, 398), Vector2(592, 398)],
		"placa": [Vector2(479, 267), Vector2(563, 267), Vector2(563, 292), Vector2(479, 292)],
		"huellas": [Vector2(500, 500), Vector2(575, 500), Vector2(790, 636), Vector2(620, 636)],
		"puerta_morada": [Vector2(472, 640), Vector2(808, 640), Vector2(808, 720), Vector2(472, 720)],
	},
	# Ventana de la Oficina: coordenadas dentro del cristal de 924x520 (no del lienzo de 1280x720).
	"pasillo_secreto": {
		"puerta_morada": [Vector2(420, 217), Vector2(502, 217), Vector2(502, 345), Vector2(420, 345)],
		"placa": [Vector2(406, 168), Vector2(516, 168), Vector2(516, 208), Vector2(406, 208)],
	},
}

## Alicia por sala: pose, punto de los pies (1280x720) y escala respecto al tamaño base del sprite
## (87x300 de pie = 1,68 m; el tamaño sigue la perspectiva de cada fondo). En la habitación secreta
## no hay sprite: el fondo ya lleva a Alicia (tumbada y, a los 3 s, sentada).
const ALICIA := {
	"vigilancia": {"pose": "sentada", "pos": Vector2(533, 640), "escala": 1.0},
	"laboratorio": {"pose": "de_espaldas", "pos": Vector2(300, 600), "escala": 1.0},
	"oficina": {"pose": "de_espaldas", "pos": Vector2(740, 590), "escala": 1.1},
}

## Cámaras: posición relativa (0-1) del cuadro dentro del feed del laboratorio y de la mancha en el del pasillo.
const CAMARAS := {
	"1": {"cuadro_centro": Vector2(0.4929, 0.3570), "cuadro_ancho": 0.1250},
	"2": {"mancha_centro": Vector2(0.5000, 0.8594), "mancha_ancho": 0.1370},
}

## Mancha del suelo del pasillo en el fondo de 1280x720: centro y ancho en píxeles.
const MANCHA_PASILLO := {"centro": Vector2(640.0, 590.0), "ancho": 175.0}

## Silueta vista por la ventana de Vigilancia: pies (x, y) y alto, relativos (0-1) al cristal.
const SILUETA_VENTANA := Vector3(0.5000, 0.7600, 0.3100)

## Silueta que asoma en el pasillo secreto (pies x, y y alto, relativos al cristal).
const SILUETA_SECRETO := Vector3(0.4400, 0.7500, 0.3500)

static func poligono(sala: String, zona: String) -> PackedVector2Array:
	return PackedVector2Array(ZONAS.get(sala, {}).get(zona, []))

static func rect(sala: String, zona: String) -> Rect2:
	var p := poligono(sala, zona)
	if p.is_empty():
		return Rect2()
	var r := Rect2(p[0], Vector2.ZERO)
	for v in p:
		r = r.expand(v)
	return r
