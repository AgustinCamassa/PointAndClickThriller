class_name ZonasFondos
## Escrito a mano para los fondos fotorrealistas (ya no lo genera exportar3d.py).
## Polígonos en el espacio 1280x720 de cada fondo, posiciones de Alicia y datos de las cámaras.
## Las zonas son invisibles con los fondos reales: para ajustarlas, mide sobre assets/fondos/<sala>.png.

const ZONAS := {
	"recepcion": {
		"letrero": [Vector2(433, 250), Vector2(741, 250), Vector2(741, 323), Vector2(433, 323)],
		"pc1": [Vector2(450, 342), Vector2(510, 342), Vector2(510, 386), Vector2(450, 386)],
		"pc2": [Vector2(650, 342), Vector2(712, 342), Vector2(712, 386), Vector2(650, 386)],
		"puerta_pasillo": [Vector2(813, 270), Vector2(915, 270), Vector2(915, 490), Vector2(813, 490)],
		"puerta_izq": [Vector2(54, 175), Vector2(256, 245), Vector2(256, 515), Vector2(61, 578)],
		"puerta_der": [Vector2(1112, 224), Vector2(1222, 178), Vector2(1222, 590), Vector2(1112, 570)],
		# «Darse la vuelta» queda por encima de la barra Volver/Cerrar para no solaparse con sus botones.
		"vuelta": [Vector2(472, 560), Vector2(808, 560), Vector2(808, 634), Vector2(472, 634)],
	},
	# Fondos macabros: otro encuadre que el normal, así que sus puertas y objetos tienen zonas propias.
	# Solo lo que cambia de sitio; el resto usa las zonas del fondo normal (medido sobre assets/fondos/<sala>_macabro.png).
	"recepcion_macabro": {
		"letrero": [Vector2(417, 251), Vector2(747, 251), Vector2(747, 328), Vector2(417, 328)],
		"pc1": [Vector2(428, 343), Vector2(488, 343), Vector2(488, 384), Vector2(428, 384)],
		"pc2": [Vector2(649, 343), Vector2(705, 343), Vector2(705, 384), Vector2(649, 384)],
		"puerta_pasillo": [Vector2(817, 266), Vector2(935, 266), Vector2(935, 490), Vector2(817, 490)],
		"puerta_izq": [Vector2(52, 184), Vector2(243, 244), Vector2(243, 522), Vector2(58, 572)],
		"puerta_der": [Vector2(1130, 225), Vector2(1236, 184), Vector2(1236, 592), Vector2(1130, 566)],
	},
	"vigilancia_macabro": {
		"ventana": [Vector2(352, 143), Vector2(928, 143), Vector2(928, 312), Vector2(352, 312)],
		"monitores": [Vector2(388, 324), Vector2(850, 324), Vector2(850, 426), Vector2(388, 426)],
		"cuaderno": [Vector2(832, 424), Vector2(900, 424), Vector2(900, 446), Vector2(832, 446)],
		"archivero": [Vector2(935, 298), Vector2(1092, 298), Vector2(1092, 600), Vector2(935, 600)],
	},
	"laboratorio_macabro": {
		"terminal": [Vector2(586, 318), Vector2(672, 318), Vector2(672, 372), Vector2(586, 372)],
		"puerta_oficina": [Vector2(1149, 218), Vector2(1240, 190), Vector2(1240, 572), Vector2(1149, 520)],
	},
	"recepcion_reverso": {
		"puerta_entrada": [Vector2(428, 302), Vector2(820, 302), Vector2(820, 560), Vector2(428, 560)],
		# Libreta sobre la mesita de la derecha (ayuda oculta; solo con la vista normal).
		"libreta": [Vector2(1056, 512), Vector2(1102, 512), Vector2(1102, 534), Vector2(1056, 534)],
	},
	"pasillo": {
		"puerta_vigilancia": [Vector2(245, 150), Vector2(324, 172), Vector2(324, 600), Vector2(246, 684)],
		"puerta_bloq1": [Vector2(418, 252), Vector2(460, 264), Vector2(460, 520), Vector2(418, 538)],
		"puerta_bloq2": [Vector2(582, 290), Vector2(670, 290), Vector2(670, 468), Vector2(582, 468)],
		"puerta_lab": [Vector2(910, 190), Vector2(984, 148), Vector2(984, 668), Vector2(920, 612)],
		# Cuadro del muro derecho (ayuda oculta; solo con la vista normal).
		"cuadro_pasillo": [Vector2(791, 264), Vector2(864, 227), Vector2(866, 435), Vector2(791, 407)],
	},
	# El fondo macabro del pasillo (`pasillo_macabro`) es otro encuadre: sus puertas están en otro sitio.
	"pasillo_macabro": {
		"puerta_vigilancia": [Vector2(262, 158), Vector2(340, 190), Vector2(340, 596), Vector2(262, 648)],
		"puerta_bloq1": [Vector2(441, 252), Vector2(476, 266), Vector2(476, 502), Vector2(441, 522)],
		"puerta_bloq2": [Vector2(598, 290), Vector2(684, 290), Vector2(684, 470), Vector2(598, 470)],
		"puerta_lab": [Vector2(948, 192), Vector2(1034, 160), Vector2(1034, 640), Vector2(948, 598)],
	},
	"vigilancia": {
		"puerta_pasillo": [Vector2(37, 116), Vector2(168, 178), Vector2(168, 640), Vector2(37, 716)],
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
	},
	"oficina": {
		"ventana_secreta": [Vector2(342, 163), Vector2(706, 163), Vector2(706, 332), Vector2(342, 332)],
		"mostrador": [Vector2(245, 402), Vector2(700, 402), Vector2(700, 555), Vector2(245, 555)],
		"puerta_azul": [Vector2(800, 208), Vector2(914, 208), Vector2(914, 484), Vector2(800, 484)],
		"tablero": [Vector2(45, 100), Vector2(245, 178), Vector2(245, 392), Vector2(45, 396)],
		# Carpeta «Caso 14-B» sobre el mostrador (la hoja suelta); va después del mostrador para quedar encima.
		"expediente": [Vector2(576, 388), Vector2(626, 388), Vector2(626, 411), Vector2(576, 411)],
	},
	"habitacion_secreta": {
		"puerta_morada": [Vector2(538, 226), Vector2(674, 226), Vector2(674, 474), Vector2(538, 474)],
		"reloj": [Vector2(427, 209), Vector2(481, 209), Vector2(481, 263), Vector2(427, 263)],
		"calendario": [Vector2(731, 229), Vector2(799, 229), Vector2(799, 318), Vector2(731, 318)],
		"mesita": [Vector2(0, 380), Vector2(214, 380), Vector2(214, 640), Vector2(0, 640)],
		"ficha": [Vector2(38, 150), Vector2(98, 150), Vector2(98, 274), Vector2(38, 274)],
		"monitor_pulso": [Vector2(296, 286), Vector2(370, 286), Vector2(370, 346), Vector2(296, 346)],
		"gotero": [Vector2(236, 160), Vector2(300, 160), Vector2(300, 300), Vector2(236, 300)],
		"camilla": [Vector2(842, 395), Vector2(1280, 372), Vector2(1280, 720), Vector2(1030, 720), Vector2(1010, 560), Vector2(845, 455)],
	},
	"pasillo_alterado": {
		"puerta_azul": [Vector2(480, 306), Vector2(562, 306), Vector2(562, 484), Vector2(480, 484)],
		"ventana": [Vector2(592, 305), Vector2(780, 305), Vector2(780, 398), Vector2(592, 398)],
		"huellas": [Vector2(500, 500), Vector2(575, 500), Vector2(790, 636), Vector2(620, 636)],
	},
	# Ventana de la Oficina: coordenadas dentro del cristal de 924x520 (no del lienzo de 1280x720).
	"pasillo_secreto": {
		"puerta_morada": [Vector2(420, 217), Vector2(502, 217), Vector2(502, 345), Vector2(420, 345)],
	},
}

## Alicia por sala: pose, punto de los pies (1280x720) y escala respecto al tamaño base del sprite
## (87x300 de pie = 1,68 m; el tamaño sigue la perspectiva de cada fondo). En la habitación secreta
## no hay sprite: el fondo ya lleva a Alicia (tumbada y, a los 3 s, sentada).
const ALICIA := {
	"vigilancia": {"pose": "sentada", "pos": Vector2(533, 640), "escala": 1.0},
	"laboratorio": {"pose": "perfil", "pos": Vector2(256, 690), "escala": 1.28},  # a la izquierda, junto a la estantería, mirando a la derecha (~460 px)
	"oficina": {"pose": "de_espaldas", "pos": Vector2(745, 690), "escala": 1.63},  # junto a la ventana, lejos de la puerta (~490 px)
}

## Cámaras: posición relativa (0-1) del cuadro dentro del feed del laboratorio y de la mancha en el del pasillo.
const CAMARAS := {
	"1": {"cuadro_centro": Vector2(0.4929, 0.3570), "cuadro_ancho": 0.1250},
	"2": {"mancha_centro": Vector2(0.5000, 0.8594), "mancha_ancho": 0.1370},
}

## Mancha del suelo del pasillo en el fondo de 1280x720: centro y ancho en píxeles.

## Entidad vista por la ventana de Vigilancia (en el fondo 1280x720): zona visible del cristal, x del centro y, por fase, alto y
## y de los pies (fuera del cristal en las fases 2 y 3: se ve de la cintura / de los hombros hacia arriba).
const ENTIDAD_FONDO := {
	"clip": Rect2(356, 152, 540, 154), "x": 622.0,
	"fases": [Vector2(74, 304), Vector2(230, 420), Vector2(520, 725)],   # (alto, y de los pies)
}

## La misma entidad en el panel de la ventana (relativo al cristal de 924x520): zona visible y, por fase, (x, y pies, alto).
const ENTIDAD_PANEL := {
	"clip": Rect2(0.012, 0.12, 0.976, 0.74),
	"fases": [Vector3(0.5, 0.76, 0.31), Vector3(0.5, 1.42, 1.12), Vector3(0.5, 2.06, 1.73)],
}

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
