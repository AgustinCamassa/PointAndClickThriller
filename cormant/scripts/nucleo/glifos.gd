class_name Glifos
## Glifos del puzzle del laboratorio: siluetas de constelaciones dibujadas por código (puntos + líneas), sin imágenes.
## Cada punto es Vector3(x, y, magnitud) en una caja unitaria; la magnitud escala el tamaño de la estrella.
## Seis constelaciones reales con 4, 5, 6, 7, 8 y 9 estrellas, trazadas con las posiciones reales (herramientas/arte_y_audio/constelaciones.py).
## Las estrellas de cada una son únicas en la paleta: los pitidos de la CAM 3 dan su número y así se identifica.
## Los 5 glifos del puzzle cuentan algo ocurrido en Cormant (el significado es del glifo, no de la sala donde aparece);
## la Cruz del Sur (4) es el señuelo: solo aparece en la paleta del terminal y en los pitidos falsos.

const REALES := ["ofiuco", "lira", "orion", "geminis", "andromeda"]
const SENUELOS := ["cruz_sur"]
## Paleta del terminal (orden alfabético, para que no delate nada).
const PALETA := ["andromeda", "cruz_sur", "geminis", "lira", "ofiuco", "orion"]

const NOMBRES := {
	"ofiuco": "Ofiuco", "lira": "Lira", "orion": "Orión", "geminis": "Géminis", "andromeda": "Andrómeda",
	"cruz_sur": "Cruz del Sur",
}

## Lo que cuenta cada glifo (se muestra en el terminal al confirmarlo). Textos provisionales.
const HISTORIA := {
	"ofiuco": "OFIUCO · «Curaba tanto que devolvió a los muertos. Lo fulminaron por alterar el final de las cosas.»",
	"lira": "LIRA · «Bajó a buscar a quien amaba. Miró atrás antes de salir.»",
	"orion": "ORIÓN · «Presumió de no temer a ninguna criatura. Lo derribó la más pequeña.»",
	"geminis": "GÉMINIS · «Uno mortal y otro no. Compartieron lo que quedaba.»",
	"andromeda": "ANDRÓMEDA · «Encadenada a la roca por la soberbia de otros. Esperó a que alguien la viera.»",
}

const PUNTOS := {
	"cruz_sur": [Vector3(0.50, 0.08, 1.2), Vector3(0.58, 0.92, 1.4), Vector3(0.21, 0.45, 1.3), Vector3(0.79, 0.32, 0.9)],
	"andromeda": [Vector3(0.92, 0.75, 1.1), Vector3(0.67, 0.70, 0.8), Vector3(0.44, 0.53, 1.1), Vector3(0.08, 0.25, 1.1), Vector3(0.53, 0.43, 0.7)],
	"lira": [Vector3(0.77, 0.18, 1.5), Vector3(0.59, 0.08, 0.7), Vector3(0.59, 0.33, 0.7), Vector3(0.35, 0.41, 0.7), Vector3(0.46, 0.84, 0.8), Vector3(0.23, 0.92, 0.8)],
	"ofiuco": [Vector3(0.24, 0.08, 1.1), Vector3(0.17, 0.32, 0.9), Vector3(0.51, 0.18, 0.8), Vector3(0.70, 0.40, 0.7), Vector3(0.83, 0.56, 1.0), Vector3(0.66, 0.76, 1.0), Vector3(0.42, 0.92, 1.0)],
	"geminis": [Vector3(0.19, 0.18, 1.2), Vector3(0.08, 0.33, 1.3), Vector3(0.71, 0.82, 1.1), Vector3(0.64, 0.47, 0.9), Vector3(0.84, 0.57, 0.9), Vector3(0.92, 0.56, 0.8), Vector3(0.30, 0.59, 0.8), Vector3(0.45, 0.65, 0.7)],
	"orion": [Vector3(0.50, 0.08, 0.8), Vector3(0.28, 0.19, 1.4), Vector3(0.60, 0.24, 1.2), Vector3(0.53, 0.52, 1.1), Vector3(0.49, 0.56, 1.2), Vector3(0.44, 0.59, 1.2), Vector3(0.36, 0.92, 1.1), Vector3(0.72, 0.86, 1.5), Vector3(0.49, 0.76, 0.9)],
}

const LINEAS := {
	"cruz_sur": [[0, 1], [2, 3]],
	"andromeda": [[0, 1], [1, 2], [2, 3], [2, 4]],
	"lira": [[0, 1], [0, 2], [1, 2], [2, 3], [2, 4], [3, 5], [4, 5]],
	"ofiuco": [[2, 0], [0, 1], [1, 6], [6, 5], [5, 4], [4, 3], [3, 2]],
	"geminis": [[0, 3], [3, 4], [4, 5], [1, 6], [6, 7], [7, 2], [3, 6]],
	"orion": [[0, 1], [0, 2], [1, 5], [2, 3], [3, 4], [4, 5], [5, 6], [3, 7], [4, 8]],
}


## Número de estrellas del glifo (= pitidos de la CAM 3).
static func estrellas(id: String) -> int:
	return PUNTOS[id].size()


static func nombre(id: String) -> String:
	return NOMBRES.get(id, id)


static func historia(id: String) -> String:
	return HISTORIA.get(id, "")


## Posición de la estrella i del glifo dentro de rect.
static func posicion(id: String, i: int, rect: Rect2) -> Vector2:
	var p: Vector3 = PUNTOS[id][i]
	return rect.position + Vector2(p.x, p.y) * rect.size


## Dibuja el glifo en rect. Si hay textura de mancha, las estrellas son manchas (ventana del pasillo).
static func dibujar(ci: CanvasItem, id: String, rect: Rect2, color: Color, radio := 4.0, grosor := 1.6,
		textura_mancha: Texture2D = null, tinte_mancha := Color.WHITE) -> void:
	if not PUNTOS.has(id):
		return
	var color_linea := Color(color.r, color.g, color.b, color.a * 0.55)
	for l in LINEAS[id]:
		ci.draw_line(posicion(id, l[0], rect), posicion(id, l[1], rect), color_linea, grosor, true)
	for i in PUNTOS[id].size():
		var p := posicion(id, i, rect)
		var m: float = PUNTOS[id][i].z
		if textura_mancha != null:
			var tam := Vector2(radio * 5.0, radio * 1.7) * m
			ci.draw_texture_rect(textura_mancha, Rect2(p - tam / 2.0, tam), false, tinte_mancha)
		else:
			ci.draw_circle(p, radio * m * 2.3, Color(color.r, color.g, color.b, color.a * 0.16))
			ci.draw_circle(p, radio * m, color)
