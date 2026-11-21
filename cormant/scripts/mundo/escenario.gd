extends Control
## Escenario: una sala de fondo fijo con zonas clicables. Cambiar de sala = fundido + reconstrucción.

const DURACION_VIAJE := 0.8         # cada fundido (entrada + salida ≈ 1,6 s): dura lo que cuesta ir en persona
const DURACION_RAPIDA := 0.15

var sala_id := ""
var _capa_fondo: Control
var _capa_anomalias: Control
var _capa_alicia: Control
var _capa_zonas: Control
var _capa_efectos: Control
var _capa_modales: Control
var _panel_abierto: PanelBase = null
var _alicia: Alicia = null
var _figura_entidad: Alicia = null   # entidad vista por la ventana de Vigilancia
var _fondo_tr: TextureRect = null
var _cuadro_visual: Control = null
var _musica_actual := ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_fondo = _nueva_capa()
	_capa_anomalias = _nueva_capa()
	_capa_alicia = _nueva_capa()
	_capa_zonas = _nueva_capa()
	_capa_efectos = _nueva_capa()
	_capa_modales = _nueva_capa()
	_capa_modales.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Interfaz.activar(true)
	Director.evento_iniciado.connect(func(_e): _refrescar_anomalias())
	Director.evento_terminado.connect(func(_e, _r): _refrescar_anomalias())
	Director.silueta_cambiada.connect(func(_v): _refrescar_anomalias())
	Director.parpadeo_cambiado.connect(func(_a): _refrescar_anomalias())   # Vigilancia pasa a su fondo macabro mientras parpadea
	EstadoJuego.glifos_cambiado.connect(_refrescar_anomalias)              # oficina: macabra al pedir el 5.º glifo (viento)
	Director.silueta_fase_cambiada.connect(_al_cambiar_fase_entidad)
	Director.apagon_cambiado.connect(_al_cambiar_apagon)
	EstadoJuego.fragmento_obtenido.connect(func(_id): _refrescar_anomalias())
	EstadoJuego.fragmento_oculto.connect(func(_id): _refrescar_anomalias())
	Interfaz.volver_pedido.connect(_volver_atras)
	Interfaz.cerrar_pedido.connect(_cerrar_panel)
	Interfaz.dev_fin_pedido.connect(_dev_fin)
	_mostrar_sala(EstadoJuego.sala_actual)


func _exit_tree() -> void:
	if Interfaz.volver_pedido.is_connected(_volver_atras):
		Interfaz.volver_pedido.disconnect(_volver_atras)
	if Interfaz.dev_fin_pedido.is_connected(_dev_fin):
		Interfaz.dev_fin_pedido.disconnect(_dev_fin)
	if Interfaz.cerrar_pedido.is_connected(_cerrar_panel):
		Interfaz.cerrar_pedido.disconnect(_cerrar_panel)
	Interfaz.set_panel_abierto(false)


func _nueva_capa() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _vaciar(capa: Control) -> void:
	for h in capa.get_children():
		h.queue_free()


# --- Construcción de la sala -----------------------------------------------------------------

func _mostrar_sala(id: String) -> void:
	sala_id = id
	EstadoJuego.sala_actual = id
	var datos := DatosSalas.obtener(id)
	_vaciar(_capa_fondo)
	_vaciar(_capa_anomalias)
	_vaciar(_capa_alicia)
	_vaciar(_capa_zonas)
	_vaciar(_capa_efectos)
	_alicia = null
	_fondo_tr = null
	_cuadro_visual = null
	var textura := _textura_sala(id)
	_construir_fondo(datos, textura)
	_oscurecer_capas(Director.apagon_activo())
	_construir_zonas(datos, textura != null)
	_construir_alicia(datos)
	_refrescar_anomalias()
	_actualizar_musica(datos)
	Interfaz.sala_cambiada()
	Director.entrar_sala(id)
	if id == "habitacion_secreta" and EstadoJuego.muertes > 0:
		_despertar()


func _construir_fondo(datos: Dictionary, textura: Texture2D) -> void:
	if textura != null:
		var tr := TextureRect.new()
		tr.texture = textura
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_capa_fondo.add_child(tr)
		_fondo_tr = tr
		return
	var color := ColorRect.new()
	color.color = datos["color"]
	color.set_anchors_preset(Control.PRESET_FULL_RECT)
	color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_fondo.add_child(color)
	var etiqueta := Label.new()
	etiqueta.text = "[%s · fondo provisional]" % datos["nombre"]
	etiqueta.position = Vector2(0, 340)
	etiqueta.size = Vector2(1280, 40)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 30)
	etiqueta.modulate = Color(1, 1, 1, 0.18)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_fondo.add_child(etiqueta)


func _construir_zonas(datos: Dictionary, con_fondo_real: bool) -> void:
	var con_mancha := EstadoJuego.sala_actual == "pasillo" and Director.macabro("pasillo")
	for h in datos["hotspots"]:
		if con_mancha and not ZonasFondos.poligono("pasillo_macabro", h["id"]).is_empty():
			# Con el fondo manchado las puertas están en otro sitio.
			h = h.duplicate()
			h["poly"] = ZonasFondos.poligono("pasillo_macabro", h["id"])
			h["rect"] = ZonasFondos.rect("pasillo_macabro", h["id"])
		if h["rect"].size == Vector2.ZERO:
			continue
		var b := ZonaPoligono.new()
		b.position = h["rect"].position
		b.size = h["rect"].size
		var local := PackedVector2Array()
		for v in h["poly"]:
			local.append(v - h["rect"].position)
		b.poligono = local
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = h["etiqueta"]
		if con_fondo_real:
			# Con fondo real las zonas son invisibles; solo se insinúan un poco al pasar el ratón.
			var vacio := StyleBoxEmpty.new()
			for estado in ["normal", "pressed", "focus", "disabled", "hover"]:
				b.add_theme_stylebox_override(estado, vacio)
			b.insinuar = true
		else:
			b.text = h["etiqueta"]
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.add_theme_font_size_override("font_size", 15)
			for estado in ["normal", "hover", "pressed"]:
				var caja := StyleBoxFlat.new()
				var c: Color = h["color"]
				caja.bg_color = c if estado == "normal" else c.lightened(0.3)
				caja.border_color = Color(1, 1, 1, 0.5)
				caja.set_border_width_all(2)
				b.add_theme_stylebox_override(estado, caja)
		b.pressed.connect(_al_pulsar.bind(h))
		_capa_zonas.add_child(b)


func _construir_alicia(datos: Dictionary) -> void:
	if not datos.has("alicia"):
		return
	var d: Dictionary = datos["alicia"]
	_alicia = Alicia.new()
	_alicia.configurar(d["pose"], d["pos"], Vector2.ZERO, false, d.get("escala", 1.0))
	_capa_alicia.add_child(_alicia)
	_alicia.aparecer(0.2)


func _despertar() -> void:
	# Tras la primera muerte: Alicia yace bajo la sábana y, a los 3 s, se incorpora (fondo "sentada").
	# El cambio de postura se esconde tras un parpadeo negro (cierra y abre los ojos).
	var id_sala := sala_id
	await get_tree().create_timer(3.0).timeout
	if sala_id != id_sala or not is_instance_valid(_fondo_tr):
		return
	var sentada := Recursos.fondo("habitacion_secreta_sentada")
	if sentada == null:
		return
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.size = Vector2(1280, 720)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	negro.modulate.a = 0.0
	_capa_efectos.add_child(negro)
	var t := create_tween()
	t.tween_property(negro, "modulate:a", 1.0, 0.09)
	t.tween_callback(func():
		if is_instance_valid(_fondo_tr) and sala_id == id_sala:
			_fondo_tr.texture = sentada
			Sonido.reproducir("golpe_grave", -12.0))
	t.tween_interval(0.16)
	t.tween_property(negro, "modulate:a", 0.0, 0.2)
	t.tween_callback(negro.queue_free)


# --- Anomalías visibles en la sala ------------------------------------------------------------------

func _rect_de(datos: Dictionary, id: String) -> Rect2:
	for h in datos["hotspots"]:
		if h["id"] == id:
			return h["rect"]
	return Rect2()


func _refrescar_anomalias() -> void:
	if not is_instance_valid(_capa_anomalias):
		return
	_vaciar(_capa_anomalias)
	_figura_entidad = null
	_cuadro_visual = null
	# Las anomalías cambian el fondo entero de la sala (versión macabra, o la sangre del pasillo): se cambia la textura.
	_actualizar_fondo()
	var datos := DatosSalas.obtener(sala_id)
	match sala_id:
		"laboratorio":
			_anomalia_cuadro(_rect_de(datos, "cuadro"))
		"vigilancia":
			if Director.silueta_visible:
				_anomalia_silueta_ventana(_rect_de(datos, "ventana"))
		"recepcion":
			if Director.glifo_recepcion_visible():
				_anomalia_glifo(_rect_de(datos, "pc2"))


func _anomalia_cuadro(rect: Rect2) -> void:
	## El cuadro normal está siempre en el laboratorio; con la anomalía real se ve el macabro (y el fondo del laboratorio también lo es). En el modo 3 se invierte.
	var textura := Recursos.sprite("cuadro_macabro" if Director.cuadro_macabro() else "cuadro")
	var nodo: Control
	if textura != null:
		var tr := TextureRect.new()
		tr.texture = textura
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		nodo = tr
	else:
		var cr := ColorRect.new()
		cr.color = Color(0.5, 0.45, 0.35)
		nodo = cr
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nodo.size = rect.size
	nodo.position = rect.position
	_capa_anomalias.add_child(nodo)
	_cuadro_visual = nodo


func _actualizar_fondo() -> void:
	## Cambia el fondo de la sala según haya o no una anomalía que lo altere (sin recargar la sala).
	if not is_instance_valid(_fondo_tr) or sala_id == "habitacion_secreta":
		return
	var tex := _textura_sala(sala_id)
	if tex != null and _fondo_tr.texture != tex:
		_fondo_tr.texture = tex
		if sala_id == "pasillo":
			_vaciar(_capa_zonas)   # las puertas cambian de sitio con el fondo manchado
			_construir_zonas(DatosSalas.obtener("pasillo"), true)
		_destello_cambio()


func _destello_cambio() -> void:
	## Un parpadeo muy breve de la luz al cambiar el fondo con el jugador delante: así el cambio no se ve como un salto de imagen.
	var id_sala := sala_id
	for v in [0.25, 1.0, 0.5, 1.0]:
		if sala_id != id_sala or not is_instance_valid(_fondo_tr):
			return
		_fondo_tr.modulate = Color(v, v, v, 1.0)
		await get_tree().create_timer(0.07).timeout
	if is_instance_valid(_fondo_tr) and sala_id == id_sala:
		_fondo_tr.modulate = Color.WHITE


func _anomalia_silueta_ventana(_rect: Rect2) -> void:
	## La entidad tras el cristal, en la fase en la que va: cuerpo entero lejos, de la cintura y de los hombros hacia arriba.
	## Se recorta al cristal para que, al acercarse, el cuerpo «salga» por debajo del marco.
	var d: Dictionary = ZonasFondos.ENTIDAD_FONDO
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = d["clip"].position
	clip.size = d["clip"].size
	_capa_anomalias.add_child(clip)
	var velo := Alicia.crear_velo(clip.size)
	clip.add_child(velo)
	velo.modulate.a = 0.0
	create_tween().tween_property(velo, "modulate:a", 1.0, 0.4)
	_figura_entidad = Alicia.new()
	var g := _geometria_entidad(maxi(Director.entidad_fase, 1))
	_figura_entidad.configurar("silueta", g["pies"] - clip.position, g["tam"], true)
	clip.add_child(_figura_entidad)
	_figura_entidad.aparecer(0.05)


func _geometria_entidad(fase: int) -> Dictionary:
	var d: Dictionary = ZonasFondos.ENTIDAD_FONDO
	var f: Vector2 = d["fases"][clampi(fase, 1, 3) - 1]
	return {"pies": Vector2(d["x"], f.y), "tam": Vector2(f.x * Alicia.ASPECTO_ENTIDAD, f.x)}


func _textura_sala(id: String) -> Texture2D:
	## Con una anomalía, el fondo macabro de la sala (si lo hay; en el modo 3, al revés: macabro siempre salvo con la anomalía); con el apagón, la versión oscurecida del que toque
	## (luces apagadas, pantallas negras); si no existe, la normal.
	var base := id
	if Director.macabro(id) and Recursos.fondo(id + "_macabro") != null:
		base = id + "_macabro"
	if Director.apagon_activo():
		var oscura := Recursos.fondo(base + "_apagon")
		if oscura != null:
			return oscura
	return Recursos.fondo(base)


func _oscurecer_capas(activo: bool) -> void:
	## Lo que se dibuja sobre el fondo (Alicia, glifos, siluetas) también se apaga.
	var tono := Color(0.4, 0.42, 0.48) if activo else Color.WHITE
	_capa_anomalias.modulate = tono
	_capa_alicia.modulate = tono


func _al_cambiar_apagon(activo: bool) -> void:
	## Apagón: se cambia el fondo por su versión oscura y se paran los ordenadores (se cierra el panel si es uno de ellos).
	## El jugador puede moverse con normalidad y las anomalías siguen su curso.
	if is_instance_valid(_fondo_tr) and sala_id != "habitacion_secreta":
		var tex := _textura_sala(sala_id)
		if tex != null:
			_fondo_tr.texture = tex
	_oscurecer_capas(activo)
	if activo and _panel_abierto != null and is_instance_valid(_panel_abierto) and _panel_abierto.es_ordenador:
		_cerrar_panel()


## Los ordenadores no funcionan durante el apagón.
func _sin_corriente() -> bool:
	if not Director.apagon_activo():
		return false
	Sonido.reproducir("error_terminal", -8.0)
	Interfaz.mensaje("Sin corriente. El equipo no responde.", 3.5)
	return true


func _al_cambiar_fase_entidad(fase: int) -> void:
	if sala_id != "vigilancia" or not is_instance_valid(_figura_entidad):
		return
	if fase <= 1:
		return
	var g := _geometria_entidad(fase)
	var clip: Control = _figura_entidad.get_parent()
	_figura_entidad.mover_a(g["pies"] - clip.position, g["tam"], Director.duracion_fase_entidad() * 0.8)


func _anomalia_glifo(rect: Rect2) -> void:
	## El glifo de la silueta solo se ve en la pantalla del ordenador 2 (el de la derecha del mostrador),
	## mientras dura la ventana tras esquivar la entidad. La pantalla parpadea como si se fuera a apagar.
	var pantalla := ColorRect.new()
	pantalla.color = Color(0.02, 0.03, 0.03, 0.92)
	pantalla.position = rect.position
	pantalla.size = rect.size
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_anomalias.add_child(pantalla)
	var v := VistaGlifo.crear(EstadoJuego.glifo_de("sombra"), rect.size)
	v.position = rect.position
	v.color = Color(0.85, 0.2, 0.2, 0.95)
	v.radio = 2.5
	v.grosor = 1.8
	v.margen = 0.12
	v.pivot_offset = rect.size / 2.0
	_capa_anomalias.add_child(v)
	# Parpadeos: apagones cortos y aleatorios de la imagen (también la pantalla queda en negro).
	var tw := v.create_tween().set_loops()
	tw.tween_property(v, "modulate:a", 0.1, 0.05)
	tw.tween_property(v, "modulate:a", 1.0, 0.07)
	tw.tween_interval(randf_range(0.6, 2.2))
	tw.tween_property(v, "modulate:a", 0.0, 0.09)
	tw.tween_property(v, "modulate:a", 1.0, 0.12)
	tw.tween_interval(randf_range(0.3, 1.4))


func _actualizar_musica(datos: Dictionary) -> void:
	var nueva: String = datos.get("musica", "")
	if nueva != _musica_actual:
		if _musica_actual != "":
			Sonido.detener_bucle(_musica_actual)
		_musica_actual = nueva
		if nueva != "":
			Sonido.bucle(nueva)
	if sala_id == "oficina" and Director.fijas.has("voz"):
		Sonido.bucle("susurro_fijo", -14.0)
	else:
		Sonido.detener_bucle("susurro_fijo")


var _glifo_mostrado := false


func _process(delta: float) -> void:
	# 5º glifo disponible: en el laboratorio se oye un susurro fuerte en el auricular derecho (la puerta de la oficina).
	if sala_id == "laboratorio" and EstadoJuego.jugando and EstadoJuego.quinto_disponible():
		Sonido.bucle("susurro_derecha", -3.0, Sonido.BUS_DERECHA)
	else:
		Sonido.detener_bucle("susurro_derecha")
	if sala_id == "oficina" and Director.viento_activo():
		Sonido.bucle("viento", -8.0)
	else:
		Sonido.detener_bucle("viento")
	if sala_id == "recepcion" and Director.glifo_recepcion_visible() != _glifo_mostrado:
		_glifo_mostrado = Director.glifo_recepcion_visible()
		_refrescar_anomalias()


# --- Interacción ----------------------------------------------------------------------------------------

func _al_pulsar(h: Dictionary) -> void:
	if Transicion.ocupada or _panel_abierto != null or not EstadoJuego.jugando:
		return
	match h["accion"]:
		"ir":
			if h["valor"] == "vigilancia" and not EstadoJuego.vigilancia_abierta:
				_abrir_pin()
				return
			if h["valor"] == "laboratorio" and not EstadoJuego.tiene_tarjeta:
				Sonido.reproducir("error_terminal", -8.0)
				Interfaz.mensaje(Textos.LAB_CERRADO, 4.5)
				return
			_viajar(h["valor"])
		"texto":
			Interfaz.mensaje(h["valor"], 4.5)
		"panel":
			_abrir_panel(h["valor"])
		"funcion":
			_funcion(h["valor"])


func _abrir_pin() -> void:
	if _sin_corriente():
		return
	## Puerta de Vigilancia cerrada: teclado de 4 dígitos. El PIN está en el correo del ordenador de la recepción.
	var p := PanelPin.crear()
	p.pin_aceptado.connect(func(): _viajar("vigilancia"))
	_abrir(p)


func _viajar(destino: String) -> void:
	var rapida := destino == "recepcion_reverso" or sala_id == "recepcion_reverso"
	if not rapida:
		Sonido.reproducir("puerta")
	await Transicion.cambiar(func(): _mostrar_sala(destino), DURACION_RAPIDA if rapida else DURACION_VIAJE)


func _funcion(nombre: String) -> void:
	match nombre:
		"cuadro":
			var macabro := Director.cuadro_macabro()
			if Director.cuadro_con_anomalia():
				Interfaz.mensaje("El cuadro ha cambiado. Ya no posan: cinco están caídos y una sigue de pie.", 4.5)
			else:
				Interfaz.mensaje("Un cuadro: seis personas posando en un laboratorio antiguo.", 3.5)
			_abrir(PanelCuadro.crear(macabro))
		"pc_senal":
			# Sin el glifo pedido y esquivado, el ordenador no tiene señal; con él, muestra la figura.
			if Director.glifo_recepcion_visible():
				_abrir(PanelGlifo.crear("Ordenador 2", Textos.FRAGMENTOS["sombra"], EstadoJuego.glifo_de("sombra")))
				Sonido.reproducir("papel")
			else:
				Interfaz.mensaje("SIN SEÑAL", 3.0)
		"mesita":
			Interfaz.mensaje(Textos.MESITA, 4.5)
		"pc_correo":
			if _sin_corriente():
				return
			Sonido.reproducir("papel", -6.0)
			_abrir(PanelCorreo.crear())
		"archivero":
			if EstadoJuego.tiene_tarjeta:
				Interfaz.mensaje(Textos.ARCHIVERO_VACIO, 4.0)
			else:
				# El evento del archivero: la tarjeta se guarda sin inventario y el laboratorio queda desbloqueado.
				EstadoJuego.obtener_tarjeta()
				Sonido.reproducir("papel")
				_abrir(PanelTexto.crear("Archivero", Textos.TARJETA))
		"puerta_azul":
			Interfaz.mensaje("No se abre desde este lado. No tiene picaporte.", 4.0)


func _abrir_panel(nombre: String) -> void:
	if (nombre == "camaras" or nombre == "terminal_lab") and _sin_corriente():
		return
	match nombre:
		"camaras":
			if not EstadoJuego.tiene_detector:
				# Primer clic en las cámaras: el jugador encuentra el detector y, al cerrar el texto, se abre el terminal.
				EstadoJuego.obtener_detector()
				Sonido.reproducir("papel")
				var aviso := PanelTexto.crear(Textos.DETECTOR_TITULO, Textos.DETECTOR)
				_abrir(aviso)
				aviso.cerrado.connect(func():
					if sala_id == "vigilancia" and _panel_abierto == null:
						_abrir_panel("camaras"))
			else:
				_abrir(PanelCamaras.crear())
		"cuaderno":
			_abrir(PanelTexto.crear("Notas de turno", Textos.cuaderno(int(Director.duracion_evento()), EstadoJuego.cfg("sombra"))))
		"ventana":
			Director.detener_entidad()   # mirar la silueta de cerca la detiene: parpadeos y desaparece
			_abrir(PanelVentana.crear("recepcion"))
		"ventana_secreta":
			_abrir(PanelVentana.crear("secreta"))
		"ficha_14b":
			_abrir(PanelTexto.crear("Ficha clínica", Textos.FICHA_14B))
			Sonido.reproducir("papel")
		"terminal_lab":
			var p := PanelTerminalLab.crear()
			p.secuencia_aceptada.connect(_abrir_documento_final)
			_abrir(p)


func _abrir(panel: PanelBase) -> void:
	_panel_abierto = panel
	if panel.es_ordenador:
		Director.ordenador_abierto = true   # la entidad de la ventana no avanza mientras se mira un ordenador
	panel.cerrado.connect(func():
		_panel_abierto = null
		Director.ordenador_abierto = false
		Interfaz.set_panel_abierto(false))
	_capa_modales.add_child(panel)
	Interfaz.set_panel_abierto(true)


## Botón «Cerrar» de la barra inferior.
func _cerrar_panel() -> void:
	if _panel_abierto != null and is_instance_valid(_panel_abierto):
		_panel_abierto.cerrar()


## Botón «Volver» de la barra inferior: sala anterior según DatosSalas.VOLVER_A.
func _volver_atras() -> void:
	if Transicion.ocupada or _panel_abierto != null or not EstadoJuego.jugando:
		return
	var destino := DatosSalas.volver_a(sala_id)
	if destino != "":
		_viajar(destino)
	elif DatosSalas.volver_bloqueado(sala_id):
		# Solo se avanza: la puerta por la que se entró ya no se puede abrir.
		Interfaz.mensaje("La puerta de la habitación se ha bloqueado.", 3.5)


## DEV (K): tras el 5.º glifo, salta directo al documento final (como tras «acceso concedido»).
func _dev_fin() -> void:
	if Transicion.ocupada or not EstadoJuego.jugando:
		return
	_abrir_documento_final()


func _abrir_documento_final() -> void:
	_panel_abierto = null
	EstadoJuego.superar_modo()
	EstadoJuego.jugando = false
	EstadoJuego.finalizada = true
	Sonido.detener_todo()
	Transicion.ir_a_escena("res://escenas/final.tscn", 0.8)
