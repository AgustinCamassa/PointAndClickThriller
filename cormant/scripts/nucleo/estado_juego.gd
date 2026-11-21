extends Node
## Estado global de la partida: compatibilidad, tiempo, tramo, muertes, fragmentos y estadísticas.

signal compatibilidad_cambiada(valor: float)
signal tramo_cambiado(tramo: int)
signal fragmento_obtenido(id: String)
signal fragmento_oculto(id: String)
signal glifos_cambiado
signal partida_nueva
signal detector_obtenido

## Segundos en los que empieza cada tramo de presión (valores provisionales).
const INICIO_TRAMOS := [45.0, 180.0, 360.0]
## Orden de los glifos (se desbloquean de izquierda a derecha en el terminal del laboratorio):
## pasillo (mancha), laboratorio (cuadro), recepción (silueta), cámara 3 (pitidos en la estática) y oficina de la sala 5 (viento/manchas).
## La silueta, la más agresiva, va tercera para que el jugador se adapte antes con las otras dos.
const ORDEN_FRAGMENTOS := ["mancha", "retrato", "sombra", "pitidos", "viento"]
const NUM_GLIFOS := 5
const VISIBLE_GLIFO := 30.0        # un glifo resuelto se desvanece pasado este tiempo (valor provisional)
## Andrómeda (la protagonista) es el 5.º glifo (la oficina de la sala 5, donde reaparece al morir) solo en el modo 1; en los modos 2 y 3 se sortean los 5 glifos por igual. En el modo 1 los otros 4 se sortean en cada partida.
const GLIFO_FIJO := "andromeda"
## Modos de juego (valores provisionales). El 2 se desbloquea al superar el 1 y el 3 al superar el 2 (en cualquiera de sus vidas).
##  sombra: "suma" (la sombra no esquivada suma compatibilidad), "mata" (muerte instantánea) o "pasos"
##  (modo 3: se oyen sus pasos cada 4 anomalías, en cualquier sala; hay que mantener el clic 1 s dentro de una ventana de 2 s).
##  bloqueo_glifo: segundos de bloqueo del terminal del laboratorio al equivocarse de glifo (además se reinicia lo confirmado).
##  entidad_fase: segundos que dura cada fase de la entidad de la ventana (3 fases; se acorta en cada reaparición, ver Director). Modo 3: 0,5 s por fase = 1,5 s para reaccionar.
##  apagon_rondas: rondas de anomalías (una ronda = una vuelta completa de la bolsa) entre apagones entre el 60 y el 80 % de compatibilidad
##  (con 80 % o más es una por ronda en todos los modos); apagon_duracion: segundos que dura el apagón.
##  penaliza_glifo: compatibilidad que suma ese error (0 en el modo 3, que empieza al 99 %: sumaría 5 y mataría).
const MODOS := {
	1: {"nombre": "Observación", "duracion_evento": 50.0, "max_activos": 2, "ventana_aviso": 8.0, "ocultarse": 5.0,
		"sombra": "suma", "suma_sombra": 20.0, "compat_inicial": 0.0, "compat_tras_morir": 60.0, "tramo_minimo": 0, "muertes_iniciales": 0, "parpadeo_penaliza": true, "parpadeo_factor": 1.0,
		"bloqueo_glifo": 30.0, "penaliza_glifo": 5.0, "entidad_fase": 1.25, "apagon_rondas": 3, "apagon_duracion": 5.0},
	2: {"nombre": "Vigilancia estricta", "duracion_evento": 35.0, "max_activos": 5, "ventana_aviso": 3.5, "ocultarse": 2.5,
		"sombra": "mata", "suma_sombra": 0.0, "compat_inicial": 0.0, "compat_tras_morir": 80.0, "tramo_minimo": 0, "muertes_iniciales": 0, "parpadeo_penaliza": true, "parpadeo_factor": 1.0,
		"bloqueo_glifo": 45.0, "penaliza_glifo": 5.0, "entidad_fase": 1.0, "apagon_rondas": 2, "apagon_duracion": 5.0},
	3: {"nombre": "Sesión roja", "duracion_evento": 35.0, "max_activos": 5, "ventana_aviso": 2.0, "ocultarse": 1.0,
		"sombra": "pasos", "suma_sombra": 0.0, "compat_inicial": 99.0, "compat_tras_morir": 99.0, "tramo_minimo": 3, "muertes_iniciales": 1, "parpadeo_penaliza": false, "parpadeo_factor": 2.0,
		"bloqueo_glifo": 60.0, "penaliza_glifo": 0.0, "entidad_fase": 0.5, "apagon_rondas": 1, "apagon_duracion": 2.5},
}
const SOMBRA_CADA := 4              # modo 3: anomalías entre una sombra y la siguiente
const COMPATIBILIDAD_MAXIMA := 100.0   # llegar a este valor mata en todos los modos
const SALA_INICIAL := "recepcion"

var compatibilidad := 0.0
var tiempo := 0.0
var tramo := 0
var jugando := false
var muertes := 0
var sala_actual := SALA_INICIAL
var visibles := {}            # id -> segundos que le quedan al glifo de seguir a la vista
var glifos: Array[String] = []   # 5 glifos, uno por anomalía (en el modo 1 el último es siempre Andrómeda; en los modos 2 y 3 todos se sortean)
var solicitados := 0          # glifos pedidos al terminal en toda la partida (no baja al morir)
var confirmados := 0          # glifos introducidos en el terminal en esta vida, de izquierda a derecha
var aciertos := 0
var falsas_alarmas := 0
var ignoradas := 0
var finalizada := false
var modo := 1                       # modo de la partida en curso
var modo_desbloqueado := 1          # el más alto al que se puede jugar (se guarda en disco)
var desbloqueo_reciente := 0        # modo desbloqueado al terminar la última partida (0 = ninguno)
var ruta_progreso := "user://progreso.cfg"
## Una estrella en el cielo del título por cada final alcanzado (5 en total, en el orden de Casiopea).
const ESTRELLAS := ["m1_bueno", "m1_malo", "m2_bueno", "m2_malo", "m3"]
var estrellas: Array = []           # ids ya conseguidos (se guardan en disco)
## Modos superados (llegar al documento final, con cualquier final): modo 1 = m1_bueno o m1_malo; modo 2 = m2_*; modo 3 = m3.
## El título va aclarando el cartel del edificio con cada uno (0–3).
static func modos_superados_de(ids: Array) -> int:
	var n := 0
	if ids.has("m1_bueno") or ids.has("m1_malo"):
		n += 1
	if ids.has("m2_bueno") or ids.has("m2_malo"):
		n += 1
	if ids.has("m3"):
		n += 1
	return n


var estrella_reciente := ""         # estrella nueva de la última partida (el título la hace aparecer)
var pin: Array[int] = []              # PIN de 4 dígitos de la puerta de Vigilancia (aleatorio en cada partida)
var vigilancia_abierta := false      # se ha metido el PIN: hasta entonces no corre el reloj ni surgen anomalías
var tiene_tarjeta := false          # tarjeta de seguridad del archivero de Vigilancia: abre el laboratorio; se conserva tras morir
var tiene_detector := false         # se consigue con el primer clic en las cámaras de Vigilancia; se pierde al empezar otra partida
var invulnerable := false           # solo para el desarrollador (tecla G): ignora todo el daño


func _ready() -> void:
	_registrar_acciones()
	cargar_progreso()
	nueva_partida()
	jugando = false


func _registrar_acciones() -> void:
	if InputMap.has_action("ocultarse"):
		return
	InputMap.add_action("ocultarse")
	for tecla in [KEY_SPACE, KEY_H]:
		var evento := InputEventKey.new()
		evento.keycode = tecla
		InputMap.action_add_event("ocultarse", evento)


## Apaga los atajos del desarrollador (se llama al volver al título).
func desactivar_trucos() -> void:
	invulnerable = false


func cfg(clave: String):
	return MODOS[modo][clave]


func cargar_progreso() -> void:
	var f := ConfigFile.new()
	if f.load(ruta_progreso) == OK:
		modo_desbloqueado = clampi(int(f.get_value("progreso", "modo_desbloqueado", 1)), 1, MODOS.size())
		estrellas.clear()
		for id in f.get_value("progreso", "estrellas", []):
			if ESTRELLAS.has(str(id)) and not estrellas.has(str(id)):
				estrellas.append(str(id))


func guardar_progreso() -> void:
	var f := ConfigFile.new()
	f.set_value("progreso", "modo_desbloqueado", modo_desbloqueado)
	f.set_value("progreso", "estrellas", estrellas)
	f.save(ruta_progreso)


## Identificador del final que se está alcanzando: modo 1 y 2 tienen final bueno (sin muertes) y malo; el 3 es único.
func id_final() -> String:
	if modo >= MODOS.size():
		return "m%d" % modo
	return "m%d_%s" % [modo, "malo" if muertes > 0 else "bueno"]


## Se ha llegado al final (bueno o malo) del modo en curso: suma su estrella y desbloquea el siguiente.
## Devuelve el modo nuevo o 0.
func superar_modo() -> int:
	desbloqueo_reciente = 0
	var id := id_final()
	if not estrellas.has(id):
		estrellas.append(id)
		estrella_reciente = id
		guardar_progreso()
	if modo == modo_desbloqueado and modo < MODOS.size():
		modo_desbloqueado = modo + 1
		desbloqueo_reciente = modo_desbloqueado
		guardar_progreso()
	return desbloqueo_reciente


func comprobar_pin(digitos: Array) -> bool:
	if digitos.size() != pin.size():
		return false
	for i in pin.size():
		if int(digitos[i]) != pin[i]:
			return false
	return true


func abrir_vigilancia() -> void:
	vigilancia_abierta = true


func obtener_tarjeta() -> void:
	tiene_tarjeta = true


func obtener_detector() -> void:
	if not tiene_detector:
		tiene_detector = true
		detector_obtenido.emit()


func nueva_partida() -> void:
	modo = clampi(modo, 1, modo_desbloqueado)
	compatibilidad = cfg("compat_inicial")
	tiempo = 0.0
	tramo = cfg("tramo_minimo")
	muertes = cfg("muertes_iniciales")
	desbloqueo_reciente = 0
	estrella_reciente = ""
	sala_actual = SALA_INICIAL
	visibles = {}
	solicitados = 0
	confirmados = 0
	aciertos = 0
	falsas_alarmas = 0
	ignoradas = 0
	finalizada = false
	tiene_detector = false
	tiene_tarjeta = false
	vigilancia_abierta = false
	pin = []
	for i in 4:
		pin.append(randi() % 10)
	var sorteados: Array = Glifos.REALES.duplicate()
	if modo == 1:
		sorteados.erase(GLIFO_FIJO)
	sorteados.shuffle()
	glifos.clear()
	for g in sorteados:
		glifos.append(g)
	if modo == 1:
		glifos.append(GLIFO_FIJO)
	jugando = true
	partida_nueva.emit()
	if tramo > 0:
		tramo_cambiado.emit(tramo)


func _process(delta: float) -> void:
	if not jugando or not vigilancia_abierta:
		return   # sin entrar en Vigilancia no corre el reloj
	tiempo += delta
	_actualizar_visibles(delta)
	var nuevo: int = cfg("tramo_minimo")
	for limite in INICIO_TRAMOS:
		if tiempo >= limite:
			nuevo = maxi(nuevo, INICIO_TRAMOS.find(limite) + 1)
	if nuevo != tramo:
		tramo = nuevo
		tramo_cambiado.emit(tramo)


func filtro_rojo() -> bool:
	return muertes > 0


func sumar_compatibilidad(cantidad: float, forzado := false) -> void:
	## Con la invulnerabilidad activa no sube la compatibilidad (salvo que se fuerce a propósito, como hace la tecla F).
	if invulnerable and cantidad > 0.0 and not forzado:
		return
	compatibilidad = clampf(compatibilidad + cantidad, 0.0, 100.0)
	compatibilidad_cambiada.emit(compatibilidad)


func fijar_compatibilidad(valor: float) -> void:
	compatibilidad = clampf(valor, 0.0, 100.0)
	compatibilidad_cambiada.emit(compatibilidad)


func glifo_de(id: String) -> String:
	return glifos[ORDEN_FRAGMENTOS.find(id)]


## ¿Es este el glifo que toca introducir ahora? (pedido al terminal y aún sin confirmar; tras morir,
## los ya desbloqueados vuelven a pedirse uno a uno, y su anomalía vuelve a dar el dato.)
func armado(id: String) -> bool:
	return solicitados > confirmados and ORDEN_FRAGMENTOS.find(id) == confirmados


## Tras la primera muerte el terminal vuelve a 0: lo desbloqueado sigue siéndolo, pero hay que reintroducirlo.
func reiniciar_terminal() -> void:
	confirmados = 0
	visibles = {}
	glifos_cambiado.emit()


## Con el 5º glifo disponible (4 confirmados) el laboratorio empieza a susurrar a la derecha.
func quinto_disponible() -> bool:
	return confirmados >= NUM_GLIFOS - 1 and not glifos_completos()


## ¿Se ha pedido ya el glifo de la recepción (el de la silueta)? Hasta entonces la silueta es lenta, hace menos daño y sale menos.
func silueta_solicitada() -> bool:
	return solicitados > ORDEN_FRAGMENTOS.find("sombra")


## «Rodaje» de la silueta: solo en el modo 1 y hasta que se pide su glifo o se reaparece tras la primera muerte. Mientras dure, la silueta
## sale una de cada 2 rondas, va al doble de lento y hace la mitad de daño. En los modos 2 y 3, y tras reaparecer, va siempre a su ritmo normal.
func silueta_en_rodaje() -> bool:
	return modo == 1 and muertes == 0 and not silueta_solicitada()


func puede_solicitar() -> bool:
	return solicitados == confirmados and solicitados < NUM_GLIFOS


func solicitar() -> bool:
	if not puede_solicitar():
		return false
	solicitados += 1
	glifos_cambiado.emit()
	return true


## Se resuelve la anomalía de un glifo: solo se revela si el terminal lo había pedido. Devuelve si se reveló.
func revelar(id: String) -> bool:
	if not armado(id):
		return false
	visibles[id] = VISIBLE_GLIFO
	fragmento_obtenido.emit(id)
	return true


## ¿Se ha pedido ya al terminal el glifo de este puzzle (aunque luego se haya reiniciado el terminal)? A diferencia de `armado`,
## no depende de cuántos se hayan reintroducido: lo pedido y visto en su sitio sigue siendo siempre el correcto.
func solicitado(id: String) -> bool:
	return solicitados > ORDEN_FRAGMENTOS.find(id)


## El glifo de un puzzle cambia al azar por otro de la paleta distinto del actual y de los de los demás puzzles
## (si no queda ninguno, por cualquiera distinto del actual). Solo se usa en el puzzle de la CAM 3.
func resortear_glifo(id: String) -> void:
	var i := ORDEN_FRAGMENTOS.find(id)
	var libres: Array = []
	for g in Glifos.PALETA:
		if g != glifos[i] and not glifos.has(g):
			libres.append(g)
	if libres.is_empty():
		for g in Glifos.PALETA:
			if g != glifos[i]:
				libres.append(g)
	glifos[i] = libres[randi() % libres.size()]
	visibles.erase(id)
	glifos_cambiado.emit()


## Modo 1: la nota de la CAM 3 añade la pista de los pitidos mientras su glifo está pedido y sin introducir (no hace falta haber muerto).
func pista_pitidos() -> bool:
	return modo == 1 and solicitado("pitidos") and confirmados <= ORDEN_FRAGMENTOS.find("pitidos")


func glifo_visible(id: String) -> bool:
	return visibles.has(id)


## Confirma en el terminal el glifo pedido: debe ser el siguiente, de izquierda a derecha.
func confirmar(indice: int, valor: String) -> bool:
	if indice != confirmados or indice >= solicitados or valor != glifos[indice]:
		return false
	confirmados += 1
	glifos_cambiado.emit()
	return true


func glifos_completos() -> bool:
	return confirmados >= NUM_GLIFOS


func _actualizar_visibles(delta: float) -> void:
	for id in visibles.keys():
		visibles[id] -= delta
		if visibles[id] <= 0.0:
			visibles.erase(id)
			fragmento_oculto.emit(id)


func tiempo_formateado() -> String:
	var total := int(tiempo)
	return "%02d:%02d" % [total / 60, total % 60]
