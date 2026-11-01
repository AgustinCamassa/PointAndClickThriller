extends Node
## Estado global de la partida: compatibilidad, tiempo, tramo, muertes, fragmentos y estadísticas.

signal compatibilidad_cambiada(valor: float)
signal tramo_cambiado(tramo: int)
signal fragmento_obtenido(id: String)
signal fragmento_oculto(id: String)
signal codigo_cambiado
signal partida_nueva
signal detector_obtenido

## Segundos en los que empieza cada tramo de presión (valores provisionales).
const INICIO_TRAMOS := [45.0, 180.0, 360.0]
## Orden del código (se desbloquea de izquierda a derecha en el terminal del laboratorio):
## recepción (silueta), pasillo (mancha), laboratorio (cuadro), cámara 3 (pitidos) y oficina de la sala 5 (viento/manchas).
const ORDEN_FRAGMENTOS := ["sombra", "mancha", "retrato", "pitidos", "viento"]
const DIGITOS := 5
const VISIBLE_DIGITO := 30.0       # un dígito resuelto se desvanece pasado este tiempo (valor provisional)
## Modos de juego (valores provisionales). El 2 se desbloquea al superar el 1 y el 3 al superar el 2 (en cualquiera de sus vidas).
##  sombra: "suma" (la sombra no esquivada suma compatibilidad), "mata" (muerte instantánea) o "pasos"
##  (modo 3: se oyen sus pasos cada 4 anomalías, en cualquier sala; hay que mantener el clic 1 s dentro de una ventana de 2 s).
##  bloqueo_codigo: segundos de bloqueo del terminal del laboratorio al equivocarse de dígito (además se reinicia lo confirmado).
##  penaliza_codigo: compatibilidad que suma ese error (0 en el modo 3, que empieza al 99 %: sumaría 5 y mataría).
const MODOS := {
	1: {"nombre": "Observación", "duracion_evento": 50.0, "max_activos": 2, "ventana_aviso": 8.0, "ocultarse": 5.0,
		"sombra": "suma", "suma_sombra": 20.0, "compat_inicial": 0.0, "compat_tras_morir": 60.0, "tramo_minimo": 0, "muertes_iniciales": 0, "parpadeo_penaliza": true, "parpadeo_factor": 1.0,
		"bloqueo_codigo": 30.0, "penaliza_codigo": 5.0},
	2: {"nombre": "Vigilancia estricta", "duracion_evento": 35.0, "max_activos": 5, "ventana_aviso": 3.5, "ocultarse": 2.5,
		"sombra": "mata", "suma_sombra": 0.0, "compat_inicial": 0.0, "compat_tras_morir": 80.0, "tramo_minimo": 0, "muertes_iniciales": 0, "parpadeo_penaliza": true, "parpadeo_factor": 1.0,
		"bloqueo_codigo": 45.0, "penaliza_codigo": 5.0},
	3: {"nombre": "Sesión roja", "duracion_evento": 35.0, "max_activos": 5, "ventana_aviso": 2.0, "ocultarse": 1.0,
		"sombra": "pasos", "suma_sombra": 0.0, "compat_inicial": 99.0, "compat_tras_morir": 99.0, "tramo_minimo": 3, "muertes_iniciales": 1, "parpadeo_penaliza": false, "parpadeo_factor": 2.0,
		"bloqueo_codigo": 60.0, "penaliza_codigo": 0.0},
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
var visibles := {}            # id -> segundos que le quedan al dígito de seguir a la vista
var codigo: Array[int] = []   # 5 dígitos, uno por anomalía del código (el último va de 1 a 9)
var solicitados := 0          # dígitos pedidos al terminal en toda la partida (no baja al morir)
var confirmados := 0          # dígitos introducidos en el terminal en esta vida, de izquierda a derecha
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
var estrella_reciente := ""         # estrella nueva de la última partida (el título la hace aparecer)
var ayuda_pitidos := false          # modo 1: nota de ayuda en la habitación tras morir atascado en el dígito de la cámara 3
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
	ayuda_pitidos = false
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
	codigo = []
	for i in DIGITOS:
		codigo.append(randi() % 10)
	codigo[DIGITOS - 1] = 1 + randi() % 9   # contar 0 manchas no se distinguiría de un pasillo normal
	jugando = true
	partida_nueva.emit()
	if tramo > 0:
		tramo_cambiado.emit(tramo)


func _process(delta: float) -> void:
	if not jugando:
		return
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


func digito_de(id: String) -> int:
	return codigo[ORDEN_FRAGMENTOS.find(id)]


## ¿Es este el dígito que toca introducir ahora? (pedido al terminal y aún sin confirmar; tras morir,
## los ya desbloqueados vuelven a pedirse uno a uno, y su anomalía vuelve a dar el dato.)
func armado(id: String) -> bool:
	return solicitados > confirmados and ORDEN_FRAGMENTOS.find(id) == confirmados


## Tras la primera muerte el terminal vuelve a 0: lo desbloqueado sigue siéndolo, pero hay que reintroducirlo.
func reiniciar_terminal() -> void:
	confirmados = 0
	visibles = {}
	codigo_cambiado.emit()


## Con el 5º dígito disponible (4 confirmados) el laboratorio empieza a susurrar a la derecha.
func quinto_disponible() -> bool:
	return confirmados >= DIGITOS - 1 and not codigo_completo()


func puede_solicitar() -> bool:
	return solicitados == confirmados and solicitados < DIGITOS


func solicitar() -> bool:
	if not puede_solicitar():
		return false
	solicitados += 1
	codigo_cambiado.emit()
	return true


## Se resuelve la anomalía de un dígito: solo se revela si el terminal lo había pedido. Devuelve si se reveló.
func revelar(id: String) -> bool:
	if not armado(id):
		return false
	visibles[id] = VISIBLE_DIGITO
	fragmento_obtenido.emit(id)
	return true


func digito_visible(id: String) -> bool:
	return visibles.has(id)


## Confirma en el terminal el dígito pedido: debe ser el siguiente, de izquierda a derecha.
func confirmar(indice: int, valor: int) -> bool:
	if indice != confirmados or indice >= solicitados or valor != codigo[indice]:
		return false
	confirmados += 1
	codigo_cambiado.emit()
	return true


func codigo_completo() -> bool:
	return confirmados >= DIGITOS


func _actualizar_visibles(delta: float) -> void:
	for id in visibles.keys():
		visibles[id] -= delta
		if visibles[id] <= 0.0:
			visibles.erase(id)
			fragmento_oculto.emit(id)


func tiempo_formateado() -> String:
	var total := int(tiempo)
	return "%02d:%02d" % [total / 60, total % 60]
