class_name Textos
## Todos los textos largos del juego, fuera del código de lógica (fáciles de traducir o corregir).

const TITULO := "CORMANT"
const SUBTITULO := "Medical Systems"

const CUADERNO_PLANTILLA := """PROCEDIMIENTO DE OBSERVACIÓN
(Cuaderno de mantenimiento · Vigilancia)

1. El terminal registra señales de forma automática. Toda señal caduca a los %d segundos.
2. Una señal puede ser real o una lectura falsa. La cámara no distingue una de otra: solo avisa. Verifique en persona (laboratorio, pasillo, oficina) antes de decidir.
3. REPORTE lo real. DESCARTE lo falso.
4. Reportar una falsa alarma bloquea el terminal durante 8 segundos.
5. Una anomalía real que se ignora SE QUEDA. Y usted se acerca más a ella.
6. Las siluetas no se reportan. No entre en la sala marcada hasta que la marca se apague: lo que dejan, lo dejan para usted.
7. La cámara 3 no tiene señal. Aun así, a veces suena. Cuente lo que oiga.
8. Los parpadeos de esta sala no se pueden evitar. Cuentan como una señal ignorada.
9. El terminal del laboratorio entrega el código dígito a dígito, de izquierda a derecha: se solicita uno, se busca, se confirma, y solo entonces se solicita el siguiente. Un dato equivocado se castiga.
10. Lo que se encuentra se desvanece a los 30 segundos. No se anota solo: recuérdelo.
11. %s

No es un procedimiento. Es una costumbre."""

const REGLA_SOMBRA := {
	"suma": "Si las luces parpadean y se oye un tono grave, ocúltese. Mantenga la ocultación hasta que termine. Lo que se acerca no mata, pero deja huella.",
	"mata": "Si las luces parpadean y se oye un tono grave, ocúltese ya: hay muy poco tiempo. Mantenga la ocultación hasta que termine.",
	"pasos": "Si oye pasos acercarse, ocúltese ya: apenas hay tiempo. Mantenga la ocultación hasta que termine.",
}


static func cuaderno(duracion: int, sombra: String) -> String:
	return CUADERNO_PLANTILLA % [duracion, REGLA_SOMBRA[sombra]]


const EXPEDIENTES := """EXPEDIENTES · ACCESO LIMITADO

N01 .... ACTIVO
N02 .... [ARCHIVO ELIMINADO]
N03 .... [ARCHIVO ELIMINADO]
N04 .... TRASLADADO
N05 .... [SIN REGISTRO]

Para consultar ARCHIVOS se requiere código de 5 dígitos."""

const FICHA_14B := """HISTORIA CLÍNICA · CASO 14-B

Sujeto: ████████ (tachado)
Ingreso: fecha ilegible
Estado: sin cambios

Observaciones:
«Compatibilidad estable. Mantener en observación.»

El resto de la hoja está arrancado."""

const MESITA := "Cajas metálicas, tarros y carpetas en la estantería. Todo en orden, como si nadie lo hubiera usado nunca. Sujeta al montante, una ficha."

## Solo en el modo 1, tras morir atascado en el dígito de la cámara 3: ayuda sin ser explícita.
const NOTA_EX_TRABAJADOR := """Entre las cajas, una hoja doblada, con letra apretada:

«Llevé la cuenta de mi último turno. La cámara tres nunca tuvo imagen y aun así el terminal la daba por activa. No es un fallo, creo. Hay un número que me faltaba y todo me lleva a ella. No llegué a comprobarlo. Quizá lo importante no sea lo que se ve.»

Firmado: un técnico anterior."""

const DETECTOR_TITULO := "Detector de señales"
const DETECTOR := "Bajo el terminal hay un aparato de mano sujeto con cinta: una radio vieja con la antena doblada. Al tocarlo se enciende solo.\n\nMarca lo que el edificio emite cuando algo no encaja. No dice si es real.\n\nTe lo guardas.\n\n[ Has conseguido: DETECTOR DE SEÑALES ]"
const CASCO := "Una incubadora de muestras con la luz encendida. Dentro hay una bandeja con restos de algo gris. El panel marca 37 grados, la temperatura de un cuerpo."

const FRAGMENTOS := {
	"sombra": "Un número escrito a toda prisa en el frente del mostrador, con algo que no es tinta:\n\n%d",
}

## Lo que muestra el terminal al solicitar cada dígito (no revela dónde exactamente, solo el sitio).
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

const DOCUMENTO_SUPERIOR := """CORMANT MEDICAL SYSTEMS
HOJA DE SESIÓN · USO INTERNO

Proyecto ......... Interfaz neural de continuidad
Técnico responsable ....... N01
Sujeto ......... N01
Sala de observación ....... Vigilancia
Estado de la sesión ....... EN CURSO"""

const DOCUMENTO_INFERIOR_BUENO := """Resultado de la transferencia ......... ▒▒▒▒▒▒▒▒▒▒
Observaciones del técnico ......... ▒▒▒▒ ▒▒▒▒▒▒ ▒▒▒ ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒ ▒▒▒ ▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒▒▒
Firma ......... ▒▒▒"""

const DOCUMENTO_ROJO := """Sujeto N01 · sesión 2 de 2
Recuerdo de la sesión 1 ......... CONSERVADO (parcial)
Observaciones ......... el sujeto vuelve a leer este documento.

Esta es la segunda vez que lees esto."""

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


static func fragmento(id: String, digito: int) -> String:
	return FRAGMENTOS[id] % digito
