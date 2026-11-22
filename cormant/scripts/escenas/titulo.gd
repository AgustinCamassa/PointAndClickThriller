extends Control

const Constelacion := preload("res://scripts/escenas/constelacion.gd")
## Pantalla de título con menús que se sustituyen unos a otros (cada pulsación destruye el menú anterior y construye el nuevo):
##  - Principal: Nueva partida (con «+» desde que se desbloquea el modo 2), Opciones, Salir.
##  - Nueva partida: con solo el modo 1 empieza directamente. Con el modo 2 desbloqueado abre un menú con Nueva partida (modo 1) y Nueva partida + (modo 2);
##    con el modo 3 desbloqueado se añade otra Nueva partida + (modo 3), escrita en rojo con la letra de dedo. Todos con Volver.
##  - Opciones: Borrar datos y Volver. Borrar datos abre un tercer menú emergente que pregunta si se está seguro.
##  - Al superar el modo 2 (modo 3 desbloqueado) el menú cambia de color (rojo oscuro).
##  - Con las cinco estrellas unidas por la línea, un fundido oscurece el cielo, lo vuelve algo rojo y lo hace parpadear.
## No hay texto de título: el título es el cartel del edificio (CORMANT · Medical Systems), borroso hasta superar los tres modos.

const MENU_POS := Vector2(56, 330)
const ANCHO_BOTON := 360.0
const ALTO_BOTON := 50.0
const SEPARACION := 12.0
const TEXTO_ROJO := "res://assets/sprites/menu_nueva_partida_mas.png"   # «Nueva partida +» en rojo, letra de dedo (sangre_mensajes.py)
const VELO_ALFA := 0.62                  # oscuridad del fundido rojo final
const CARTEL_POS := Vector2(550, 316)    # dónde van los recortes de titulo_cartel_N.png sobre el fondo (ver fondo_titulo.py)


var _cortina: ColorRect
var _caja: VBoxContainer
var _popup: Control
var _tema_rojo := false
var _velo: ColorRect
var _velo_base := 0.0
var _proximo_parpadeo := 3.0
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
	var textura := Recursos.fondo("titulo")
	if textura != null:
		var tr := TextureRect.new()
		tr.texture = textura
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(tr)
	# Cartel del edificio: muy borroso al principio; cada modo superado lo aclara y con los tres se lee «CORMANT · Medical Systems».
	_cartel(EstadoJuego.estrellas, EstadoJuego.estrella_reciente)
	# Cielo: una estrella por cada final alcanzado (Casiopea). La recién ganada aparece con fundido.
	_lugar_velo = get_child_count()   # el velo rojo irá aquí: encima del fondo y del cartel, debajo de las estrellas
	var cielo = Constelacion.new()
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


func _process(delta: float) -> void:
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


## Fundido final: oscurece el cielo y lo tiñe de rojo, con parpadeos. `espera` = lo que tarda en terminar de dibujarse la línea de la constelación.
func _velo_rojo(espera: float) -> void:
	_velo = ColorRect.new()
	_velo.color = Color(0.2, 0.0, 0.02, 0.0)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_velo)
	move_child(_velo, _lugar_velo)
	if espera <= 0.0:
		_velo.color.a = VELO_ALFA
		_velo_base = VELO_ALFA
	else:
		var t := create_tween()
		t.tween_interval(espera)
		t.tween_property(_velo, "color:a", VELO_ALFA, 3.5)
		t.tween_callback(func(): _velo_base = VELO_ALFA)
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
			items = [["Nueva partida +" if plus else "Nueva partida", _on_nueva_partida],
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
func _cartel(ids: Array, nueva: String) -> void:
	var nivel := EstadoJuego.modos_superados_de(ids)
	var previo := nivel
	if nueva != "":
		var sin: Array = ids.duplicate()
		sin.erase(nueva)
		previo = EstadoJuego.modos_superados_de(sin)
	for n in [previo, nivel]:
		if n <= 0:
			continue
		var textura := Recursos.fondo("titulo_cartel_%d" % n)
		if textura == null:
			continue
		var tr := TextureRect.new()
		tr.texture = textura
		tr.position = CARTEL_POS
		tr.size = textura.get_size()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		if n == nivel and previo != nivel:
			tr.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_interval(1.0)
			tween.tween_property(tr, "modulate:a", 1.0, 3.0)
