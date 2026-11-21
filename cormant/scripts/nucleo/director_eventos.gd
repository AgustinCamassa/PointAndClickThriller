extends Node
## Director de eventos: genera anomalías (bolsa aleatoria), aplica penalizaciones
## y gestiona a la entidad (advertencia + ocultarse). Todos los valores son PROVISIONALES.

signal evento_iniciado(evento)
signal evento_terminado(evento, resultado: String)
signal terminal_bloqueado(segundos: float)
signal silueta_cambiada(visible: bool)
signal silueta_fase_cambiada(fase: int)   # la entidad de la ventana se acerca (1 cuerpo entero, 2 cintura, 3 hombros)
signal advertencia_iniciada
signal advertencia_terminada(sobrevivio: bool)
signal mensaje(texto: String)
signal jugador_muerto
signal pitidos_cambiados(activo: bool)
signal parpadeo_cambiado(activo: bool)
signal apagon_cambiado(activo: bool)

# --- Valores ajustables -------------------------------------------------------
const SEMILLA_FIJA := -1                 # >= 0 para depurar con orden fijo
const DURACION_EVENTO := 35.0
const PROBABILIDAD_FALSO := 0.4
const MINIMO_ENTRE_EVENTOS := 4.0
## Nunca pasan más de estos segundos sin que surja una anomalía (en la oficina, en modo 1, se alargaban demasiado).
const CAP_SIN_ANOMALIA := 15.0
const GRACIA_TRAS_ERROR := 10.0
const BLOQUEO_FALSA_ALARMA := 8.0
const PENALIZA_IGNORAR := 10.0
const PENALIZA_FALSA_ALARMA := 5.0
## Entidad de la ventana (anomalía «silueta»): 3 fases de acercamiento; cada una dura 1 s de movimiento + 0,25 s de pausa.
## Si el jugador no hace clic en la ventana antes de que acabe la fase 3: +40 % de compatibilidad, o la muerte si ya había muerto.
const ENTIDAD_REDUCCION := 0.08       # cada reaparición de la entidad acorta sus fases un 8 %...
const ENTIDAD_FACTOR_MIN := 0.65      # ...hasta un 65 % de la duración base del modo
const ENTIDAD_FASE_MIN := 0.4         # y nunca menos de 0,4 s por fase (1,2 s en total): por debajo sería injusto de esquivar
const ENTIDAD_PENALIZA := 40.0
const ENTIDAD_PENALIZA_PREVIA := 20.0   # mientras no se haya pedido su glifo: la mitad de daño
const ENTIDAD_LENTITUD_PREVIA := 2.0    # y sus fases duran el doble (la entidad, aún sin glifo, es más lenta)
const RONDAS_SILUETA_PREVIA := 2        # y solo sale una de cada 2 rondas
const ENTIDAD_PENALIZA_SALIR := 15.0     # apartar la vista (salir de Vigilancia) con la entidad acercándose
const PARPADEO_AMBIENTE_MIN := 25.0    # segundos entre parpadeos de ambiente (antes de abrir Vigilancia)
const PARPADEO_AMBIENTE_MAX := 45.0
const DURACION_PARPADEO_AMBIENTE := 3.0
const UMBRAL_APAGON_FRECUENTE := 80.0   # desde este nivel de compatibilidad, un apagón por ronda
const APAGON_RETRASO_MIN := 1.0      # tras la anomalía elegida de su ronda, el apagón llega entre 1 y 4 s después
const APAGON_RETRASO_MAX := 4.0
const APAGON_AVISO := 1.2            # parpadeo breve (sin daño) justo antes del apagón
const MUSICA_MODO3_DB := -17.0
const ENTIDAD_DETENIDA := 1.4            # parpadeos tras hacer clic en la ventana, antes de que desaparezca
const DURACION_PITIDOS := 30.0
const DURACION_PARPADEO := 3.5
const MINIMO_ENTRE_PARPADEOS := 45.0
const VISIBLE_GLIFO_RECEPCION := 30.0   # el glifo del mostrador también se desvanece
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
## Dan un glifo: cuadro (laboratorio), mancha (pasillo), silueta (recepción) y pitidos (cámara 3).
const TIPOS := ["cuadro", "mancha", "voz", "pitidos", "silueta", "parpadeo"]
const RECURRENTES := ["cuadro", "mancha"]   # si se ignoran siguen ahí, pero pueden volver para resolverse
const DESCRIPCION := {
	"cuadro": "Anomalía visual · CAM 1 (Laboratorio)",
	"mancha": "Anomalía visual · CAM 2 (Pasillo)",
	"voz": "Anomalía de audio · CAM 3 (sin señal)",
}
const FRAGMENTO_DE := {"cuadro": "retrato", "mancha": "mancha"}
## Anomalía que da cada glifo (el 5º tiene su propia anomalía, fuera de la bolsa).
const TIPO_DE_GLIFO := {"sombra": "silueta", "mancha": "mancha", "pitidos": "pitidos", "retrato": "cuadro"}

## Segundos que hay que mirar la cámara 3 mientras emite para ver el glifo entero en la estática.
const SEGUNDOS_ESTATICA := 7.0   # un ciclo completo de 9 pitidos dura ~6 s

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
var desde_ultimo := 0.0
var proximo := -1.0
var rondas_sin_silueta := 0       # rondas de anomalías desde la última silueta (mientras no se pida su glifo)
var silueta_visible := false
var entidad_apariciones := 0         # veces que ha aparecido la entidad en esta partida (cada una es más rápida)
var entidad_fase := 0                # 0 = no hay entidad; 1-3 = fases de acercamiento
var _silueta_restante := 0.0         # tiempo que queda de la fase actual
var entidad_parpadeo := 0.0          # >0: la entidad ha sido vista en detalle y desaparece entre parpadeos
var entidad_doble := false           # tras esquivarla saliendo de la sala, su próxima aparición es el doble de probable
var ventana_abierta := false         # el jugador está mirando por la ventana de Vigilancia (panel abierto)
var glifo_recepcion := false      # hay un glifo trazado en la recepción (aparece al esquivar la silueta)
var glifo_restante := 0.0         # segundos que le quedan visible tras esquivar la silueta
var pitidos_glifo_falso := ""     # constelación cuyos pitidos suenan si el terminal no había pedido ese glifo
var pitidos_escuchados := false
var viento_espera := 0.0
var viento_manchas_restante := 0.0
var bloqueo_lab := 0.0
var anomalias_desde_sombra := 0    # modo 3: anomalías surgidas desde la última sombra
var pitidos_restante := 0.0
var parpadeo_pendiente := false
var parpadeo_restante := 0.0
var apagon_restante := 0.0            # >0: apagón en curso
var rondas_apagon := 0                # rondas empezadas desde el último apagón (la actual incluida) mientras es elegible
var anomalias_ronda := 0              # anomalías ya sacadas de la bolsa en la ronda actual
var tam_ronda := 0                    # tamaño de la bolsa al empezar la ronda
var apagon_objetivo := 0              # nº de anomalía de la ronda tras la que llega el apagón (0 = no hay uno armado)
var apagon_aviso := 0.0               # >0: parpadeo de aviso previo al apagón
var _apagon_pendiente := false        # ya se sacó la anomalía elegida: falta el retraso aleatorio y el aviso
var _hasta_apagon := -1.0             # cuenta atrás de ese retraso
var parpadeo_ambiente := 0.0          # antes de abrir Vigilancia: parpadeo en cualquier sala, sin penalización
var _hasta_parpadeo_ambiente := 0.0
var desde_parpadeo := 999.0

var advertencia_activa := false
var aviso_restante := 0.0
var ocultacion := 0.0
var entidades_pausadas := false:     # DEV (tecla H): sin sorteo ni anomalías, entidades, avisos ni apagones hasta volver a pulsarla
	set(v):
		if v and not entidades_pausadas:
			_limpiar_anomalias_dev()
		entidades_pausadas = v
var manteniendo := false
var proximo_aviso := -1.0

var depuracion := false


func _ready() -> void:
	EstadoJuego.glifos_cambiado.connect(_priorizar)
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
	desde_ultimo = 0.0
	proximo = -1.0
	rondas_sin_silueta = 1
	silueta_visible = false
	entidad_apariciones = 0
	entidad_fase = 0
	_silueta_restante = 0.0
	entidad_parpadeo = 0.0
	entidad_doble = false
	ventana_abierta = false
	glifo_recepcion = false
	glifo_restante = 0.0
	pitidos_escuchados = false
	viento_espera = 0.0
	viento_manchas_restante = 0.0
	bloqueo_lab = 0.0
	anomalias_desde_sombra = 0
	pitidos_restante = 0.0
	parpadeo_pendiente = false
	parpadeo_restante = 0.0
	_reiniciar_apagon()
	parpadeo_ambiente = 0.0
	_hasta_parpadeo_ambiente = randf_range(PARPADEO_AMBIENTE_MIN, PARPADEO_AMBIENTE_MAX)
	desde_parpadeo = 999.0
	advertencia_activa = false
	ocultacion = 0.0
	manteniendo = false
	proximo_aviso = -1.0
	ultimo_tipo = ""
	bolsa = ["cuadro"]
	var resto := ["mancha", "voz", "pitidos", "parpadeo"]   # la silueta, en rodaje (modo 1 sin glifo pedido), sale una de cada 2 rondas
	if not EstadoJuego.silueta_en_rodaje():
		resto.append("silueta")
	_barajar(resto)
	bolsa.append_array(resto)
	_reiniciar_apagon()
	_iniciar_ronda_apagon()   # primera ronda (en el modo 3 ya cuenta: es elegible desde el inicio)
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


## Modo 3 invierte los fondos: el macabro es el de siempre y el normal aparece con la anomalía.
## En los modos 1 y 2, el fondo macabro llega con la anomalía. `invertido()` decide cuál de los dos casos aplica.
func invertido() -> bool:
	return EstadoJuego.modo == 3


## ¿Hay anomalía del cuadro (real, o fijada en pruebas)? Sin invertir: lo usa el texto de «Cuadro» al mirarlo.
func cuadro_con_anomalia() -> bool:
	if fijas.has("cuadro"):
		return true
	var e := evento_de("cuadro")
	return e != null and e.real


## En persona, el cuadro del laboratorio (y su fondo) es el macabro con la anomalía real (modos 1 y 2);
## en el modo 3 es el macabro siempre, salvo con la anomalía.
func cuadro_macabro() -> bool:
	return cuadro_con_anomalia() != invertido()


## La cámara 1 enseña el laboratorio macabro con cualquier señal del cuadro (real o falsa) en los modos 1 y 2.
## En el modo 3, lo contrario: macabro salvo con alguna señal.
func cuadro_en_camara() -> bool:
	var senal := fijas.has("cuadro") or evento_de("cuadro") != null
	return senal != invertido()


## ¿Se muestra el fondo macabro (`<fondo>_macabro`) de esta sala o vista?
## Modos 1 y 2, con la anomalía: laboratorio → cuadro real; recepción, reverso y ventana → silueta;
## Vigilancia → mientras dura el parpadeo; oficina y pasillo de la sala 5 → el 5.º glifo (viento).
## Modo 3: lo mismo invertido (macabro siempre, normal con la anomalía).
## El pasillo tiene su propia anomalía de fondo (`pasillo_mancha`) y no pasa por aquí.
func macabro(fondo: String) -> bool:
	var anomalia: bool
	match fondo:
		"laboratorio":
			anomalia = cuadro_con_anomalia()
		"recepcion", "recepcion_reverso", "ventana_recepcion":
			anomalia = silueta_visible
		"vigilancia":
			anomalia = parpadeo_restante > 0.0
		"oficina", "pasillo_secreto":
			anomalia = EstadoJuego.armado("viento")
		_:
			return false
	return anomalia != invertido()


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


func glifo_recepcion_visible() -> bool:
	## El glifo solo está trazado si el terminal ya lo había pedido; se ve hasta que se desvanece.
	return glifo_recepcion and glifo_restante > 0.0 and EstadoJuego.armado("sombra")


## Glifo que se dibuja en la estática de la cámara 3: el real solo si el terminal lo había pedido; si no, uno falso.
func pitidos_glifo() -> String:
	## Pedido el glifo, la CAM 3 suena siempre con el real (aunque luego se reinicie el terminal); si no, con un señuelo.
	var real: String = EstadoJuego.glifo_de("pitidos")
	if EstadoJuego.solicitado("pitidos"):
		return real
	if pitidos_glifo_falso == real or pitidos_glifo_falso == "":
		pitidos_glifo_falso = _glifo_falso(real)
	return pitidos_glifo_falso


## Número de pitidos de la CAM 3: el de estrellas de la constelación (4 a 9). No se dibuja nada en la pantalla.
func pitidos_cantidad() -> int:
	return Glifos.estrellas(pitidos_glifo())


func _glifo_falso(real: String) -> String:
	var falsos: Array = Glifos.PALETA.duplicate()
	falsos.erase(real)
	return falsos[rng.randi() % falsos.size()]


## El viento suena en la oficina de la sala 5 cuando se pide el último glifo y no hay manchas a la vista.
func viento_activo() -> bool:
	return EstadoJuego.armado("viento") and viento_manchas_restante <= 0.0 and viento_espera <= 0.0


func manchas_viento_visibles() -> bool:
	return viento_manchas_restante > 0.0


## El jugador mira por la ventana de la oficina mientras suena el viento.
func ver_manchas_viento() -> bool:
	if not viento_activo():
		return false
	viento_manchas_restante = EstadoJuego.VISIBLE_GLIFO
	return true


## Glifo equivocado en el terminal del laboratorio: bloqueo según el modo y todo lo confirmado vuelve a 0
## (lo desbloqueado sigue desbloqueado, pero hay que reintroducirlo).
func glifo_erroneo(indice := -1) -> void:
	var penaliza: float = EstadoJuego.cfg("penaliza_glifo")
	if penaliza > 0.0:
		EstadoJuego.sumar_compatibilidad(penaliza)
	bloqueo_lab = EstadoJuego.cfg("bloqueo_glifo")
	EstadoJuego.reiniciar_terminal()
	# Solo el puzzle de la CAM 3: si falla ahí, su constelación cambia y hay que volver a oír los pitidos.
	if indice == EstadoJuego.ORDEN_FRAGMENTOS.find("pitidos"):
		EstadoJuego.resortear_glifo("pitidos")
		pitidos_escuchados = false
		pitidos_glifo_falso = ""
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
	if EstadoJuego.modo == 3:
		Sonido.bucle("musica_modo3", MUSICA_MODO3_DB)   # banda sonora propia del modo 3, baja para no tapar las pistas
	if entidades_pausadas:
		return   # DEV (H): todo congelado: ni sorteo, ni anomalías, ni señales
	if not EstadoJuego.vigilancia_abierta:
		# Hasta abrir Vigilancia (PIN) no surgen anomalías (aún no hay forma de responderlas); solo el parpadeo, como ambiente.
		_actualizar_parpadeo_ambiente(delta)
		return
	parpadeo_ambiente = 0.0
	_actualizar_apagon(delta)
	desde_ultimo += delta
	desde_parpadeo += delta
	gracia = maxf(0.0, gracia - delta)
	_actualizar_bloqueo(delta)
	_actualizar_viento(delta)
	_actualizar_glifo_recepcion(delta)
	if not entidades_pausadas:
		_actualizar_silueta(delta)
	_actualizar_pitidos(delta)
	_actualizar_parpadeo(delta)
	_actualizar_eventos(delta)
	_actualizar_generacion(delta)
	if not entidades_pausadas:
		_actualizar_entidad(delta)
	if EstadoJuego.compatibilidad >= EstadoJuego.COMPATIBILIDAD_MAXIMA:
		morir()


## Única anomalía posible con la puerta de Vigilancia aún cerrada: parpadeos de luz en cualquier sala, sin sumar compatibilidad.
func _actualizar_parpadeo_ambiente(delta: float) -> void:
	if parpadeo_ambiente > 0.0:
		parpadeo_ambiente = maxf(0.0, parpadeo_ambiente - delta)
		return
	_hasta_parpadeo_ambiente -= delta
	if _hasta_parpadeo_ambiente <= 0.0:
		_hasta_parpadeo_ambiente = randf_range(PARPADEO_AMBIENTE_MIN, PARPADEO_AMBIENTE_MAX)
		parpadeo_ambiente = DURACION_PARPADEO_AMBIENTE
		Sonido.reproducir("estatica_breve", -10.0)


func apagon_activo() -> bool:
	return apagon_restante > 0.0


## Apagón: con 60 % de compatibilidad o más, o en la segunda vida, la luz se va (5 s; 2,5 s en el modo 3) cada 3 / 2 / 1 rondas de anomalías según el modo, y cada ronda con 80 % o más; llega en un momento aleatorio de su propia ronda, precedida de un breve parpadeo inofensivo. No lo hay en la
## habitación secreta ni mientras la entidad de la ventana está activa, y ella tampoco puede aparecer durante el apagón.
## Rondas de anomalías entre apagones: las del modo (3 / 2 / 1) y, con 80 % de compatibilidad o más, uno por ronda.
func rondas_para_apagon() -> int:
	if EstadoJuego.compatibilidad >= UMBRAL_APAGON_FRECUENTE:
		return 1
	return int(EstadoJuego.cfg("apagon_rondas"))


func _apagon_elegible() -> bool:
	return (EstadoJuego.compatibilidad >= UMBRAL_ADVERTENCIA or EstadoJuego.muertes >= 1) \
		and EstadoJuego.sala_actual != "habitacion_secreta"


## DEV (H): al pausar se retiran las anomalías en curso (señales del detector, entidad, sombra, pitidos, parpadeo, apagón y aviso).
func _limpiar_anomalias_dev() -> void:
	for e in eventos.duplicate():
		eventos.erase(e)
		evento_terminado.emit(e, "dev")
	_quitar_entidad()
	var habia_apagon := apagon_restante > 0.0
	apagon_restante = 0.0
	apagon_aviso = 0.0
	_apagon_pendiente = false
	_hasta_apagon = -1.0
	if habia_apagon:
		apagon_cambiado.emit(false)
	var habia_pitidos := pitidos_restante > 0.0
	pitidos_restante = 0.0
	if habia_pitidos:
		pitidos_cambiados.emit(false)
	viento_manchas_restante = 0.0
	var habia_parpadeo := parpadeo_restante > 0.0 or parpadeo_pendiente
	parpadeo_pendiente = false
	parpadeo_restante = 0.0
	parpadeo_ambiente = 0.0
	if habia_parpadeo:
		parpadeo_cambiado.emit(false)
	var habia_aviso := advertencia_activa
	advertencia_activa = false
	manteniendo = false
	if habia_aviso:
		advertencia_terminada.emit(false)
	Sonido.detener_bucle("entidad_acecho")


func _reiniciar_apagon() -> void:
	apagon_restante = 0.0
	apagon_aviso = 0.0
	_apagon_pendiente = false
	_hasta_apagon = -1.0
	apagon_objetivo = 0
	rondas_apagon = 0
	anomalias_ronda = 0
	tam_ronda = bolsa.size()


## Empieza una ronda de anomalías (la bolsa se acaba de llenar): cuenta para el apagón si ya es elegible.
func _iniciar_ronda_apagon() -> void:
	tam_ronda = bolsa.size()
	anomalias_ronda = 0
	apagon_objetivo = 0
	if _apagon_elegible():
		rondas_apagon += 1
		_armar_apagon()


## Si toca apagón en esta ronda, elige al azar tras qué anomalía de ESTA ronda llega (no la última, para que no se salga de ella).
func _armar_apagon() -> void:
	if apagon_objetivo > 0 or _apagon_pendiente or rondas_apagon < rondas_para_apagon():
		return
	var primera := anomalias_ronda + 1
	if primera > tam_ronda:
		return
	apagon_objetivo = rng.randi_range(primera, maxi(primera, tam_ronda - 1))


func _actualizar_apagon(delta: float) -> void:
	if apagon_restante > 0.0:
		apagon_restante -= delta
		if apagon_restante <= 0.0:
			apagon_restante = 0.0
			Sonido.reproducir("apagon_fin")
			apagon_cambiado.emit(false)
		return
	if apagon_aviso > 0.0:
		apagon_aviso -= delta
		if apagon_aviso <= 0.0:
			apagon_aviso = 0.0
			iniciar_apagon()
		return
	if not _apagon_elegible():
		_apagon_pendiente = false
		apagon_objetivo = 0
		rondas_apagon = 0
		return
	_armar_apagon()
	if not _apagon_pendiente:
		return
	_hasta_apagon = maxf(_hasta_apagon - delta, 0.0)   # 0 = listo, a la espera de que no haya entidad en la ventana
	if _hasta_apagon <= 0.0 and not silueta_visible:
		_apagon_pendiente = false
		apagon_aviso = APAGON_AVISO
		Sonido.reproducir("estatica_breve", -8.0)


## Una anomalía sale de la bolsa: si es la elegida para su ronda, el apagón queda en marcha.
func _anomalia_sacada() -> void:
	anomalias_ronda += 1
	if apagon_objetivo > 0 and anomalias_ronda >= apagon_objetivo:
		apagon_objetivo = 0
		rondas_apagon = 0
		_apagon_pendiente = true
		_hasta_apagon = rng.randf_range(APAGON_RETRASO_MIN, APAGON_RETRASO_MAX)


func iniciar_apagon() -> void:
	apagon_restante = float(EstadoJuego.cfg("apagon_duracion"))
	apagon_aviso = 0.0
	Sonido.reproducir("apagon_inicio")
	mensaje.emit("Se ha ido la luz.")
	apagon_cambiado.emit(true)


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


func _actualizar_glifo_recepcion(delta: float) -> void:
	# El glifo del mostrador queda ahí tras esquivar la silueta y se desvanece solo.
	if glifo_restante > 0.0:
		glifo_restante -= delta
		if glifo_restante <= 0.0:
			glifo_restante = 0.0
			glifo_recepcion = false


func _actualizar_silueta(delta: float) -> void:
	if not silueta_visible:
		return
	if entidad_parpadeo > 0.0:
		entidad_parpadeo -= delta
		if entidad_parpadeo <= 0.0:
			entidad_parpadeo = 0.0
			_quitar_entidad()
		return
	if ventana_abierta:
		return
	_silueta_restante -= delta
	if _silueta_restante > 0.0:
		return
	if entidad_fase < 3:
		entidad_fase += 1
		_silueta_restante = duracion_fase_entidad()
		silueta_fase_cambiada.emit(entidad_fase)
		return
	_castigo_entidad()


func _quitar_entidad() -> void:
	silueta_visible = false
	entidad_fase = 0
	entidad_parpadeo = 0.0
	Sonido.detener_bucle("entidad_acecho")
	silueta_cambiada.emit(false)


## El jugador hace clic en la ventana: la entidad se detiene, hay parpadeos y desaparece.
func detener_entidad() -> void:
	if not silueta_visible or entidad_parpadeo > 0.0:
		return
	entidad_parpadeo = ENTIDAD_DETENIDA
	Sonido.detener_bucle("entidad_acecho")
	Sonido.reproducir("estatica_breve")
	# Esquivarla bien deja el glifo en el mostrador de la recepción (solo si el terminal lo había pedido).
	if EstadoJuego.armado("sombra"):
		glifo_recepcion = true
		glifo_restante = VISIBLE_GLIFO_RECEPCION


func _castigo_entidad() -> void:
	_quitar_entidad()
	Sonido.reproducir("golpe_grave")
	if EstadoJuego.muertes > 0:
		morir()
	else:
		EstadoJuego.sumar_compatibilidad(ENTIDAD_PENALIZA_PREVIA if EstadoJuego.silueta_en_rodaje() else ENTIDAD_PENALIZA)
		mensaje.emit("La silueta cruzó el cristal. Algo me atravesó.")


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
	desde_ultimo = 0.0
	Sonido.detener_bucle("ambiente_tramo_%d" % (tramo - 1))
	if tramo > 0:
		Sonido.bucle("ambiente_tramo_%d" % tramo)


func _actualizar_generacion(delta: float) -> void:
	if EstadoJuego.tramo == 0 or advertencia_activa or gracia > 0.0:
		return
	if proximo < 0.0:
		proximo = _intervalo()
	proximo -= delta
	if desde_ultimo >= CAP_SIN_ANOMALIA:
		_forzar_anomalia()
		return
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


## Pasados CAP_SIN_ANOMALIA sin ninguna anomalía nueva: se crea una aunque no toque por el ritmo ni el máximo activo.
func _forzar_anomalia() -> void:
	var tipo := _elegir_tipo()
	if tipo == "":
		# Nada elegible con la bolsa actual (p. ej. solo queda un parpadeo ya pendiente): se rehace la bolsa.
		bolsa.clear()
		tipo = _elegir_tipo()
	# Nunca dos iguales seguidos (el parpadeo sí puede repetirse: a veces es lo único elegible).
	var intentos := 0
	while tipo == ultimo_tipo and tipo != "parpadeo" and tipo != "" and intentos < 6:
		tipo = _elegir_tipo()
		intentos += 1
	if tipo == "":
		tipo = "parpadeo"
	_crear(tipo)
	proximo = _intervalo()


func _intervalo() -> float:
	var t: Array = TRAMOS[EstadoJuego.tramo]
	return rng.randf_range(t[0], t[1])


# --- Creación de eventos -------------------------------------------------------------

## Al pedir un glifo, su anomalía gana prioridad dentro de la bolsa, pero nunca sale la primera:
## se coloca en segundo o tercer lugar (así sale una vez otra anomalía, y el azar sigue siendo justo).
func _priorizar() -> void:
	if not EstadoJuego.jugando or EstadoJuego.solicitados <= EstadoJuego.confirmados:
		return
	var id: String = EstadoJuego.ORDEN_FRAGMENTOS[EstadoJuego.confirmados]
	if not TIPO_DE_GLIFO.has(id):
		return
	var t: String = TIPO_DE_GLIFO[id]
	var i := bolsa.find(t)
	if i == -1 and t == "silueta" and not silueta_visible:
		bolsa.insert(mini(rng.randi_range(1, 2), bolsa.size()), t)   # pedido el glifo: la silueta entra en la ronda en curso
		return
	if i == -1 or bolsa.size() < 2 or (i >= 1 and i <= 2):
		return
	bolsa.remove_at(i)
	bolsa.insert(mini(rng.randi_range(1, 2), bolsa.size()), t)


func _rellenar_bolsa() -> void:
	bolsa = []
	var silueta_ronda := true
	if EstadoJuego.silueta_en_rodaje():
		rondas_sin_silueta += 1
		silueta_ronda = rondas_sin_silueta >= RONDAS_SILUETA_PREVIA
		if silueta_ronda:
			rondas_sin_silueta = 0
	for t in TIPOS:
		if t == "silueta" and not silueta_ronda:
			continue
		if not fijas.has(t) or RECURRENTES.has(t):
			bolsa.append(t)
	_barajar(bolsa)
	if bolsa.size() > 1 and bolsa[0] == ultimo_tipo:
		var tmp = bolsa[0]
		bolsa[0] = bolsa[1]
		bolsa[1] = tmp
	_priorizar()
	_iniciar_ronda_apagon()   # bolsa llena = empieza una ronda nueva


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
				if entidades_pausadas or silueta_visible or advertencia_activa or apagon_activo() or apagon_aviso > 0.0 or EstadoJuego.sala_actual != "vigilancia":
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
		_anomalia_sacada()
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
	pitidos_glifo_falso = _glifo_falso(EstadoJuego.glifo_de("pitidos"))   # siempre distinto del real
	if not EstadoJuego.tiene_detector:   # con el detector, el aviso lo da él (LEDs y pitido)
		Sonido.reproducir("alerta_terminal")
	mensaje.emit("La cámara 3 emite pitidos.")
	pitidos_cambiados.emit(true)


## La cámara 3 avisa de que el jugador ha visto el glifo en la estática.
func pitidos_oidos() -> void:
	if not pitidos_escuchados:
		pitidos_escuchados = true
		if EstadoJuego.armado("pitidos"):
			mensaje.emit("He contado los pitidos.")


## Segundos de cada fase de la entidad: la base del modo, acortada un 8 % por cada reaparición (mínimo 65 %).
## Sin haber pedido su glifo, la entidad es el doble de lenta (y no cuenta para acortarla después).
func duracion_fase_entidad() -> float:
	var factor := maxf(ENTIDAD_FACTOR_MIN, 1.0 - ENTIDAD_REDUCCION * maxi(entidad_apariciones - 1, 0))
	var lentitud := ENTIDAD_LENTITUD_PREVIA if EstadoJuego.silueta_en_rodaje() else 1.0
	return maxf(ENTIDAD_FASE_MIN, float(EstadoJuego.cfg("entidad_fase")) * factor * lentitud)


func _aparece_silueta() -> void:
	silueta_visible = true
	entidad_fase = 1
	if not EstadoJuego.silueta_en_rodaje():
		entidad_apariciones += 1   # solo las apariciones «en serio» la aceleran
	_silueta_restante = duracion_fase_entidad()
	entidad_parpadeo = 0.0
	entidad_doble = false
	_quitar_copias_silueta()
	glifo_recepcion = false
	Sonido.reproducir("estatica_breve")
	Sonido.bucle("entidad_acecho", -3.0)
	silueta_cambiada.emit(true)
	silueta_fase_cambiada.emit(1)
	if ventana_abierta:   # ya la está mirando de cerca: la ve en detalle desde el primer momento
		detener_entidad()


## Deja una sola «silueta» en la bolsa (tras la aparición con probabilidad doble).
func _quitar_copias_silueta() -> void:
	var primera := bolsa.find("silueta")
	for i in range(bolsa.size() - 1, -1, -1):
		if bolsa[i] == "silueta" and i != primera:
			bolsa.remove_at(i)


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
	if silueta_visible and id != "vigilancia":
		_esquivar_entidad_saliendo()
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
				c.pista = "Laboratorio comprobado: el cuadro ha cambiado." if c.real else "Laboratorio comprobado: el cuadro está igual."


# --- Entidad ------------------------------------------------------------------------------

## Salir de Vigilancia con la entidad acercándose la reinicia, cuesta +15 % y hace que su próxima aparición sea el doble de
## probable (una vez; si vuelve a esquivarla saliendo, otra vez).
func _esquivar_entidad_saliendo() -> void:
	_quitar_entidad()
	EstadoJuego.sumar_compatibilidad(ENTIDAD_PENALIZA_SALIR)
	entidad_doble = true
	if not EstadoJuego.silueta_en_rodaje():   # en el rodaje no insiste: sigue saliendo una de cada 2 rondas
		bolsa.insert(rng.randi_range(0, bolsa.size()), "silueta")
	mensaje.emit("Aparté la vista. La silueta ya no está en la ventana.")
	Sonido.reproducir("golpe_grave")


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
		if silueta_visible:
			proximo_aviso = 0.0   # no atacan a la vez: la sombra espera a que la entidad termine
		else:
			_iniciar_advertencia()


## Modo 3: cada 4 anomalías que surgen se oyen los pasos de la entidad, en cualquier sala (el jugador tiene 2 s para
## empezar a ocultarse y mantenerlo 1 s). Con SOMBRA_SOLO_VIGILANCIA solo cuenta y ataca estando en Vigilancia
## (fuera, el contador queda congelado).
func _actualizar_sombra_pasos() -> void:
	if SOMBRA_SOLO_VIGILANCIA and EstadoJuego.sala_actual != "vigilancia":
		return
	if anomalias_desde_sombra >= EstadoJuego.SOMBRA_CADA and not silueta_visible:   # si coincide con la entidad, espera
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
		mensaje.emit("La sombra me atraviesa.")
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
	EstadoJuego.reiniciar_terminal()
	var habia_apagon := apagon_restante > 0.0
	_reiniciar_apagon()
	if habia_apagon:
		apagon_cambiado.emit(false)
	silueta_visible = false
	glifo_recepcion = false
	glifo_restante = 0.0
	entidad_fase = 0
	entidad_parpadeo = 0.0
	ventana_abierta = false
	pitidos_restante = 0.0
	viento_manchas_restante = 0.0
	parpadeo_pendiente = false
	parpadeo_restante = 0.0
	var habia_aviso := advertencia_activa
	advertencia_activa = false
	manteniendo = false
	if habia_aviso:
		advertencia_terminada.emit(false)   # recoge el aviso, la barra, el botón y el oscurecimiento de ocultarse
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
	EstadoJuego.jugando = true
	if EstadoJuego.tramo > 0:
		Sonido.bucle("ambiente_tramo_%d" % EstadoJuego.tramo)
