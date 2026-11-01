extends Node
## Director de eventos: genera anomalías (bolsa aleatoria), aplica penalizaciones
## y gestiona a la entidad (advertencia + ocultarse). Todos los valores son PROVISIONALES.

signal evento_iniciado(evento)
signal evento_terminado(evento, resultado: String)
signal terminal_bloqueado(segundos: float)
signal silueta_cambiada(visible: bool)
signal advertencia_iniciada
signal advertencia_terminada(sobrevivio: bool)
signal mensaje(texto: String)
signal jugador_muerto
signal pitidos_cambiados(activo: bool)
signal parpadeo_cambiado(activo: bool)

# --- Valores ajustables -------------------------------------------------------
const SEMILLA_FIJA := -1                 # >= 0 para depurar con orden fijo
const DURACION_EVENTO := 35.0
const PROBABILIDAD_FALSO := 0.4
const MINIMO_ENTRE_EVENTOS := 4.0
const GRACIA_TRAS_ERROR := 10.0
const BLOQUEO_FALSA_ALARMA := 8.0
const PENALIZA_IGNORAR := 10.0
const PENALIZA_FALSA_ALARMA := 5.0
const PENALIZA_SALA_MARCADA := 10.0
const DURACION_MARCA := 25.0
const SILUETA_MIN := 6.0
const SILUETA_MAX := 9.0
const DURACION_PITIDOS := 30.0
const DURACION_PARPADEO := 3.5
const MINIMO_ENTRE_PARPADEOS := 45.0
const VISIBLE_NUMERO := 30.0             # el número de recepción también se desvanece (desde que se apaga la marca)
const ESPERA_VIENTO := 40.0              # tras desvanecerse las manchas, el viento tarda en volver
## Modo 3: la sombra puede contar y atacar solo con el jugador en Vigilancia (true) o en cualquier sala (false).
const SOMBRA_SOLO_VIGILANCIA := false
# Por tramo (índice 0..3): [intervalo mínimo, intervalo máximo]. El máximo de activas depende del modo.
const TRAMOS := [[0.0, 0.0], [10.0, 16.0], [7.0, 12.0], [5.0, 9.0]]
# Entidad
const UMBRAL_TONO := 30.0
const UMBRAL_ADVERTENCIA := 60.0
const UMBRAL_ALTO := 85.0
const AVISO_VENTANA := 7.0               # tiempo total para reaccionar
const OCULTARSE_NECESARIO := 5.0         # segundos continuos que hay que mantener

## Seis anomalías. Reportables (menú de Vigilancia): cuadro, mancha y voz. Ambientales: pitidos, silueta, parpadeo.
## Dan un dígito del código: cuadro (laboratorio), mancha (pasillo), silueta (recepción) y pitidos (cámara 3).
const TIPOS := ["cuadro", "mancha", "voz", "pitidos", "silueta", "parpadeo"]
const RECURRENTES := ["cuadro", "mancha"]   # si se ignoran siguen ahí, pero pueden volver para resolverse
const DESCRIPCION := {
	"cuadro": "Anomalía visual · CAM 1 (Laboratorio)",
	"mancha": "Anomalía visual · CAM 2 (Pasillo)",
	"voz": "Anomalía de audio · CAM 3 (sin señal)",
}
const FRAGMENTO_DE := {"cuadro": "retrato", "mancha": "mancha"}
## Anomalía que da cada dígito (el 5º tiene su propia anomalía, fuera de la bolsa).
const TIPO_DE_DIGITO := {"sombra": "silueta", "mancha": "mancha", "pitidos": "pitidos", "retrato": "cuadro"}

## Duración (s) de una vuelta de pitidos: N pitidos + silencio; el 0 es un tono largo.
static func segundos_pitidos(digito: int) -> float:
	return (0.9 if digito == 0 else digito * 0.46) + 1.8

class Evento:
	var tipo: String
	var real: bool
	var restante: float
	var pista := ""
	func _init(t: String, r: bool, d: float) -> void:
		tipo = t
		real = r
		restante = d

var rng := RandomNumberGenerator.new()
var eventos: Array = []
var bolsa: Array = []
var ultimo_tipo := ""
var fijas := {}                  # anomalías reales ignoradas que se quedan
var gracia := 0.0
var bloqueo := 0.0
var desde_ultimo := 999.0
var proximo := -1.0
var sala_marcada := ""
var marca_restante := 0.0
var silueta_visible := false
var _silueta_restante := 0.0
var numero_recepcion := false      # hay un número escrito en la recepción (aparece al apagarse la marca)
var numero_restante := 0.0         # segundos que le quedan visible una vez apagada la marca
var pitidos_digito_falso := 0      # cuenta que suenan si el terminal no había pedido ese dígito
var pitidos_escuchados := false
var viento_espera := 0.0
var viento_manchas_restante := 0.0
var bloqueo_lab := 0.0
var anomalias_desde_sombra := 0    # modo 3: anomalías surgidas desde la última sombra
var pitidos_restante := 0.0
var parpadeo_pendiente := false
var parpadeo_restante := 0.0
var desde_parpadeo := 999.0

var advertencia_activa := false
var aviso_restante := 0.0
var ocultacion := 0.0
var manteniendo := false
var proximo_aviso := -1.0

var depuracion := false


func _ready() -> void:
	EstadoJuego.codigo_cambiado.connect(_priorizar)
	reiniciar()
	EstadoJuego.partida_nueva.connect(reiniciar)
	EstadoJuego.tramo_cambiado.connect(_al_cambiar_tramo)


func reiniciar() -> void:
	if SEMILLA_FIJA >= 0:
		rng.seed = SEMILLA_FIJA
	else:
		rng.randomize()
	eventos.clear()
	fijas = {}
	gracia = 0.0
	bloqueo = 0.0
	desde_ultimo = 999.0
	proximo = -1.0
	sala_marcada = ""
	marca_restante = 0.0
	silueta_visible = false
	_silueta_restante = 0.0
	numero_recepcion = false
	numero_restante = 0.0
	pitidos_escuchados = false
	viento_espera = 0.0
	viento_manchas_restante = 0.0
	bloqueo_lab = 0.0
	anomalias_desde_sombra = 0
	pitidos_restante = 0.0
	parpadeo_pendiente = false
	parpadeo_restante = 0.0
	desde_parpadeo = 999.0
	advertencia_activa = false
	ocultacion = 0.0
	manteniendo = false
	proximo_aviso = -1.0
	ultimo_tipo = ""
	bolsa = ["cuadro"]
	var resto := ["mancha", "voz", "pitidos", "silueta", "parpadeo"]
	_barajar(resto)
	bolsa.append_array(resto)
	Sonido.detener_todo()


func _barajar(lista: Array) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp


# --- Consultas -----------------------------------------------------------------

func reportables() -> Array:
	return eventos


func evento_de(tipo: String) -> Evento:
	for e in eventos:
		if e.tipo == tipo:
			return e
	return null


func cuadro_girado() -> bool:
	if fijas.has("cuadro"):
		return true
	var e := evento_de("cuadro")
	return e != null and e.real


func cuadro_en_camara() -> bool:
	## La cámara avisa de la anomalía pero no distingue si es real o una lectura falsa.
	return fijas.has("cuadro") or evento_de("cuadro") != null


func mancha_visible() -> bool:
	## Lo que se ve en persona en el pasillo.
	if fijas.has("mancha"):
		return true
	var e := evento_de("mancha")
	return e != null and e.real


func mancha_en_camara() -> bool:
	return fijas.has("mancha") or evento_de("mancha") != null


func pitidos_activos() -> bool:
	return pitidos_restante > 0.0


func numero_recepcion_visible() -> bool:
	## El número solo está escrito si el terminal ya lo había pedido; se ve hasta que se desvanece.
	return numero_recepcion and marca_restante <= 0.0 and numero_restante > 0.0 and EstadoJuego.armado("sombra")


## Cuenta de pitidos que suena: la real solo si el terminal había pedido ese dígito; si no, una cuenta falsa.
func pitidos_digito() -> int:
	return EstadoJuego.digito_de("pitidos") if EstadoJuego.armado("pitidos") else pitidos_digito_falso


## El viento suena en la oficina de la sala 5 cuando se pide el último dígito y no hay manchas a la vista.
func viento_activo() -> bool:
	return EstadoJuego.armado("viento") and viento_manchas_restante <= 0.0 and viento_espera <= 0.0


func manchas_viento_visibles() -> bool:
	return viento_manchas_restante > 0.0


## El jugador mira por la ventana de la oficina mientras suena el viento.
func ver_manchas_viento() -> bool:
	if not viento_activo():
		return false
	viento_manchas_restante = EstadoJuego.VISIBLE_DIGITO
	return true


## Dígito equivocado en el terminal del laboratorio: bloqueo según el modo y todo lo confirmado vuelve a 0
## (lo desbloqueado sigue desbloqueado, pero hay que reintroducirlo).
func codigo_erroneo() -> void:
	var penaliza: float = EstadoJuego.cfg("penaliza_codigo")
	if penaliza > 0.0:
		EstadoJuego.sumar_compatibilidad(penaliza)
	bloqueo_lab = EstadoJuego.cfg("bloqueo_codigo")
	EstadoJuego.reiniciar_terminal()
	Sonido.reproducir("error_terminal")


func terminal_lab_ocupado() -> bool:
	return bloqueo_lab > 0.0


func _activos_total() -> int:
	return eventos.size() + (1 if pitidos_activos() else 0) + (1 if silueta_visible else 0)


func voz_audible() -> bool:
	if fijas.has("voz"):
		return true
	var e := evento_de("voz")
	return e != null and e.real


func terminal_ocupado() -> bool:
	return bloqueo > 0.0


func maximo_activos() -> int:
	return EstadoJuego.cfg("max_activos")


func duracion_evento() -> float:
	return EstadoJuego.cfg("duracion_evento")


## Segundos que dura el aviso de la sombra y segundos seguidos que hay que mantener la ocultación (según el modo).
func ventana_aviso() -> float:
	return EstadoJuego.cfg("ventana_aviso")


func ocultarse_necesario() -> float:
	return EstadoJuego.cfg("ocultarse")


# --- Bucle principal ---------------------------------------------------------------

func _process(delta: float) -> void:
	if not EstadoJuego.jugando:
		return
	desde_ultimo += delta
	desde_parpadeo += delta
	gracia = maxf(0.0, gracia - delta)
	_actualizar_bloqueo(delta)
	_actualizar_viento(delta)
	_actualizar_marca(delta)
	_actualizar_silueta(delta)
	_actualizar_pitidos(delta)
	_actualizar_parpadeo(delta)
	_actualizar_eventos(delta)
	_actualizar_generacion(delta)
	_actualizar_entidad(delta)
	if EstadoJuego.compatibilidad >= EstadoJuego.COMPATIBILIDAD_MAXIMA:
		morir()


func _actualizar_bloqueo(delta: float) -> void:
	if bloqueo > 0.0:
		bloqueo = maxf(0.0, bloqueo - delta)
	if bloqueo_lab > 0.0:
		bloqueo_lab = maxf(0.0, bloqueo_lab - delta)


func _actualizar_viento(delta: float) -> void:
	if viento_manchas_restante > 0.0:
		viento_manchas_restante -= delta
		if viento_manchas_restante <= 0.0:
			viento_manchas_restante = 0.0
			viento_espera = ESPERA_VIENTO
	elif viento_espera > 0.0:
		viento_espera = maxf(0.0, viento_espera - delta)


func _actualizar_marca(delta: float) -> void:
	if marca_restante > 0.0:
		marca_restante -= delta
		if marca_restante <= 0.0:
			sala_marcada = ""
			if numero_recepcion:
				numero_restante = VISIBLE_NUMERO
	elif numero_restante > 0.0:
		numero_restante -= delta
		if numero_restante <= 0.0:
			numero_restante = 0.0
			numero_recepcion = false


func _actualizar_silueta(delta: float) -> void:
	if silueta_visible:
		_silueta_restante -= delta
		if _silueta_restante <= 0.0:
			silueta_visible = false
			silueta_cambiada.emit(false)


func _actualizar_pitidos(delta: float) -> void:
	if pitidos_restante > 0.0:
		pitidos_restante -= delta
		if pitidos_restante <= 0.0:
			pitidos_restante = 0.0
			pitidos_cambiados.emit(false)


func _actualizar_parpadeo(delta: float) -> void:
	## Los parpadeos solo se manifiestan en Vigilancia; si el jugador no está, esperan a que entre.
	if parpadeo_pendiente and EstadoJuego.sala_actual == "vigilancia":
		parpadeo_pendiente = false
		parpadeo_restante = DURACION_PARPADEO * EstadoJuego.cfg("parpadeo_factor")
		desde_parpadeo = 0.0
		EstadoJuego.ignoradas += 1
		# Modo 3: el parpadeo no suma compatibilidad; en su lugar dura el doble y es el doble de intenso.
		if EstadoJuego.cfg("parpadeo_penaliza"):
			EstadoJuego.sumar_compatibilidad(PENALIZA_IGNORAR)
		Sonido.reproducir("golpe_grave")
		Sonido.reproducir("estatica_breve")
		mensaje.emit("Las luces de Vigilancia parpadean. No hay forma de evitarlo.")
		parpadeo_cambiado.emit(true)
	if parpadeo_restante > 0.0:
		parpadeo_restante -= delta
		if parpadeo_restante <= 0.0:
			parpadeo_restante = 0.0
			parpadeo_cambiado.emit(false)


func _actualizar_eventos(delta: float) -> void:
	for e in eventos.duplicate():
		e.restante -= delta
		if e.restante <= 0.0:
			_resolver(e, "expirado")


func _al_cambiar_tramo(tramo: int) -> void:
	if tramo == 1:
		proximo = 8.0
	Sonido.detener_bucle("ambiente_tramo_%d" % (tramo - 1))
	if tramo > 0:
		Sonido.bucle("ambiente_tramo_%d" % tramo)


func _actualizar_generacion(delta: float) -> void:
	if EstadoJuego.tramo == 0 or advertencia_activa or gracia > 0.0:
		return
	if proximo < 0.0:
		proximo = _intervalo()
	proximo -= delta
	if proximo > 0.0:
		return
	if desde_ultimo < MINIMO_ENTRE_EVENTOS or _activos_total() >= maximo_activos():
		proximo = 1.0
		return
	var tipo := _elegir_tipo()
	if tipo == "":
		proximo = 5.0
		return
	_crear(tipo)
	proximo = _intervalo()


func _intervalo() -> float:
	var t: Array = TRAMOS[EstadoJuego.tramo]
	return rng.randf_range(t[0], t[1])


# --- Creación de eventos -------------------------------------------------------------

## Al pedir un dígito, su anomalía gana prioridad dentro de la bolsa, pero nunca sale la primera:
## se coloca en segundo o tercer lugar (así sale una vez otra anomalía, y el azar sigue siendo justo).
func _priorizar() -> void:
	if not EstadoJuego.jugando or EstadoJuego.solicitados <= EstadoJuego.confirmados:
		return
	var id: String = EstadoJuego.ORDEN_FRAGMENTOS[EstadoJuego.confirmados]
	if not TIPO_DE_DIGITO.has(id):
		return
	var t: String = TIPO_DE_DIGITO[id]
	var i := bolsa.find(t)
	if i == -1 or bolsa.size() < 2 or (i >= 1 and i <= 2):
		return
	bolsa.remove_at(i)
	bolsa.insert(mini(rng.randi_range(1, 2), bolsa.size()), t)


func _rellenar_bolsa() -> void:
	bolsa = []
	for t in TIPOS:
		if not fijas.has(t) or RECURRENTES.has(t):
			bolsa.append(t)
	_barajar(bolsa)
	if bolsa.size() > 1 and bolsa[0] == ultimo_tipo:
		var tmp = bolsa[0]
		bolsa[0] = bolsa[1]
		bolsa[1] = tmp
	_priorizar()


func _elegir_tipo() -> String:
	if bolsa.is_empty():
		_rellenar_bolsa()
	# Tras morir se despierta en la habitación secreta: mientras el jugador siga ahí solo puede surgir el parpadeo
	# (la entidad tiene su propio temporizador y también puede aparecer).
	var en_habitacion: bool = EstadoJuego.sala_actual == "habitacion_secreta"
	for i in bolsa.size():
		var t: String = bolsa[i]
		if en_habitacion and t != "parpadeo":
			continue
		if fijas.has(t) and not RECURRENTES.has(t):
			continue
		match t:
			"silueta":
				if silueta_visible:
					continue
			"pitidos":
				if pitidos_activos() or evento_de("voz") != null:
					continue
			"voz":
				if pitidos_activos() or evento_de("voz") != null:
					continue
			"parpadeo":
				if parpadeo_pendiente or parpadeo_restante > 0.0 or EstadoJuego.tramo < 2 or desde_parpadeo < MINIMO_ENTRE_PARPADEOS:
					continue
			_:
				if evento_de(t) != null:
					continue
		bolsa.remove_at(i)
		return t
	return ""


func forzar(tipo: String) -> void:
	## Solo para depuración.
	_crear(tipo)


func _crear(tipo: String) -> void:
	# Modo 3: el contador de la sombra avanza con cada anomalía (con SOMBRA_SOLO_VIGILANCIA, solo estando en Vigilancia).
	if not SOMBRA_SOLO_VIGILANCIA or EstadoJuego.sala_actual == "vigilancia":
		anomalias_desde_sombra += 1
	ultimo_tipo = tipo
	desde_ultimo = 0.0
	match tipo:
		"silueta":
			_aparece_silueta()
			return
		"pitidos":
			_aparece_pitidos()
			return
		"parpadeo":
			parpadeo_pendiente = true
			return
	# Si la anomalía sigue ahí por haberla ignorado, la nueva señal es real: así se puede resolver.
	var real := fijas.has(tipo) or rng.randf() >= PROBABILIDAD_FALSO
	var e := Evento.new(tipo, real, duracion_evento())
	eventos.append(e)
	if not EstadoJuego.tiene_detector:   # con el detector, el aviso lo da él (LEDs y pitido)
		Sonido.reproducir("alerta_terminal")
	if tipo == "voz":
		Sonido.reproducir("susurro_terminal")
		mensaje.emit("La cámara 3 sigue sin señal, pero el altavoz susurra.")
	else:
		mensaje.emit("El terminal ha registrado una señal.")
	evento_iniciado.emit(e)


func _aparece_pitidos() -> void:
	pitidos_restante = DURACION_PITIDOS
	pitidos_escuchados = false
	pitidos_digito_falso = (EstadoJuego.digito_de("pitidos") + 1 + rng.randi() % 9) % 10   # siempre distinto del real
	if not EstadoJuego.tiene_detector:   # con el detector, el aviso lo da él (LEDs y pitido)
		Sonido.reproducir("alerta_terminal")
	mensaje.emit("La cámara 3 emite pitidos.")
	pitidos_cambiados.emit(true)


## La cámara 3 avisa de que el jugador ha oído una vuelta completa de pitidos.
func pitidos_oidos() -> void:
	if not pitidos_escuchados:
		pitidos_escuchados = true
		if EstadoJuego.armado("pitidos"):
			mensaje.emit("Lo he oído. Tengo que contar los pitidos.")


func _aparece_silueta() -> void:
	silueta_visible = true
	_silueta_restante = rng.randf_range(SILUETA_MIN, SILUETA_MAX)
	sala_marcada = "recepcion"
	marca_restante = DURACION_MARCA
	numero_recepcion = true
	Sonido.reproducir("estatica_breve")
	silueta_cambiada.emit(true)


# --- Resolución -----------------------------------------------------------------------

func reportar(e: Evento) -> void:
	if bloqueo > 0.0 or not eventos.has(e):
		return
	_resolver(e, "reportado")


func descartar(e: Evento) -> void:
	if bloqueo > 0.0 or not eventos.has(e):
		return
	_resolver(e, "descartado")


func _resolver(e: Evento, como: String) -> void:
	eventos.erase(e)
	var resultado := ""
	if como == "reportado":
		if e.real:
			EstadoJuego.aciertos += 1
			resultado = "acierto"
			fijas.erase(e.tipo)
			if FRAGMENTO_DE.has(e.tipo) and not EstadoJuego.revelar(FRAGMENTO_DE[e.tipo]):
				mensaje.emit("Anomalía registrada. El terminal del laboratorio no esperaba ese dato.")
			else:
				mensaje.emit("Anomalía registrada. Eso era real.")
			Sonido.reproducir("confirmacion")
		else:
			EstadoJuego.falsas_alarmas += 1
			EstadoJuego.sumar_compatibilidad(PENALIZA_FALSA_ALARMA)
			bloqueo = BLOQUEO_FALSA_ALARMA
			_tras_error()
			resultado = "falsa_alarma"
			mensaje.emit(_texto_falsa_alarma(e))
			terminal_bloqueado.emit(bloqueo)
			Sonido.reproducir("error_terminal")
	else:
		if e.real:
			_ignorada(e)
			resultado = "ignorada"
		else:
			resultado = "descarte_correcto"
	if como == "expirado" and not e.real:
		resultado = "descarte_correcto"
	evento_terminado.emit(e, resultado)


func _ignorada(e: Evento) -> void:
	EstadoJuego.ignoradas += 1
	EstadoJuego.sumar_compatibilidad(PENALIZA_IGNORAR)
	fijas[e.tipo] = true
	_tras_error()
	var texto := ""
	match e.tipo:
		"cuadro":
			texto = "Era real. El cuadro del laboratorio se queda torcido."
		"mancha":
			texto = "Era real. La mancha del pasillo se queda."
		"voz":
			texto = "Era real. El susurro de la cámara 3 se queda."
	mensaje.emit(texto)
	Sonido.reproducir("error_terminal")


func _texto_falsa_alarma(e: Evento) -> String:
	match e.tipo:
		"cuadro":
			return "Falsa alarma: el cuadro estaba recto."
		"mancha":
			return "Falsa alarma: el suelo del pasillo estaba limpio."
		"voz":
			return "Falsa alarma: no había ningún susurro."
	return "Falsa alarma."


func _tras_error() -> void:
	gracia = GRACIA_TRAS_ERROR


# --- Verificación en persona ------------------------------------------------------------

func entrar_sala(id: String) -> void:
	## Llamado por el escenario cada vez que el jugador llega a una sala.
	if id == sala_marcada and marca_restante > 0.0:
		EstadoJuego.sumar_compatibilidad(PENALIZA_SALA_MARCADA)
		sala_marcada = ""
		marca_restante = 0.0
		if numero_recepcion:
			numero_restante = VISIBLE_NUMERO
		_tras_error()
		mensaje.emit("Había algo aquí. No debí entrar.")
		Sonido.reproducir("golpe_grave")
	match id:
		"pasillo":
			var m := evento_de("mancha")
			if m != null:
				if m.real:
					m.pista = "Pasillo comprobado: hay una mancha en el suelo."
					mensaje.emit("Hay una mancha oscura en el suelo del pasillo.")
				else:
					m.pista = "Pasillo comprobado: el suelo está limpio."
					mensaje.emit("El suelo del pasillo está limpio.")
			elif fijas.has("mancha"):
				mensaje.emit("La mancha sigue ahí.")
		"oficina":
			if EstadoJuego.quinto_disponible() and not EstadoJuego.armado("viento"):
				mensaje.emit("Aquí no pasa nada. Falta pedir el último dato al terminal.")
			# La oficina da al pasillo de la habitación 5: el sonido de la cámara 3 se comprueba aquí.
			var v := evento_de("voz")
			if v != null:
				if v.real:
					v.pista = "Oficina comprobada: se oye un susurro al otro lado del cristal."
					mensaje.emit("Un susurro atraviesa el cristal.")
					Sonido.reproducir("susurro_pasillo")
				else:
					v.pista = "Oficina comprobada: silencio."
					mensaje.emit("La oficina está en silencio.")
			elif fijas.has("voz"):
				mensaje.emit("El susurro sigue ahí, muy bajo.")
		"laboratorio":
			var c := evento_de("cuadro")
			if c != null:
				c.pista = "Laboratorio comprobado: marco girado." if c.real else "Laboratorio comprobado: marco recto."


# --- Entidad ------------------------------------------------------------------------------

func _actualizar_entidad(delta: float) -> void:
	var comp := EstadoJuego.compatibilidad
	if comp >= UMBRAL_TONO:
		var volumen := lerpf(-30.0, -8.0, clampf((comp - UMBRAL_TONO) / 70.0, 0.0, 1.0))
		Sonido.bucle("tono_grave", volumen)
	else:
		Sonido.detener_bucle("tono_grave")
	if advertencia_activa:
		aviso_restante -= delta
		if manteniendo:
			ocultacion += delta
			if ocultacion >= ocultarse_necesario():
				_terminar_advertencia(true)
				return
		else:
			ocultacion = 0.0
		if aviso_restante <= 0.0:
			_terminar_advertencia(false)
		return
	if EstadoJuego.cfg("sombra") == "pasos":
		_actualizar_sombra_pasos()
		return
	if comp < UMBRAL_ADVERTENCIA:
		proximo_aviso = -1.0
		return
	if proximo_aviso < 0.0:
		proximo_aviso = rng.randf_range(20.0, 30.0)
	proximo_aviso -= delta
	if proximo_aviso <= 0.0:
		_iniciar_advertencia()


## Modo 3: cada 4 anomalías que surgen se oyen los pasos de la entidad, en cualquier sala (el jugador tiene 2 s para
## empezar a ocultarse y mantenerlo 1 s). Con SOMBRA_SOLO_VIGILANCIA solo cuenta y ataca estando en Vigilancia
## (fuera, el contador queda congelado).
func _actualizar_sombra_pasos() -> void:
	if SOMBRA_SOLO_VIGILANCIA and EstadoJuego.sala_actual != "vigilancia":
		return
	if anomalias_desde_sombra >= EstadoJuego.SOMBRA_CADA:
		anomalias_desde_sombra = 0
		_iniciar_advertencia()


func _iniciar_advertencia() -> void:
	advertencia_activa = true
	aviso_restante = ventana_aviso()
	ocultacion = 0.0
	Sonido.reproducir("pasos_entidad" if EstadoJuego.cfg("sombra") == "pasos" else "advertencia_entidad")
	advertencia_iniciada.emit()


func _terminar_advertencia(sobrevivio: bool) -> void:
	advertencia_activa = false
	ocultacion = 0.0
	if sobrevivio:
		if EstadoJuego.compatibilidad >= UMBRAL_ALTO:
			proximo_aviso = rng.randf_range(25.0, 35.0)
		else:
			proximo_aviso = rng.randf_range(45.0, 60.0)
		mensaje.emit("Pasó de largo.")
	advertencia_terminada.emit(sobrevivio)
	if sobrevivio:
		return
	if EstadoJuego.cfg("sombra") == "suma":
		# Modo 1: la sombra no mata; suma compatibilidad (y se muere al llegar al 100 %).
		EstadoJuego.sumar_compatibilidad(EstadoJuego.cfg("suma_sombra"))
		proximo_aviso = rng.randf_range(20.0, 30.0)
		mensaje.emit("La sombra te atraviesa.")
		Sonido.reproducir("golpe_grave")
	else:
		morir()


func mantener(valor: bool) -> void:
	manteniendo = valor
	if not valor and advertencia_activa:
		ocultacion = 0.0


# --- Muerte ---------------------------------------------------------------------------------

func morir() -> void:
	if not EstadoJuego.jugando or EstadoJuego.invulnerable:
		return
	EstadoJuego.jugando = false
	EstadoJuego.muertes += 1
	eventos.clear()
	# Solo modo 1: si la primera muerte llega con el dígito de la cámara 3 pedido y sin resolver, la habitación guarda una pista.
	if EstadoJuego.modo == 1 and EstadoJuego.muertes == 1 and EstadoJuego.armado("pitidos"):
		EstadoJuego.ayuda_pitidos = true
	EstadoJuego.reiniciar_terminal()
	silueta_visible = false
	pitidos_restante = 0.0
	viento_manchas_restante = 0.0
	parpadeo_pendiente = false
	parpadeo_restante = 0.0
	advertencia_activa = false
	manteniendo = false
	Sonido.detener_todo()
	jugador_muerto.emit()
	if EstadoJuego.muertes >= 2:
		Transicion.ir_a_escena("res://escenas/game_over.tscn", 0.6)
	else:
		Transicion.ir_a_escena("res://escenas/muerte.tscn", 0.6)


## Tras despertar en la habitación secreta tras la primera muerte.
func reanudar_tras_morir() -> void:
	EstadoJuego.fijar_compatibilidad(EstadoJuego.cfg("compat_tras_morir"))
	_priorizar()
	proximo_aviso = rng.randf_range(20.0, 30.0)
	gracia = GRACIA_TRAS_ERROR
	proximo = -1.0
	bloqueo = 0.0
	sala_marcada = ""
	marca_restante = 0.0
	EstadoJuego.jugando = true
	if EstadoJuego.tramo > 0:
		Sonido.bucle("ambiente_tramo_%d" % EstadoJuego.tramo)
