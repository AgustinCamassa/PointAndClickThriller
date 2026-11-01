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
var _fondo_tr: TextureRect = null
var _cuadro_visual: Control = null
var _mitad_parpadeo: ColorRect = null
var _tiempo_mitad := 0.0
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
	EstadoJuego.fragmento_obtenido.connect(func(_id): _refrescar_anomalias())
	EstadoJuego.fragmento_oculto.connect(func(_id): _refrescar_anomalias())
	Interfaz.volver_pedido.connect(_volver_atras)
	Interfaz.cerrar_pedido.connect(_cerrar_panel)
	_mostrar_sala(EstadoJuego.sala_actual)


func _exit_tree() -> void:
	if Interfaz.volver_pedido.is_connected(_volver_atras):
		Interfaz.volver_pedido.disconnect(_volver_atras)
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
	_mitad_parpadeo = null
	var textura := Recursos.fondo(id)
	_construir_fondo(datos, textura)
	_construir_zonas(datos, textura != null)
	_construir_alicia(datos)
	if datos.get("parpadeo_mitad", false):
		_mitad_parpadeo = ColorRect.new()
		_mitad_parpadeo.color = Color(0, 0, 0, 0)
		_mitad_parpadeo.position = Vector2.ZERO
		_mitad_parpadeo.size = Vector2(640, 720)
		_mitad_parpadeo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_capa_efectos.add_child(_mitad_parpadeo)
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
	for h in datos["hotspots"]:
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
	var id_sala := sala_id
	await get_tree().create_timer(3.0).timeout
	if sala_id == id_sala and is_instance_valid(_fondo_tr):
		var sentada := Recursos.fondo("habitacion_secreta_sentada")
		if sentada != null:
			_fondo_tr.texture = sentada
			Sonido.reproducir("golpe_grave", -12.0)


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
	_cuadro_visual = null
	var datos := DatosSalas.obtener(sala_id)
	match sala_id:
		"laboratorio":
			_anomalia_cuadro(_rect_de(datos, "cuadro"))
		"pasillo":
			if Director.mancha_visible():
				_anomalia_mancha()
		"vigilancia":
			if Director.silueta_visible:
				_anomalia_silueta_ventana(_rect_de(datos, "ventana"))
		"recepcion":
			if Director.numero_recepcion_visible():
				_anomalia_numero(_rect_de(datos, "numero"))


func _anomalia_cuadro(rect: Rect2) -> void:
	var girado := Director.cuadro_girado()
	var textura := Recursos.sprite("cuadro_recto")
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
	nodo.pivot_offset = rect.size / 2.0
	nodo.rotation = PI if girado else 0.0
	_capa_anomalias.add_child(nodo)
	_cuadro_visual = nodo


func _anomalia_mancha() -> void:
	var d: Dictionary = ZonasFondos.MANCHA_PASILLO
	var ancho: float = d["ancho"]
	var textura := Recursos.sprite("mancha_suelo")
	var centro: Vector2 = d["centro"]
	var nodo: Control
	if textura != null:
		var tr := TextureRect.new()
		tr.texture = textura
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(ancho, ancho / 3.0)
		nodo = tr
	else:
		var cr := ColorRect.new()
		cr.color = Color(0.25, 0.05, 0.05)
		cr.size = Vector2(ancho, ancho / 3.0)
		nodo = cr
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nodo.position = centro - nodo.size / 2.0
	_capa_anomalias.add_child(nodo)


func _anomalia_silueta_ventana(rect: Rect2) -> void:
	## Una figura pequeña y oscura tras el cristal: lo bastante visible para invitar a mirar por la ventana.
	var figura := Alicia.new()
	var alto := 74.0
	var pies := Vector2(rect.get_center().x, rect.end.y - 14.0)
	figura.configurar("de_espaldas", pies, Vector2(alto * 0.29, alto), true)
	_capa_anomalias.add_child(figura)
	figura.aparecer(0.05)


func _anomalia_numero(rect: Rect2) -> void:
	var l := Label.new()
	l.text = str(EstadoJuego.digito_de("sombra"))
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 56)
	l.add_theme_color_override("font_color", Color(0.45, 0.07, 0.07))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.rotation = deg_to_rad(-5.0)
	l.pivot_offset = rect.size / 2.0
	_capa_anomalias.add_child(l)


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


var _numero_mostrado := false


func _process(delta: float) -> void:
	# 5º dígito disponible: en el laboratorio se oye un susurro fuerte en el auricular derecho (la puerta de la oficina).
	if sala_id == "laboratorio" and EstadoJuego.jugando and EstadoJuego.quinto_disponible():
		Sonido.bucle("susurro_derecha", -3.0, Sonido.BUS_DERECHA)
	else:
		Sonido.detener_bucle("susurro_derecha")
	if sala_id == "oficina" and Director.viento_activo():
		Sonido.bucle("viento", -8.0)
	else:
		Sonido.detener_bucle("viento")
	if sala_id == "recepcion" and Director.numero_recepcion_visible() != _numero_mostrado:
		_numero_mostrado = Director.numero_recepcion_visible()
		_refrescar_anomalias()
	if _mitad_parpadeo != null:
		_tiempo_mitad -= delta
		if _tiempo_mitad <= 0.0:
			_mitad_parpadeo.color.a = randf_range(0.3, 0.8) if randf() < 0.45 else 0.0
			_tiempo_mitad = randf_range(0.05, 0.4)


# --- Interacción ----------------------------------------------------------------------------------------

func _al_pulsar(h: Dictionary) -> void:
	if Transicion.ocupada or _panel_abierto != null or not EstadoJuego.jugando:
		return
	match h["accion"]:
		"ir":
			_viajar(h["valor"])
		"texto":
			Interfaz.mensaje(h["valor"], 4.5)
		"panel":
			_abrir_panel(h["valor"])
		"funcion":
			_funcion(h["valor"])


func _viajar(destino: String) -> void:
	var rapida := destino == "recepcion_reverso" or sala_id == "recepcion_reverso"
	if not rapida:
		Sonido.reproducir("puerta")
	await Transicion.cambiar(func(): _mostrar_sala(destino), DURACION_RAPIDA if rapida else DURACION_VIAJE)


func _funcion(nombre: String) -> void:
	match nombre:
		"cuadro":
			if Director.cuadro_girado():
				Interfaz.mensaje("El cuadro está del revés. No hay nada que lo sujete.", 4.5)
			else:
				Interfaz.mensaje("Un cuadro. Está recto.", 3.0)
		"numero_recepcion":
			if Director.numero_recepcion_visible():
				_abrir(PanelTexto.crear("Frente del mostrador", Textos.fragmento("sombra", EstadoJuego.digito_de("sombra"))))
				Sonido.reproducir("papel")
			elif Director.marca_restante > 0.0 and Director.numero_recepcion:
				Interfaz.mensaje("Algo se mueve detrás del mostrador. Mejor esperar.", 3.5)
			else:
				Interfaz.mensaje("El frente del mostrador está limpio.", 3.0)
		"mesita":
			if EstadoJuego.ayuda_pitidos:
				_abrir(PanelTexto.crear("Estantería", Textos.MESITA + "\n\n" + Textos.NOTA_EX_TRABAJADOR))
				Sonido.reproducir("papel")
			else:
				Interfaz.mensaje(Textos.MESITA, 4.5)
		"puerta_azul":
			Interfaz.mensaje("No se abre desde este lado. No tiene picaporte.", 4.0)


func _abrir_panel(nombre: String) -> void:
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
			_abrir(PanelTexto.crear("Cuaderno de mantenimiento", Textos.cuaderno(int(Director.duracion_evento()), EstadoJuego.cfg("sombra"))))
		"ventana":
			_abrir(PanelVentana.crear("recepcion"))
		"ventana_secreta":
			_abrir(PanelVentana.crear("secreta"))
		"ficha_14b":
			_abrir(PanelTexto.crear("Ficha clínica", Textos.FICHA_14B))
			Sonido.reproducir("papel")
		"terminal_lab":
			var p := PanelTerminalLab.crear()
			p.codigo_aceptado.connect(_abrir_documento_final)
			_abrir(p)


func _abrir(panel: PanelBase) -> void:
	_panel_abierto = panel
	panel.cerrado.connect(func():
		_panel_abierto = null
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


func _abrir_documento_final() -> void:
	_panel_abierto = null
	EstadoJuego.superar_modo()
	EstadoJuego.jugando = false
	EstadoJuego.finalizada = true
	Sonido.detener_todo()
	Transicion.ir_a_escena("res://escenas/final.tscn", 0.8)
