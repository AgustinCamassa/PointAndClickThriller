class_name Textos
## Todos los textos largos del juego, fuera del código de lógica (fáciles de traducir o corregir).

const TITULO := "CORMANT"
const SUBTITULO := "Medical Systems"

const CUADERNO_PLANTILLA := """NOTAS DE TURNO · Vigilancia

El terminal apunta lo que detecta. Lo apuntado caduca a los %d segundos.
La cámara avisa, pero no distingue. Para saber si algo es real hay que ir a verlo.
Desde estos monitores es donde se decide: lo real se da por real, lo falso se descarta.
Me equivoqué más de una vez. Se nota.
Lo que se deja pasar se queda.
%s

No es un procedimiento. Es una costumbre."""

const REGLA_SOMBRA := {
	"suma": "Cuando las luces tiemblan y suena un tono grave, me oculto y aguanto hasta que termina. Lo que se acerca no mata. Deja huella.",
	"mata": "Cuando las luces tiemblan y suena el tono grave, me oculto enseguida. No hay tiempo. Aguanto hasta que termina.",
	"pasos": "Si oigo pasos acercarse, me oculto enseguida. Apenas hay tiempo. Aguanto hasta que termina.",
}


static func cuaderno(duracion: int, sombra: String) -> String:
	return CUADERNO_PLANTILLA % [duracion, REGLA_SOMBRA[sombra]]


const EXPEDIENTES := """EXPEDIENTES · ACCESO LIMITADO

N01 .... ACTIVO
N02 .... [ARCHIVO ELIMINADO]
N03 .... [ARCHIVO ELIMINADO]
N04 .... TRASLADADO
N05 .... [SIN REGISTRO]

Para consultar ARCHIVOS se requiere secuencia de 5 glifos."""

const FICHA_14B := """HISTORIA CLÍNICA · CASO 14-B

Sujeto: ████████ (tachado)
Ingreso: fecha ilegible
Estado: sin cambios

Observaciones:
«Compatibilidad estable. Mantener en observación.»

El resto de la hoja está arrancado."""

const MESITA := "Cajas metálicas, tarros y carpetas en la estantería. Todo en orden, como si nadie lo hubiera usado nunca. Sujeta al montante, una ficha."

## Hoja pegada bajo el monitor de la CAM 3 (Vigilancia). Sin firma y sin marcas de género.
const NOTA_TECNICO_DESC := "Estática y nada más. Bajo el monitor hay una hoja pegada con cinta, con letra apretada."
const NOTA_TECNICO := """«Llevé la cuenta de mi último turno.
La cámara tres nunca tuvo imagen y el terminal la daba por activa. No creo que sea un fallo.
En la sala hay una figura que no consigo situar. A veces creo que la conozco.
No sé de quién es esta letra.»"""
## Solo modo 1, con el glifo de los pitidos pedido y sin introducir (EstadoJuego.pista_pitidos).
const NOTA_TECNICO_MODO1 := """«Entre la estática suenan pitidos cortos, siempre en cuenta distinta.
Quizá lo importante no sea lo que se oye, sino cuántas veces.»"""


static func nota_tecnico(con_pista: bool) -> String:
	var t := NOTA_TECNICO_DESC + "\n\n" + NOTA_TECNICO
	if con_pista:
		t += "\n\n" + NOTA_TECNICO_MODO1
	return t


const DETECTOR_TITULO := "Detector de señales"
const DETECTOR := "Bajo el terminal hay un aparato de mano sujeto con cinta: una radio vieja con la antena doblada. Al tocarlo se enciende solo.\n\nMarca lo que el edificio emite cuando algo no encaja. No dice si es real.\n\nMe lo guardo.\n\n[ Has conseguido: DETECTOR DE SEÑALES ]"
const TARJETA := "Entre carpetas vacías hay una tarjeta de plástico con una banda magnética: «ACCESO · LABORATORIO». El borde está gastado.\n\nMe la guardo.\n\n[ Has conseguido: TARJETA DE SEGURIDAD ]"
const ARCHIVERO_VACIO := "Carpetas vacías. Alguien se ha llevado lo importante."
const LAB_CERRADO := "Lector de tarjetas. La luz está en rojo: acceso restringido. Hace falta una tarjeta de seguridad."
const CORREO_CABECERA := "CORMANT · CORREO INTERNO\nDe: Seguridad <seguridad@cormant.local>\nPara: Recepción\nAsunto: Renovación del acceso · Sala de vigilancia"
const CORREO_CUERPO := "Se ha renovado el PIN de la puerta de Vigilancia. Memorícelo y borre este mensaje: no debe quedar escrito en ningún sitio."
const CORREO_PIE := "El PIN se renueva en cada turno. Si no puede leerlo, no insista en pedirlo por correo: avise a Mantenimiento."
const PIN_CORRECTO := "El lector pita en verde. La puerta de Vigilancia se abre."
const PIN_ERRONEO := "PIN incorrecto."
const CASCO := "Una incubadora de muestras con la luz encendida. Dentro hay una bandeja con restos de algo gris. El panel marca 37 grados, la temperatura de un cuerpo."

const FRAGMENTOS := {
	"sombra": "Un dibujo trazado a toda prisa en el frente del mostrador, con algo que no es tinta. Puntos unidos por líneas, como un mapa del cielo.",
}

## Lo que muestra el terminal al solicitar cada glifo (no revela dónde exactamente, solo el sitio).
const PISTA_SOLICITUD := {
	"sombra": "Registro pendiente: recepción.",
	"mancha": "Registro pendiente: pasillo.",
	"pitidos": "Registro pendiente: señal de la cámara 3.",
	"retrato": "Registro pendiente: laboratorio.",
	"viento": "Registro pendiente: oficina de la sala 5.",
}

const NOMBRE_FRAGMENTO := {
	"sombra": "Recepción",
	"mancha": "Pasillo",
	"retrato": "Laboratorio",
	"pitidos": "Señal",
	"viento": "Oficina",
}

# --- Documento final -------------------------------------------------------

## Dos tintas: la normal se lee siempre que el bloque esté visible; la roja solo se revela con el filtro rojo.
const BLOQUE_A := """CORMANT MEDICAL SYSTEMS
HOJA DE SESIÓN · USO INTERNO

Proyecto ..................... Interfaz neural de continuidad
Objetivo ..................... Verificar la continuidad del recuerdo tras la transferencia
Sala de observación .......... Vigilancia
Técnico responsable .......... N01
Sujeto ....................... N01
Sesión ....................... 2 de 2
Estado ....................... EN CURSO"""

const BLOQUE_B := """Resultado de la transferencia ....... PARCIAL
Recuerdo de la sesión 1 ............. CONSERVADO (parcial)

Observaciones del técnico:
«El sujeto reconoce la sala antes de entrar.
 Cuenta los pitidos sin que nadie se lo pida.
 Si alguien lee esto, la transferencia ha funcionado.»

Firma ............................... N01"""

const BLOQUE_C := """Registro de lectura ................. 2
Esta es la segunda vez que lees esto."""

const BLOQUE_D := """VERIFICACIÓN DE SALA · VIGILANCIA

Personas registradas en el acceso ..... 1
Perfiles de memoria activos ........... 2
Presencias detectadas en sala ......... 3
Discrepancia .......................... SIN RESOLVER"""
## Modo 2 malo: nota en tinta roja junto a la línea «Presencias detectadas» (índice de línea del bloque D).
const BLOQUE_D_NOTA := "Una de ellas eres tú."
const BLOQUE_D_NOTA_LINEA := 4

const BLOQUE_E := "Verificación de firma ............... NO CONCLUYENTE"


## Convierte cada letra en ▒ respetando espacios, puntos y signos; `conservar` líneas iniciales se dejan legibles.
static func tapar(texto: String, conservar := 0) -> String:
	var r := RegEx.new()
	r.compile("[^\\s.·:«»\\[\\]]")
	var lineas := texto.split("\n")
	for i in range(conservar, lineas.size()):
		lineas[i] = r.sub(lineas[i], "▒", true)
	return "\n".join(lineas)


## Bloques del documento final: [{texto, rojo, nota, nota_linea}]. Modo 3 no usa esto (hoja de sangre).
static func documento(modo: int, malo: bool) -> Array:
	var bloques: Array = []
	if modo == 2:
		bloques = [{"texto": BLOQUE_A}, {"texto": BLOQUE_D}, {"texto": BLOQUE_B}, {"texto": BLOQUE_E}]
		if malo:
			bloques[1]["nota"] = BLOQUE_D_NOTA
			bloques[1]["nota_linea"] = BLOQUE_D_NOTA_LINEA
			bloques.append({"texto": BLOQUE_C, "rojo": true})
	elif malo:
		bloques = [{"texto": tapar(BLOQUE_A, 2)}, {"texto": BLOQUE_B}, {"texto": BLOQUE_C, "rojo": true}]
	else:
		bloques = [{"texto": BLOQUE_A}, {"texto": tapar(BLOQUE_B)}]
	for b in bloques:
		if not b.has("rojo"):
			b["rojo"] = false
	return bloques


const INFORME_BUENO := """INFORME DE SESIÓN

Tiempo de observación ......... %s
Aciertos ......... %d
Falsas alarmas ......... %d
Compatibilidad final ......... %d %%

Áreas sin registro: 1"""

# --- Pantalla final --------------------------------------------------------

const FIN_DEMO := "FIN DE LA DEMO"
const MODO_DESBLOQUEADO := "Modo %d desbloqueado: %s."
const FIN_GRACIAS := "Gracias por jugar."
const FIN_LISTA_DESEOS := "Cormant llegará completo. Añádelo a tu lista de deseos."

# --- Muerte ----------------------------------------------------------------

const GAME_OVER := "SESIÓN TERMINADA"
const REINTENTAR := "Reintentar"
const VOLVER_MENU := "Volver al menú"
