class_name DatosSalas
## Definición de cada sala: color provisional, zonas clicables (hotspots) y posición de Alicia.
## Coordenadas en un lienzo de 1280x720. Cuando existan los fondos reales
## (assets/fondos/<id>.png) las zonas pasan a ser invisibles automáticamente.

const ROJO := Color(0.8, 0.15, 0.15, 0.45)
const MARRON := Color(0.45, 0.28, 0.12, 0.45)
const AZUL := Color(0.15, 0.3, 0.85, 0.45)
const MORADO := Color(0.55, 0.15, 0.65, 0.45)
const OBJETO := Color(0.95, 0.9, 0.35, 0.25)
const VOLVER := Color(0.9, 0.9, 0.9, 0.2)


## Zona clicable: el polígono sale de ZonasFondos (escrito a mano sobre los fondos).
static func _h(sala: String, id: String, etiqueta: String, accion: String, valor: String, color: Color, zona := "") -> Dictionary:
	var nombre_zona := zona if zona != "" else id
	return {
		"id": id, "poly": ZonasFondos.poligono(sala, nombre_zona), "rect": ZonasFondos.rect(sala, nombre_zona),
		"etiqueta": etiqueta, "accion": accion, "valor": valor, "color": color,
	}


## Sala a la que lleva el botón «Volver» de la barra inferior ("" = no hay vuelta atrás: inicio, habitación y pasillo alterado).
const VOLVER_A := {
	"recepcion_reverso": "recepcion",
	"pasillo": "recepcion",
	"vigilancia": "pasillo",
	"laboratorio": "pasillo",
	"oficina": "laboratorio",
}


static func volver_a(sala: String) -> String:
	return VOLVER_A.get(sala, "")


## Salas donde «Volver» no lleva a ningún sitio y avisa de que la puerta está bloqueada (solo se avanza).
const VOLVER_BLOQUEADO := ["pasillo_alterado"]


static func volver_bloqueado(sala: String) -> bool:
	return sala in VOLVER_BLOQUEADO


static func nombre(id: String) -> String:
	return obtener(id).get("nombre", id)


static func obtener(id: String) -> Dictionary:
	match id:
		"recepcion":
			return {
				"nombre": "Recepción",
				"color": Color(0.16, 0.19, 0.22),
				"musica": "ambiente_recepcion",
				"hotspots": [
					_h("recepcion", "letrero", "Letrero CORMANT", "texto",
						"El letrero está sobre un cristal oscuro. Del otro lado no se ve nada.", OBJETO),
					_h("recepcion", "puerta_pasillo", "Pasillo", "ir", "pasillo", ROJO),
					_h("recepcion", "puerta_izq", "Puerta cerrada", "texto",
						"Cerrada con llave. Se oye una radio al otro lado.", MARRON),
					_h("recepcion", "puerta_der", "Puerta cerrada", "texto",
						"Un teclado de acceso parpadea en azul junto a la puerta. Se oye un zumbido eléctrico.", MARRON),
					_h("recepcion", "pc1", "Ordenador 1", "funcion", "pc_correo", OBJETO),
					_h("recepcion", "pc2", "Ordenador 2", "funcion", "pc_senal", OBJETO),
					_h("recepcion", "vuelta", "Darse la vuelta", "ir", "recepcion_reverso", VOLVER),
				],
			}
		"recepcion_reverso":
			return {
				"nombre": "Recepción (entrada)",
				"fondo": "recepcion",
				"color": Color(0.17, 0.2, 0.21),
				"hotspots": [
					_h("recepcion_reverso", "puerta_entrada", "Puerta de entrada", "texto",
						"Cerrada. No recuerdo haberla cruzado.", MARRON),
				],
			}
		"pasillo":
			return {
				"nombre": "Pasillo",
				"color": Color(0.14, 0.15, 0.17),
				"musica": "ambiente_pasillo",
				"hotspots": [
					_h("pasillo", "puerta_bloq1", "Puerta cerrada", "texto",
						"El cristal está empañado por el frío. Hay gotas de condensación del lado de dentro.", MARRON),
					_h("pasillo", "puerta_vigilancia", "Vigilancia", "ir", "vigilancia", ROJO),
					_h("pasillo", "puerta_bloq2", "Puerta cerrada", "texto",
						"Cerrada. Junto a ella hay un rectángulo limpio en la pared, donde antes colgaba una placa.", MARRON),
					_h("pasillo", "puerta_lab", "Laboratorio", "ir", "laboratorio", ROJO),
				],
			}
		"vigilancia":
			return {
				"nombre": "Vigilancia",
				"color": Color(0.12, 0.13, 0.15),
				"musica": "ambiente_vigilancia",
				"alicia": ZonasFondos.ALICIA["vigilancia"],
				"hotspots": [
					_h("vigilancia", "monitores", "Terminal de vigilancia", "panel", "camaras", OBJETO),
					_h("vigilancia", "cuaderno", "Notas de turno", "panel", "cuaderno", OBJETO),
					_h("vigilancia", "archivero", "Archivero", "funcion", "archivero", OBJETO),
					_h("vigilancia", "ventana", "Ventana", "panel", "ventana", OBJETO),
					_h("vigilancia", "puerta_pasillo", "Pasillo", "ir", "pasillo", ROJO),
				],
			}
		"laboratorio":
			return {
				"nombre": "Laboratorio",
				"color": Color(0.13, 0.17, 0.15),
				"musica": "ambiente_laboratorio",
				"alicia": ZonasFondos.ALICIA["laboratorio"],
				"hotspots": [
					_h("laboratorio", "terminal", "Terminal", "panel", "terminal_lab", OBJETO),
					_h("laboratorio", "cuadro", "Cuadro", "funcion", "cuadro", OBJETO),
					_h("laboratorio", "frasco", "Tubos de muestra", "texto", "MUESTRA · NO ABRIR. En el tubo del extremo, una sustancia gris se mueve despacio.", OBJETO),
					_h("laboratorio", "casco", "Incubadora", "texto", Textos.CASCO, OBJETO),
					_h("laboratorio", "puerta_oficina", "Oficina", "ir", "oficina", ROJO),
					_h("laboratorio", "armario", "Estantería de muestras", "texto",
						"Muestras con fechas. Varias etiquetas están rascadas.", OBJETO),
				],
			}
		"oficina":
			return {
				"nombre": "Oficina",
				"color": Color(0.2, 0.18, 0.14),
				"musica": "ambiente_oficina",
				"alicia": ZonasFondos.ALICIA["oficina"],
				"hotspots": [
					_h("oficina", "mostrador", "Documentos del mostrador", "texto", "Hojas de turnos sin firmar. Todas dicen N01. En la última, la hora de salida está escrita dos veces, con letras distintas.", OBJETO),
					_h("oficina", "ventana_secreta", "Ventana al pasillo", "panel", "ventana_secreta", OBJETO),
					_h("oficina", "puerta_azul", "Puerta azul", "funcion", "puerta_azul", AZUL),
					_h("oficina", "tablero", "Tablón de avisos", "texto",
						"Normas de seguridad y avisos de personal, unos sobre otros. Hay una chincheta sola, sin nada que sujetar.", OBJETO),
					_h("oficina", "expediente", "Expediente", "texto",
						"CASO 14-B · TRASLADO\n\nSujeto: ████████\nDestino: habitación segura\nAutorizado por: ████\nRetorno: no previsto\n\nAl margen, a lápiz: «Compatible. Mantener en observación.»", OBJETO),
				],
			}
		"habitacion_secreta":
			return {
				"nombre": "Habitación",
				"color": Color(0.22, 0.06, 0.06),
				"musica": "ambiente_habitacion",
				"hotspots": [
					_h("habitacion_secreta", "puerta_morada", "Puerta morada", "ir", "pasillo_alterado", MORADO),
					_h("habitacion_secreta", "monitor_pulso", "Monitor de pulso", "texto",
						"El monitor marca un pulso. Va al ritmo de mi respiración.", OBJETO),
					_h("habitacion_secreta", "camilla", "Camilla", "texto",
						"La sábana está hundida donde estuve. Las correas están sueltas.", OBJETO),
					_h("habitacion_secreta", "reloj", "Reloj", "texto",
						"El reloj marca una hora. No coincide con la del reloj de la oficina.", OBJETO),
					_h("habitacion_secreta", "calendario", "Lámina del cerebro", "texto",
						"Una lámina de anatomía del cerebro, con anotaciones que no consigo leer. Alguien ha rodeado una zona con tinta.", OBJETO),
					_h("habitacion_secreta", "ficha", "Ficha clínica", "panel", "ficha_14b", OBJETO),
					_h("habitacion_secreta", "mesita", "Estantería", "funcion", "mesita", OBJETO),
					_h("habitacion_secreta", "gotero", "Gotero", "texto",
						"La bolsa está vacía. El tubo cuelga sin aguja.", OBJETO),
				],
			}
		"pasillo_alterado":
			return {
				"nombre": "Pasillo alterado",
				"color": Color(0.12, 0.09, 0.09),
				"musica": "ambiente_pasillo_alterado",
				"hotspots": [
					_h("pasillo_alterado", "ventana", "Ventana", "texto",
						"El cristal de la oficina, visto desde este lado. No hay nadie dentro.", OBJETO),
					_h("pasillo_alterado", "huellas", "Huellas", "texto",
						"Huellas en el suelo, ya marcadas. Todas llevan a la puerta azul. No sé decir si son mías.", OBJETO),
					_h("pasillo_alterado", "puerta_azul", "Puerta azul", "ir", "oficina", AZUL),
				],
			}
	return {"nombre": id, "color": Color(0.1, 0.1, 0.1), "hotspots": []}
