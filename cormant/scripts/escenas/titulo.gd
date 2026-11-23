extends Control

const Constelacion := preload("res://scripts/escenas/constelacion.gd")
## Pantalla de título con menús que se sustituyen unos a otros (cada pulsación destruye el menú anterior y construye el nuevo):
##  - Principal: Nueva partida (con «+» desde que se desbloquea el modo 2), Opciones, Salir.
##  - Nueva partida: con solo el modo 1 empieza directamente. Con el modo 2 desbloqueado abre un menú con Nueva partida (modo 1) y Nueva partida + (modo 2);
##    con el modo 3 desbloqueado se añade otra Nueva partida + (modo 3), escrita en rojo con la letra de dedo. Todos con Volver.
##  - Opciones: Borrar datos y Volver. Borrar datos abre un tercer menú emergente que pregunta si se está seguro.
##  - Al superar el modo 2 (modo 3 desbloqueado) el menú cambia de color (rojo oscuro).
##  - El cartel del edificio solo está borroso en los modos 1 y 2; con el modo 3 desbloqueado se ve nítido.
##  - Con las cinco estrellas unidas por la línea, un fundido oscurece el cielo, lo vuelve algo rojo y lo hace parpadear.
##  - Fondo: con el modo 3 desbloqueado el edificio alterna (interferencia) entre normal y macabro; al superar el modo 3 queda el macabro
##    con la farola apagada. Al volver justo después: normal → estrellas → línea → parpadeo → macabro → la farola se apaga.
## No hay texto de título: el título es el cartel del edificio (CORMANT · Medical Systems), borroso hasta superar los tres modos.

const MENU_POS := Vector2(56, 330)
const ANCHO_BOTON := 360.0
const ALTO_BOTON := 50.0
const SEPARACION := 12.0
const TEXTO_ROJO := "res://assets/sprites/menu_nueva_partida_mas.png"   # «Nueva partida +» en rojo, letra de dedo (sangre_mensajes.py)
const VELO_ALFA := 0.36                  # oscuridad del fundido rojo final (más suave que antes: 0,62)
const TEXTO_ESTRELLA := "texto de historia aquí"   # provisional: lo que se lee al pulsar una estrella con la constelación completa
const TIEMPO_TEXTO := 4.0                # lo que se ve el texto sobre el blanco antes de fundirse con la vista normal
const CARTEL_POS := Vector2(550, 316)    # dónde van los recortes de titulo_cartel_N.png sobre el fondo (ver fondo_titulo.py)
const CARTEL_POS_MACABRO := Vector2(542, 284)   # ídem para titulo_macabro_cartel_N.png (ver fondo_titulo_macabro.py)


var _cortina: ColorRect
var _caja: VBoxContainer
var _popup: Control
var _tema_rojo := false
var _velo: ColorRect
var _velo_base := 0.0
var _proximo_parpadeo := 3.0
var _capa_normal: Control      # edificio normal (+ su cartel)
var _capa_macabra: Control     # edificio macabro con la farola encendida (+ cartel)
var _capa_apagada: Control     # edificio macabro con la farola apagada (+ cartel); es el fondo definitivo tras superar el modo 3
var _proximo_cambio := 5.0
var _glitch := false
var _vineta: TextureRect       # viñeta oscura en las esquinas (visión de ojo) que acompaña al velo rojo
var _superado := false         # modo 3 ya superado: el edificio macabro queda fijo
var _flash_activo := false
var _proximo_titileo := 1.0    # farola que titila mientras se ve el edificio macabro
var _cielo                     # constelación (estrellas y línea); el fundido final también las atenúa
const ATENUACION_ESTRELLAS := 0.55   # brillo de las estrellas tras el fundido final
var _lugar_velo := 0           # posición del velo entre los hijos: sobre el fondo y el cartel, bajo las estrellas y el menú


func _ready() -> void:
	Interfaz.desactivar_trucos()
	Interfaz.activar(false)
	EstadoJuego.jugando = false
	Sonido.detener_todo()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.04, 0.05)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_construir_fondos(EstadoJuego.estrellas, EstadoJuego.estrella_reciente)
	# Cielo: una estrella por cada final alcanzado (Casiopea). La recién ganada aparece con fundido.
	_lugar_velo = get_child_count()   # el velo rojo irá aquí: encima del fondo y del cartel, debajo de las estrellas
	var cielo = Constelacion.new()
	_cielo = cielo
	add_child(cielo)
	var reciente := EstadoJuego.estrella_reciente
	cielo.configurar(EstadoJuego.estrellas, reciente)
	EstadoJuego.estrella_reciente = ""
	if cielo.completa():
		# Con la constelación completa y la línea ya dibujada, el cielo se oscurece, se vuelve algo rojo y parpadea.
		_velo_rojo(cielo.duracion_linea() if reciente != "" else 0.0)
	# Menú a la izquierda, para dejar siempre a la vista el cartel del edificio (centro) y el cielo (arriba).
	_tema_rojo = EstadoJuego.modo_desbloqueado >= 3
	_cortina = ColorRect.new()
	add_child(_cortina)
	_caja = VBoxContainer.new()
	_caja.position = MENU_POS
	_caja.add_theme_constant_override("separation", int(SEPARACION))
	add_child(_caja)
	_mostrar_menu("principal")
	Sonido.bucle("musica_titulo", -6.0)


## Pulsar una estrella conseguida. Va en _input (no en _unhandled_input): los controles a pantalla completa del fondo se tragarían el clic.
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT \
			and _popup == null and not _flash_activo and _cielo != null and _cielo.estrella_en(evento.position):
		_destello(_cielo.completa())


## TRUCO de desarrollo (solo en compilaciones de depuración): L supera el siguiente modo (1, 2 y 3 en pulsaciones sucesivas) y recarga el título.
func _unhandled_input(evento: InputEvent) -> void:
	if OS.is_debug_build() and evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_L:
		if _popup == null and not Transicion.ocupada and EstadoJuego.trampa_superar_siguiente() > 0:
			get_tree().reload_current_scene()


func _process(delta: float) -> void:
	# Modo 3 desbloqueado y sin superar: el edificio alterna entre normal y macabro, como una interferencia.
	if _capa_macabra != null and not _superado and not _glitch:
		_proximo_cambio -= delta
		if _proximo_cambio <= 0.0:
			_proximo_cambio = randf_range(4.0, 7.0)
			_interferencia(not _capa_macabra.visible)
		elif _capa_macabra.visible:
			# Mientras se ve el edificio macabro la farola se enciende y se apaga titilando (en el normal queda encendida).
			_proximo_titileo -= delta
			if _proximo_titileo <= 0.0:
				_capa_apagada.visible = not _capa_apagada.visible
				_proximo_titileo = randf_range(0.04, 0.22) if _capa_apagada.visible else randf_range(0.25, 1.4)
	# Parpadeos del velo rojo (solo cuando ya está puesto).
	if _velo == null or _velo_base <= 0.0:
		return
	_proximo_parpadeo -= delta
	if _proximo_parpadeo <= 0.0:
		_proximo_parpadeo = randf_range(1.4, 4.5)
		var t := create_tween()
		for i in randi_range(2, 3):
			t.tween_property(_velo, "color:a", randf_range(0.1, 0.3), 0.05)
			t.tween_property(_velo, "color:a", _velo_base, 0.06 + 0.04 * i)


# --- Fondo del edificio -------------------------------------------------------------------------------

func _capa(textura: String, prefijo_cartel: String, pos: Vector2, ids: Array, nueva: String) -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa)
	var t := Recursos.fondo(textura)
	if t != null:
		var tr := TextureRect.new()
		tr.texture = t
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa.add_child(tr)
	# Cartel del edificio: muy borroso al principio; cada modo superado lo aclara y con los tres se lee «CORMANT · Medical Systems».
	_cartel(capa, ids, nueva, prefijo_cartel, pos)
	return capa


## Normal siempre; el macabro aparece al desbloquear el modo 3. Hasta superarlo alterna con el normal; superado, se queda (farola apagada).
## Al volver justo después de superarlo (`nueva == "m3"`), empieza normal y el cambio llega cuando se han dibujado las estrellas.
func _construir_fondos(ids: Array, nueva: String) -> void:
	_capa_normal = _capa("titulo", "titulo_cartel_", CARTEL_POS, ids, nueva)
	if EstadoJuego.modo_desbloqueado < 3:
		return
	_superado = ids.has("m3")
	_capa_macabra = _capa("titulo_macabro", "titulo_macabro_cartel_", CARTEL_POS_MACABRO, ids, nueva)
	_capa_apagada = _capa("titulo_macabro_apagado", "titulo_macabro_cartel_", CARTEL_POS_MACABRO, ids, nueva)   # farola apagada, encima
	if _superado:
		if nueva == "m3":
			_capa_macabra.modulate.a = 0.0     # el cambio se hace después (_cambio_macabro)
			_capa_apagada.modulate.a = 0.0
			var c = Constelacion.new()
			var espera: float = c.duracion_linea() if ids.size() >= 5 else 3.5   # sin las cinco estrellas no hay línea: basta con que se dibujen las estrellas
			c.free()
			_cambio_macabro(espera)
		else:
			_capa_macabra.visible = false
	else:
		_capa_macabra.visible = false
		_capa_apagada.visible = false
		_proximo_cambio = randf_range(3.0, 5.0)


## Interferencia: unos destellos rápidos con el edificio descolocado y luego se queda en el estado pedido.
func _interferencia(macabro: bool) -> void:
	_glitch = true
	var t := create_tween()
	for i in randi_range(4, 6):
		var estado := (i % 2 == 0) == macabro
		t.tween_callback(func():
			_capa_macabra.visible = estado
			_capa_apagada.visible = false
			var d := Vector2(randf_range(-9, 9), randf_range(-3, 3))
			_capa_normal.position = d
			_capa_macabra.position = d
			_capa_macabra.modulate = Color(1.5, 1.3, 1.3) if randf() < 0.4 else Color.WHITE)
		t.tween_interval(randf_range(0.03, 0.09))
	t.tween_callback(func():
		_capa_macabra.visible = macabro
		_capa_apagada.visible = false
		_proximo_titileo = randf_range(0.5, 1.2)
		_capa_normal.position = Vector2.ZERO
		_capa_macabra.position = Vector2.ZERO
		_capa_macabra.modulate = Color.WHITE
		_glitch = false)


## Tras superar el modo 3: pasado `espera` (estrellas y línea ya dibujadas) parpadea, cambia al edificio macabro y la farola se apaga.
func _cambio_macabro(espera: float) -> void:
	if _capa_apagada == null:
		return
	var t := create_tween()
	t.tween_interval(espera)
	for i in 3:
		t.tween_callback(func(): _capa_macabra.modulate.a = 1.0)
		t.tween_interval(0.05 + 0.03 * i)
		t.tween_callback(func(): _capa_macabra.modulate.a = 0.0)
		t.tween_interval(0.07)
	t.tween_callback(func(): _capa_macabra.modulate.a = 1.0)
	t.tween_interval(0.9)       # la farola aún luce un momento
	for i in 3:                 # y se apaga con parpadeos
		t.tween_callback(func(): _capa_apagada.modulate.a = 1.0)
		t.tween_interval(0.06)
		t.tween_callback(func(): _capa_apagada.modulate.a = 0.0)
		t.tween_interval(0.08)
	t.tween_callback(func(): _capa_apagada.modulate.a = 1.0)


## Al pulsar una estrella. Con la constelación completa: pantallazo blanco con un texto donde van los subtítulos (provisional), unos 4 s,
## y después se funde con la vista normal. Si no está completa: destello blanco que se atenúa poco a poco en 3 s.
func _destello(con_texto: bool) -> void:
	_flash_activo = true
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_STOP if con_texto else Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var t := create_tween()
	if con_texto:
		var frase := Label.new()   # misma posición y tamaño que los subtítulos del juego (Interfaz._mensaje)
		frase.text = TEXTO_ESTRELLA
		frase.position = Vector2(360, 446)
		frase.size = Vector2(560, 100)
		frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		frase.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		frase.add_theme_font_size_override("font_size", 20)
		frase.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
		frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.add_child(frase)
		t.tween_interval(TIEMPO_TEXTO)
		t.tween_property(flash, "modulate:a", 0.0, 1.5)
	else:
		t.tween_property(flash, "color:a", 0.0, 3.0)
	t.tween_callback(func():
		flash.queue_free()
		_flash_activo = false)


## Fundido final: oscurece el cielo y lo tiñe de rojo, con parpadeos. `espera` = lo que tarda en terminar de dibujarse la línea de la constelación.
func _velo_rojo(espera: float) -> void:
	_velo = ColorRect.new()
	_velo.color = Color(0.2, 0.0, 0.02, 0.0)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_velo)
	move_child(_velo, _lugar_velo)
	# Viñeta: esquinas tirando a negro, como una visión de ojo; entra con el mismo fundido.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.88)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	_vineta = TextureRect.new()
	_vineta.texture = gt
	_vineta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vineta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vineta.stretch_mode = TextureRect.STRETCH_SCALE
	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vineta)
	move_child(_vineta, _lugar_velo + 1)
	if espera <= 0.0:
		_vineta.modulate.a = 1.0
	else:
		_vineta.modulate.a = 0.0
		var tv := create_tween()
		tv.tween_interval(espera)
		tv.tween_property(_vineta, "modulate:a", 1.0, 3.5)
	if espera <= 0.0:
		_velo.color.a = VELO_ALFA
		_velo_base = VELO_ALFA
		if _cielo != null:
			_cielo.atenuar(ATENUACION_ESTRELLAS, 0.0)
	else:
		var t := create_tween()
		t.tween_interval(espera)
		t.tween_property(_velo, "color:a", VELO_ALFA, 3.5)
		t.tween_callback(func(): _velo_base = VELO_ALFA)
		if _cielo != null:   # las estrellas se atenúan con el mismo fundido
			var ta := create_tween()
			ta.tween_interval(espera)
			ta.tween_method(func(v: float): _cielo.atenuacion = v, 1.0, ATENUACION_ESTRELLAS, 3.5)
	_proximo_parpadeo = espera + 4.0


# --- Menús --------------------------------------------------------------------------------------------

## Destruye el menú actual y construye `nombre`: «principal», «partidas», «opciones» o «confirmar».
func _mostrar_menu(nombre: String) -> void:
	for h in _caja.get_children():
		_caja.remove_child(h)
		h.queue_free()
	if _popup != null:
		_popup.queue_free()
		_popup = null
	var plus := EstadoJuego.modo_desbloqueado >= 2
	var items: Array = []     # [texto, Callable] o [texto, Callable, "rojo"]
	match nombre:
		"principal":
			items = [["Nueva partida +", _on_nueva_partida, "rojo"] if EstadoJuego.modo_desbloqueado >= 3 else ["Nueva partida +" if plus else "Nueva partida", _on_nueva_partida],
				["Opciones", _mostrar_menu.bind("opciones")],
				["Salir", func(): get_tree().quit()]]
		"partidas":
			items = [["Nueva partida", _iniciar.bind(1)], ["Nueva partida +", _iniciar.bind(2)]]
			if EstadoJuego.modo_desbloqueado >= 3:
				items.append(["Nueva partida +", _iniciar.bind(3), "rojo"])
			items.append(["Volver", _mostrar_menu.bind("principal")])
		"opciones":
			items = [["Borrar datos", _mostrar_menu.bind("confirmar")], ["Volver", _mostrar_menu.bind("principal")]]
		"confirmar":
			_cortina.visible = false
			_popup_borrar()
			return
	_cortina.visible = true
	var alto := items.size() * (ALTO_BOTON + SEPARACION) - SEPARACION
	_cortina.color = Color(0.12, 0.0, 0.0, 0.72) if _tema_rojo else Color(0, 0, 0, 0.62)
	_cortina.position = Vector2(MENU_POS.x - 24.0, MENU_POS.y - 16.0)
	_cortina.size = Vector2(ANCHO_BOTON + 48.0, alto + 32.0)
	_caja.size = Vector2(ANCHO_BOTON, alto)
	for it in items:
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(ANCHO_BOTON, ALTO_BOTON)
		_estilo_boton(boton)
		if it.size() > 2 and it[2] == "rojo":
			_texto_de_dedo(boton)
		else:
			boton.text = it[0]
		boton.pressed.connect(it[1])
		_caja.add_child(boton)


## Con solo el modo 1 desbloqueado, Nueva partida empieza directamente; después abre el menú de partidas.
func _on_nueva_partida() -> void:
	if EstadoJuego.modo_desbloqueado <= 1:
		_iniciar(1)
	else:
		_mostrar_menu("partidas")


func _iniciar(modo: int) -> void:
	if Transicion.ocupada:
		return
	EstadoJuego.modo = modo
	EstadoJuego.nueva_partida()
	Sonido.detener_todo()
	Transicion.ir_a_escena("res://escenas/escenario.tscn", 0.7)


## El botón de la nueva partida del modo 3: «Nueva partida +» en rojo, con la letra de dedo de los mensajes de sangre (imagen).
func _texto_de_dedo(boton: Button) -> void:
	var tex: Texture2D = load(TEXTO_ROJO)
	if tex == null:
		boton.text = "Nueva partida +"
		return
	var esc := minf((ANCHO_BOTON - 30.0) / tex.get_width(), 58.0 / tex.get_height())
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = tex.get_size() * esc
	tr.position = Vector2((ANCHO_BOTON - tr.size.x) / 2.0, (ALTO_BOTON - tr.size.y) / 2.0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(tr)
	boton.mouse_entered.connect(func(): tr.modulate = Color(1.35, 1.2, 1.2))
	boton.mouse_exited.connect(func(): tr.modulate = Color(1, 1, 1))


## Tercer menú, emergente y centrado: ¿borrar todos los datos?
func _popup_borrar() -> void:
	_popup = Control.new()
	_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_popup)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(velo)
	var panel := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.12, 0.02, 0.02, 0.96) if _tema_rojo else Color(0.05, 0.07, 0.1, 0.96)
	caja.border_color = Color(0.75, 0.25, 0.22, 0.9) if _tema_rojo else Color(0.6, 0.7, 0.8, 0.8)
	caja.set_border_width_all(2)
	caja.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", caja)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_popup.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)
	var pregunta := Label.new()
	pregunta.text = "¿Seguro que quieres borrar todos los datos?\nSe perderá todo el progreso: modos, estrellas y partida guía. No se puede deshacer."
	pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pregunta.add_theme_font_size_override("font_size", 22)
	v.add_child(pregunta)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 20)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(fila)
	var si := Button.new()
	si.text = "Sí, borrar"
	si.custom_minimum_size = Vector2(200, ALTO_BOTON)
	_estilo_boton(si)
	si.pressed.connect(_borrar_datos)
	fila.add_child(si)
	var no := Button.new()
	no.text = "No"
	no.custom_minimum_size = Vector2(200, ALTO_BOTON)
	_estilo_boton(no)
	no.pressed.connect(_mostrar_menu.bind("opciones"))
	fila.add_child(no)
	no.grab_focus()   # por seguridad, el foco empieza en «No»


func _borrar_datos() -> void:
	EstadoJuego.borrar_progreso()
	get_tree().reload_current_scene()   # el título se reconstruye sin estrellas ni cartel nítido y con el menú del principio


func _estilo_boton(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 22)
	if _tema_rojo:
		b.add_theme_color_override("font_color", Color(0.95, 0.82, 0.8))
		b.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.88))
	for estado in ["normal", "hover", "pressed"]:
		var caja := StyleBoxFlat.new()
		if _tema_rojo:
			caja.bg_color = Color(0.14, 0.03, 0.03, 0.92) if estado == "normal" else Color(0.34, 0.06, 0.06, 0.96)
			caja.border_color = Color(0.78, 0.26, 0.22, 0.85)
		else:
			caja.bg_color = Color(0.08, 0.1, 0.14, 0.9) if estado == "normal" else Color(0.18, 0.24, 0.32, 0.95)
			caja.border_color = Color(0.6, 0.7, 0.8, 0.8)
		caja.set_border_width_all(2)
		b.add_theme_stylebox_override(estado, caja)


## Pone sobre el fondo (cartel muy borroso) el recorte que corresponde a los modos superados; si el último final acaba de
## subir el nivel, el recorte nuevo aparece con fundido sobre el anterior.
func _cartel(padre: Control, ids: Array, nueva: String, prefijo: String, pos: Vector2) -> void:
	# Cartel borroso solo en los modos 1 y 2: al superar el modo 2 (modo 3 desbloqueado) el logo se ve nítido para siempre.
	var nivel := 3 if EstadoJuego.modo_desbloqueado >= 3 else EstadoJuego.modos_superados_de(ids)
	var previo := nivel
	if nueva != "" and nueva.begins_with("m2") and EstadoJuego.modo_desbloqueado >= 3:
		previo = 0   # acaba de superar el modo 2: el logo se aclara con fundido
	elif nueva != "" and EstadoJuego.modo_desbloqueado < 3:
		var sin: Array = ids.duplicate()
		sin.erase(nueva)
		previo = EstadoJuego.modos_superados_de(sin)
	for n in [previo, nivel]:
		if n <= 0:
			continue
		var textura := Recursos.fondo("%s%d" % [prefijo, n])
		if textura == null:
			continue
		var tr := TextureRect.new()
		tr.texture = textura
		tr.position = pos
		tr.size = textura.get_size()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padre.add_child(tr)
		if n == nivel and previo != nivel:
			tr.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_interval(1.0)
			tween.tween_property(tr, "modulate:a", 1.0, 3.0)
