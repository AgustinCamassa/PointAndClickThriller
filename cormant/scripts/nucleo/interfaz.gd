extends CanvasLayer
## Interfaz persistente: compatibilidad, móvil con las señales activas (derecha), mensajes (sobre los botones),
## botones inferiores Volver/Cerrar, libreta de objetivos (abajo a la izquierda), menú de eventos (reportar/descartar),
## botón de ocultarse, filtros de color (sin shaders) y menú de pausa.

signal volver_pedido
signal cerrar_pedido

var activa := false

var _raiz: Control
var _tinte_compat: ColorRect
var _tinte_rojo: ColorRect
var _parpadeo: ColorRect
var _oculto: ColorRect
var _etiqueta_compat: Label
var _boton_notas: Button
var _mensaje: Label
var _texto_evento: Label
var _boton_reportar: Button
var _boton_descartar: Button
var _boton_siguiente: Button
var _indice_evento := 0
var _boton_ocultarse: Button
var _barra_ocultarse: ProgressBar
var _aviso: Label
var _pausa: Control
var _notas: Control
var _texto_notas: Label
var _depuracion: Label
var _senales: Label            # LCD del detector: lista de señales activas
var _leds: Array = []             # 9 LEDs del detector (apagados sin anomalías; parpadean 2 veces con cada señal nueva)
var _animando_leds := false
var _claves_previas := {}         # señales de anomalía del fotograma anterior (para detectar las nuevas)
var _leds_tween: Tween
var _detector: Control            # detector de señales (sprite + LCD); solo visible tras conseguirlo
var _boton_volver: Button
var _boton_cerrar: Button
var _hay_panel := false
var _etiqueta_dev: Label
var _tween_mensaje: Tween
var _tiempo_parpadeo := 0.0
var _mensaje_oculto_en := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	EstadoJuego.compatibilidad_cambiada.connect(_al_cambiar_compatibilidad)
	EstadoJuego.fragmento_obtenido.connect(func(_id): _refrescar_notas())
	EstadoJuego.codigo_cambiado.connect(_refrescar_notas)
	EstadoJuego.partida_nueva.connect(_al_nueva_partida)
	Director.mensaje.connect(mensaje)
	Director.advertencia_iniciada.connect(_al_iniciar_advertencia)
	Director.advertencia_terminada.connect(func(_s): _al_terminar_advertencia())
	Director.terminal_bloqueado.connect(func(_s): _refrescar_menu())
	Director.evento_iniciado.connect(func(_e): _refrescar_menu())
	Director.evento_terminado.connect(func(_e, _r): _refrescar_menu())
	Sonido.sonido_pedido.connect(_al_pedir_sonido)
	activar(false)


func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	_tinte_compat = _rect_filtro(Color(0.02, 0.0, 0.05, 0.0))
	_tinte_rojo = _rect_filtro(Color(0.7, 0.0, 0.0, 0.0))
	_parpadeo = _rect_filtro(Color(0, 0, 0, 0))
	_oculto = _rect_filtro(Color(0, 0, 0, 0))

	_etiqueta_compat = Label.new()
	_etiqueta_compat.position = Vector2(1000, 14)
	_etiqueta_compat.size = Vector2(266, 30)
	_etiqueta_compat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_etiqueta_compat.add_theme_font_size_override("font_size", 20)
	_raiz.add_child(_etiqueta_compat)

	_construir_detector()
	EstadoJuego.detector_obtenido.connect(func():
		_detector.visible = true
		_refrescar_menu())

	_etiqueta_dev = Label.new()
	_etiqueta_dev.text = "[DEV] INVULNERABLE"
	_etiqueta_dev.position = Vector2(14, 14)
	_etiqueta_dev.add_theme_font_size_override("font_size", 16)
	_etiqueta_dev.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_etiqueta_dev.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiqueta_dev.add_theme_constant_override("outline_size", 5)
	_etiqueta_dev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_etiqueta_dev.visible = false
	_raiz.add_child(_etiqueta_dev)

	# Libreta (abajo a la izquierda): al pulsarla se abre la hoja de objetivos.
	_boton_notas = Button.new()
	_boton_notas.text = "Libreta"
	_boton_notas.position = Vector2(14, 662)
	_boton_notas.size = Vector2(130, 48)
	_estilo_papel(_boton_notas)
	_boton_notas.pressed.connect(_alternar_notas)
	_raiz.add_child(_boton_notas)

	# Botones inferiores: Volver (centro-izquierda) y Cerrar (centro-derecha).
	_boton_volver = Button.new()
	_boton_volver.text = "Volver"
	_boton_volver.position = Vector2(470, 662)
	_boton_volver.size = Vector2(150, 48)
	_estilo_boton_barra(_boton_volver)
	_boton_volver.pressed.connect(func(): volver_pedido.emit())
	_raiz.add_child(_boton_volver)
	_boton_cerrar = Button.new()
	_boton_cerrar.text = "Cerrar"
	_boton_cerrar.position = Vector2(660, 662)
	_boton_cerrar.size = Vector2(150, 48)
	_estilo_boton_barra(_boton_cerrar)
	_boton_cerrar.pressed.connect(func(): cerrar_pedido.emit())
	_raiz.add_child(_boton_cerrar)
	# Decisión sobre la señal seleccionada: tres botones centrados, justo encima de Volver y Cerrar.
	var x0 := 640.0 - (3 * 150.0 + 2 * 14.0) / 2.0
	var textos := ["DESCARTAR", "REPORTAR", "OTRA SEÑAL"]
	var ayudas := ["Descartar la señal: no era real", "Reportar la señal: es una anomalía", "Cambiar a otra señal activa"]
	var botones: Array[Button] = []
	for i in 3:
		var b := Button.new()
		b.text = textos[i]
		b.tooltip_text = ayudas[i]
		b.position = Vector2(x0 + i * 164.0, 606)
		b.size = Vector2(150, 44)
		b.focus_mode = Control.FOCUS_NONE
		_estilo_boton_barra(b)
		b.visible = false
		_raiz.add_child(b)
		botones.append(b)
	_boton_descartar = botones[0]
	_boton_descartar.pressed.connect(func(): _decidir(false))
	_boton_reportar = botones[1]
	_boton_reportar.pressed.connect(func(): _decidir(true))
	_boton_siguiente = botones[2]
	_boton_siguiente.pressed.connect(func(): _indice_evento += 1)

	# Caja de texto: justo encima de los botones inferiores.
	_mensaje = Label.new()
	_mensaje.position = Vector2(430, 446)
	_mensaje.size = Vector2(560, 100)
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.add_theme_font_size_override("font_size", 20)
	_mensaje.add_theme_color_override("font_outline_color", Color.BLACK)
	_mensaje.add_theme_constant_override("outline_size", 6)
	_mensaje.modulate.a = 0.0
	_mensaje.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_mensaje)

	_boton_ocultarse = Button.new()
	_boton_ocultarse.text = "OCULTARSE\n(mantener)"
	_boton_ocultarse.position = Vector2(880, 662)
	_boton_ocultarse.size = Vector2(176, 48)
	_boton_ocultarse.add_theme_font_size_override("font_size", 18)
	_boton_ocultarse.button_down.connect(_pulsar_ocultarse)
	_boton_ocultarse.button_up.connect(func(): Director.mantener(false))
	_raiz.add_child(_boton_ocultarse)
	_boton_ocultarse.visible = false

	_barra_ocultarse = ProgressBar.new()
	_barra_ocultarse.position = Vector2(880, 644)
	_barra_ocultarse.size = Vector2(176, 14)
	_barra_ocultarse.max_value = Director.OCULTARSE_NECESARIO
	_barra_ocultarse.show_percentage = false
	_raiz.add_child(_barra_ocultarse)
	_barra_ocultarse.visible = false

	_aviso = Label.new()
	_aviso.text = "ALGO SE ACERCA"
	_aviso.position = Vector2(340, 150)
	_aviso.size = Vector2(600, 40)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 26)
	_aviso.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	_aviso.visible = false
	_raiz.add_child(_aviso)

	_construir_notas()
	_construir_pausa()

	_depuracion = Label.new()
	_depuracion.position = Vector2(14, 60)
	_depuracion.add_theme_font_size_override("font_size", 14)
	_depuracion.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_depuracion.visible = false
	_raiz.add_child(_depuracion)


func _rect_filtro(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(r)
	return r


func _construir_notas() -> void:
	# Hoja de la libreta: papel con margen rojo, se abre justo encima del botón.
	_notas = PanelContainer.new()
	_notas.position = Vector2(14, 318)
	_notas.size = Vector2(410, 100)
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.92, 0.87, 0.68)
	caja.border_color = Color(0.55, 0.15, 0.12)
	caja.border_width_left = 6
	caja.set_corner_radius_all(3)
	caja.set_content_margin_all(14)
	caja.content_margin_left = 20
	_notas.add_theme_stylebox_override("panel", caja)
	_texto_notas = Label.new()
	_texto_notas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_notas.custom_minimum_size = Vector2(370, 0)
	_texto_notas.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	_texto_notas.add_theme_font_size_override("font_size", 16)
	_notas.add_child(_texto_notas)
	_notas.visible = false
	_raiz.add_child(_notas)


## Detector de señales en la esquina inferior derecha. El sprite lleva LCD, LEDs y botones sin contenido:
##  - LCD: lista de señales activas y, debajo, el texto de la señal seleccionada.
##  - LEDs: apagados sin anomalías; encendidos con alguna; con cada señal nueva parpadean 2 veces y pita.
##  - Los botones del dibujo son solo decorativos; descartar / reportar / otra señal son tres botones en la
##    franja inferior de la pantalla (sobre Volver y Cerrar) que solo aparecen en Vigilancia.
## Las constantes salen de importar_detector.py (coordenadas del PNG original de 475x1349).
const DETECTOR_TAM := Vector2(211, 600)
const LCD_REL := Rect2(0.2021, 0.4529, 0.6021, 0.1972)
const DET_ORIGINAL := Vector2(475, 1349)
const LEDS_X := [110, 141, 172, 203, 235, 266, 297, 329, 360]
const LEDS_Y := 537
const LEDS_COLOR := [Color(0.4, 0.82, 0.2), Color(0.43, 0.84, 0.2), Color(0.45, 0.85, 0.19), Color(0.48, 0.86, 0.2),
	Color(0.59, 0.85, 0.19), Color(0.89, 0.83, 0.15), Color(0.9, 0.79, 0.15), Color(0.9, 0.71, 0.13), Color(0.89, 0.2, 0.27)]


func _escala_det() -> Vector2:
	return DETECTOR_TAM / DET_ORIGINAL


func _construir_detector() -> void:
	_detector = Control.new()
	_detector.position = Vector2(1280, 720) - DETECTOR_TAM - Vector2(6, 6)
	_detector.size = DETECTOR_TAM
	_detector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detector.visible = EstadoJuego.tiene_detector
	_raiz.add_child(_detector)
	var tex := Recursos.sprite("detector")
	if tex != null:
		var sprite := TextureRect.new()
		sprite.texture = tex
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.size = DETECTOR_TAM
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_detector.add_child(sprite)
	else:
		var cuerpo := ColorRect.new()
		cuerpo.color = Color(0.14, 0.15, 0.19)
		cuerpo.position = Vector2(0, 80)
		cuerpo.size = DETECTOR_TAM - Vector2(0, 80)
		_detector.add_child(cuerpo)
	var esc := _escala_det()
	# LCD: lista de señales (arriba) y texto de la señal seleccionada (abajo)
	var lcd := Rect2(DETECTOR_TAM * LCD_REL.position, DETECTOR_TAM * LCD_REL.size)
	_senales = Label.new()
	_senales.position = lcd.position + Vector2(5, 3)
	_senales.size = Vector2(lcd.size.x - 8, 50)
	_senales.clip_text = true
	_estilo_lcd(_senales, Color(0.4, 1.0, 0.55))
	_detector.add_child(_senales)
	_texto_evento = Label.new()
	_texto_evento.position = lcd.position + Vector2(5, 57)
	_texto_evento.size = Vector2(lcd.size.x - 8, lcd.size.y - 60)
	_texto_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_evento.clip_text = true
	_estilo_lcd(_texto_evento, Color(0.3, 0.78, 0.42))
	_detector.add_child(_texto_evento)
	# LEDs
	for i in LEDS_X.size():
		var c: Color = LEDS_COLOR[i]
		var led := Control.new()
		led.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var centro := Vector2(LEDS_X[i], LEDS_Y) * esc
		led.position = centro
		var halo := ColorRect.new()
		halo.color = Color(c, 0.28)
		halo.position = Vector2(-8, -9)
		halo.size = Vector2(16, 18)
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		led.add_child(halo)
		var luz := ColorRect.new()
		luz.color = c
		luz.position = Vector2(-4, -4.5)
		luz.size = Vector2(8, 9)
		luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		led.add_child(luz)
		led.visible = false
		_detector.add_child(led)
		_leds.append(led)
	_refrescar_menu()


func _estilo_lcd(l: Label, color: Color) -> void:
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_constant_override("line_spacing", 0)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _estilo_papel(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	b.add_theme_color_override("font_hover_color", Color(0.3, 0.05, 0.04))
	b.add_theme_color_override("font_pressed_color", Color(0.3, 0.05, 0.04))
	for estado in ["normal", "hover", "pressed"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(0.92, 0.87, 0.68) if estado == "normal" else Color(0.97, 0.93, 0.76)
		caja.border_color = Color(0.55, 0.15, 0.12)
		caja.border_width_left = 8
		caja.set_corner_radius_all(3)
		b.add_theme_stylebox_override(estado, caja)


func _estilo_boton_barra(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 22)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caja := StyleBoxFlat.new()
		match estado:
			"normal": caja.bg_color = Color(0.08, 0.1, 0.14, 0.92)
			"disabled": caja.bg_color = Color(0.06, 0.07, 0.09, 0.6)
			_: caja.bg_color = Color(0.18, 0.24, 0.32, 0.95)
		caja.border_color = Color(0.6, 0.7, 0.8, 0.8) if estado != "disabled" else Color(0.4, 0.45, 0.5, 0.4)
		caja.set_border_width_all(2)
		b.add_theme_stylebox_override(estado, caja)


func _construir_pausa() -> void:
	_pausa = ColorRect.new()
	(_pausa as ColorRect).color = Color(0, 0, 0, 0.8)
	_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	# CenterContainer a pantalla completa: el menú queda siempre en el centro.
	var centrar := CenterContainer.new()
	centrar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pausa.add_child(centrar)
	var centro := VBoxContainer.new()
	centro.custom_minimum_size = Vector2(240, 0)
	centro.add_theme_constant_override("separation", 14)
	centrar.add_child(centro)
	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 32)
	centro.add_child(titulo)
	var seguir := Button.new()
	seguir.text = "Continuar"
	seguir.custom_minimum_size = Vector2(240, 50)
	seguir.pressed.connect(alternar_pausa)
	_estilo_boton_barra(seguir)
	centro.add_child(seguir)
	var menu := Button.new()
	menu.text = "Volver al menú"
	menu.custom_minimum_size = Vector2(240, 50)
	menu.pressed.connect(_volver_al_menu)
	_estilo_boton_barra(menu)
	centro.add_child(menu)
	_pausa.visible = false
	_raiz.add_child(_pausa)


# --- Control general ---------------------------------------------------------------------

func activar(valor: bool) -> void:
	activa = valor
	_raiz.visible = valor
	if not valor:
		_pausa.visible = false
		get_tree().paused = false


## Al volver al título se apagan todos los trucos: invulnerabilidad y panel de depuración.
func desactivar_trucos() -> void:
	EstadoJuego.desactivar_trucos()
	_etiqueta_dev.visible = false
	_depuracion.visible = false


func _al_nueva_partida() -> void:
	_claves_previas = {}
	_animando_leds = false
	if _leds_tween != null:
		_leds_tween.kill()
	_notas.visible = false
	_aviso.visible = false
	_boton_ocultarse.visible = false
	_barra_ocultarse.visible = false
	_hay_panel = false
	_detector.visible = EstadoJuego.tiene_detector
	_refrescar_menu()
	_actualizar_botones()
	_refrescar_notas()
	_al_cambiar_compatibilidad(EstadoJuego.compatibilidad)


func _volver_al_menu() -> void:
	get_tree().paused = false
	activar(false)
	Sonido.detener_todo()
	EstadoJuego.jugando = false
	Transicion.ir_a_escena("res://escenas/titulo.tscn")


func alternar_pausa() -> void:
	if not activa:
		return
	var nuevo := not get_tree().paused
	get_tree().paused = nuevo
	_pausa.visible = nuevo


func _unhandled_input(evento: InputEvent) -> void:
	if not activa:
		return
	if evento.is_action_pressed("ui_cancel"):
		alternar_pausa()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ocultarse") and Director.advertencia_activa:
		_pulsar_ocultarse()
	elif evento.is_action_released("ocultarse"):
		Director.mantener(false)
	elif OS.is_debug_build() and evento is InputEventKey and evento.pressed and not evento.echo:
		match evento.keycode:
			KEY_F1:
				_depuracion.visible = not _depuracion.visible
			KEY_F2:
				Director.forzar(Director.TIPOS[randi() % 3])
			KEY_F3:
				EstadoJuego.sumar_compatibilidad(10.0)
			KEY_G:
				EstadoJuego.invulnerable = not EstadoJuego.invulnerable
				_etiqueta_dev.visible = EstadoJuego.invulnerable
				mensaje("[DEV] Invulnerabilidad %s" % ("ACTIVADA" if EstadoJuego.invulnerable else "desactivada"), 2.0)
			KEY_F:
				EstadoJuego.sumar_compatibilidad(20.0, true)
				mensaje("[DEV] +20 % de compatibilidad", 1.5)


# --- Mensajes y etiquetas ----------------------------------------------------------------------

func mensaje(texto: String, duracion := 3.5) -> void:
	_mensaje.text = texto
	if _tween_mensaje:
		_tween_mensaje.kill()
	_mensaje.modulate.a = 1.0
	_tween_mensaje = create_tween()
	_tween_mensaje.tween_interval(duracion)
	_tween_mensaje.tween_property(_mensaje, "modulate:a", 0.0, 0.6)


func _al_cambiar_compatibilidad(valor: float) -> void:
	_etiqueta_compat.text = "COMPATIBILIDAD  %d%%" % int(round(valor))
	var color := Color(0.85, 0.85, 0.85)
	if valor >= Director.UMBRAL_ADVERTENCIA:
		color = Color(0.95, 0.35, 0.25)
	elif valor >= Director.UMBRAL_TONO:
		color = Color(0.95, 0.8, 0.3)
	_etiqueta_compat.add_theme_color_override("font_color", color)
	_tinte_compat.color.a = clampf(valor / 100.0 * 0.38, 0.0, 0.38)


func _al_pedir_sonido(nombre: String) -> void:
	if _depuracion.visible:
		mensaje("[sonido: %s]" % nombre, 1.2)


# --- Notas -----------------------------------------------------------------------------------------

func _alternar_notas() -> void:
	_notas.visible = not _notas.visible
	_refrescar_notas()


func _refrescar_notas() -> void:
	## La libreta guarda los objetivos y el avance, no los números: hay que recordarlos.
	if _texto_notas == null:
		return
	var lineas := ["OBJETIVOS", "Abrir el terminal del laboratorio con el código de 5 dígitos.", "Ahora: " + _objetivo_actual(), "", "CÓDIGO"]
	for i in EstadoJuego.DIGITOS:
		var nombre: String = Textos.NOMBRE_FRAGMENTO[EstadoJuego.ORDEN_FRAGMENTOS[i]]
		var estado := "bloqueado"
		if i < EstadoJuego.confirmados:
			estado = "confirmado"
		elif i < EstadoJuego.solicitados:
			estado = "por introducir en el terminal"
		lineas.append("%d. %s: %s" % [i + 1, nombre, estado])
	lineas.append("")
	lineas.append("Los números no se anotan solos.")
	_texto_notas.text = "\n".join(lineas)
	call_deferred("_ajustar_libreta")


## La hoja crece hacia arriba desde el botón de la libreta.
func _ajustar_libreta() -> void:
	if _notas == null:
		return
	_notas.reset_size()
	_notas.position = Vector2(14, 654.0 - _notas.size.y)


## Siguiente paso del código según lo que lleva el jugador (sin revelar ningún número).
func _objetivo_actual() -> String:
	var e := EstadoJuego
	if e.codigo_completo():
		return "El terminal está abierto."
	if e.solicitados > e.confirmados:
		var id: String = e.ORDEN_FRAGMENTOS[e.confirmados]
		if e.visibles.has(id):
			return "introducir en el terminal el dígito que has visto."
		return "buscar el dígito %d. %s" % [e.confirmados + 1, Textos.PISTA_SOLICITUD[id]]
	return "solicitar el dígito %d en el terminal del laboratorio." % (e.confirmados + 1)


# --- Menú de eventos -----------------------------------------------------------------------------------

func _evento_visible():
	if Director.eventos.is_empty():
		return null
	return Director.eventos[_indice_evento % Director.eventos.size()]


func _refrescar_menu() -> void:
	## Botones y texto de la señal seleccionada del detector; solo se puede decidir desde Vigilancia.
	if _boton_reportar == null:
		return
	var e = _evento_visible()
	var en_vigilancia := EstadoJuego.sala_actual == "vigilancia"
	var libre := activa and en_vigilancia and e != null and not Director.terminal_ocupado()
	# Los tres botones solo existen en Vigilancia, con el detector y alguna señal activa.
	var mostrar := activa and en_vigilancia and EstadoJuego.tiene_detector and e != null
	for b in [_boton_reportar, _boton_descartar, _boton_siguiente]:
		b.visible = mostrar
	_boton_reportar.disabled = not libre
	_boton_descartar.disabled = not libre
	_boton_siguiente.disabled = not (mostrar and Director.eventos.size() > 1)
	if e == null or not en_vigilancia:
		_texto_evento.text = "" if e == null else "Ve a Vigilancia para decidir."
		return
	var texto: String = Director.DESCRIPCION.get(e.tipo, e.tipo)
	if e.pista != "":
		texto += "\n" + e.pista
	if Director.terminal_ocupado():
		texto = "TERMINAL BLOQUEADO"
	_texto_evento.text = texto


func sala_cambiada() -> void:
	_refrescar_menu()
	_actualizar_botones()


## El escenario avisa de que hay (o ya no) un panel abierto: Cerrar solo vale con panel y Volver solo sin él.
func set_panel_abierto(valor: bool) -> void:
	_hay_panel = valor
	_actualizar_botones()


func _actualizar_botones() -> void:
	if _boton_volver == null:
		return
	_boton_volver.disabled = _hay_panel or DatosSalas.volver_a(EstadoJuego.sala_actual) == ""
	_boton_cerrar.disabled = not _hay_panel


func _decidir(reportar: bool) -> void:
	var e = _evento_visible()
	if e == null:
		return
	if reportar:
		Director.reportar(e)
	else:
		Director.descartar(e)
	_refrescar_menu()


# --- Entidad -----------------------------------------------------------------------------------------------

func _pulsar_ocultarse() -> void:
	Director.mantener(true)


func _al_iniciar_advertencia() -> void:
	_aviso.visible = true
	_boton_ocultarse.visible = true
	_boton_ocultarse.text = "OCULTARSE\n(mantener)"
	_barra_ocultarse.visible = true
	_barra_ocultarse.max_value = maxf(Director.ocultarse_necesario(), 0.1)
	_barra_ocultarse.value = 0.0


func _al_terminar_advertencia() -> void:
	_aviso.visible = false
	_boton_ocultarse.visible = false
	_barra_ocultarse.visible = false
	_oculto.color.a = 0.0


# --- Bucle -------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not activa or get_tree().paused:
		return
	_tinte_rojo.color.a = 0.26 if EstadoJuego.filtro_rojo() else 0.0
	_etiqueta_dev.visible = EstadoJuego.invulnerable
	_actualizar_parpadeo(delta)
	_refrescar_senales()
	if Director.advertencia_activa and Director.manteniendo:
		Sonido.bucle("latido", -4.0)
	else:
		Sonido.detener_bucle("latido")
	if Director.advertencia_activa:
		_barra_ocultarse.value = Director.ocultacion
		_oculto.color.a = lerpf(_oculto.color.a, 0.8 if Director.manteniendo else 0.0, 0.2)
	_refrescar_menu()
	if _depuracion.visible:
		_actualizar_depuracion()


func _actualizar_parpadeo(delta: float) -> void:
	# Intensidad según tramo y advertencia: luces que parpadean (rectángulo negro, sin shaders).
	var intensidad := 0.0
	match EstadoJuego.tramo:
		2: intensidad = 0.15
		3: intensidad = 0.35
	if Director.advertencia_activa:
		intensidad = 1.0
	var factor := 1.0
	if Director.parpadeo_restante > 0.0 and EstadoJuego.sala_actual == "vigilancia":
		intensidad = 1.0
		factor = EstadoJuego.cfg("parpadeo_factor")   # modo 3: doble de intensidad (más oscuro y más seguido)
	_tiempo_parpadeo -= delta
	if _tiempo_parpadeo <= 0.0:
		if intensidad > 0.0 and randf() < intensidad:
			_parpadeo.color.a = minf(randf_range(0.35, 0.75) * factor, 1.0)
			_tiempo_parpadeo = randf_range(0.04, 0.14)
		else:
			_parpadeo.color.a = 0.0
			_tiempo_parpadeo = (randf_range(0.15, 0.6) if intensidad > 0.0 else 0.3) / factor


const NOMBRE_SENAL := {"cuadro": "CAM1 cuadro", "mancha": "CAM2 mancha", "voz": "CAM3 susurro"}
const ABREVIATURA_SALA := {"recepcion": "RECEP."}


func _refrescar_senales() -> void:
	## Todo lo activo en un solo sitio (LCD del detector), sin decir si las señales son reales.
	var lineas: Array[String] = []
	var claves := {}   # solo anomalías (no los «datos visibles»): sirven para los LEDs y el aviso de señal nueva
	var elegido = _evento_visible()
	var marcar := EstadoJuego.sala_actual == "vigilancia" and Director.eventos.size() > 1
	for e in Director.eventos:
		var prefijo := ""
		if marcar:
			prefijo = ">" if e == elegido else " "
		lineas.append("%s%s %ds" % [prefijo, NOMBRE_SENAL.get(e.tipo, e.tipo), int(ceil(e.restante))])
		claves["e%d" % e.get_instance_id()] = true
	if Director.pitidos_activos():
		lineas.append("CAM3 pitidos %ds" % int(ceil(Director.pitidos_restante)))
		claves["pitidos"] = true
	if Director.marca_restante > 0.0 and Director.sala_marcada != "":
		var sala: String = ABREVIATURA_SALA.get(Director.sala_marcada, DatosSalas.nombre(Director.sala_marcada).left(6).to_upper())
		lineas.append("MARCA %s %ds" % [sala, int(ceil(Director.marca_restante))])
		claves["marca"] = true
	if Director.parpadeo_pendiente:
		lineas.append("Parpadeo pend.")
		claves["parpadeo"] = true
	if Director.viento_activo():
		lineas.append("Oficina viento")
		claves["viento"] = true
	for id in EstadoJuego.visibles:
		lineas.append("Dato visible %ds" % int(ceil(EstadoJuego.visibles[id])))
	if Director.numero_recepcion_visible():
		lineas.append("Dato visible %ds" % int(ceil(Director.numero_restante)))
	if Director.manchas_viento_visibles():
		lineas.append("Dato visible %ds" % int(ceil(Director.viento_manchas_restante)))
	if lineas.is_empty():
		lineas.append("Sin actividad")
	_senales.text = "\n".join(lineas)
	# Señal nueva = alguna clave que no estaba en el fotograma anterior
	var nueva := false
	for k in claves:
		if not _claves_previas.has(k):
			nueva = true
	_claves_previas = claves
	if nueva:
		_alerta_detector()
	if not _animando_leds:
		_poner_leds(not claves.is_empty())


func _poner_leds(encendidos: bool) -> void:
	for led in _leds:
		led.visible = encendidos


## Señal nueva: los LEDs parpadean 2 veces y el detector pita en cada destello (solo si se tiene el detector).
func _alerta_detector() -> void:
	if not EstadoJuego.tiene_detector:
		return
	if _leds_tween != null:
		_leds_tween.kill()
	_animando_leds = true
	_leds_tween = create_tween()
	for i in 2:
		_leds_tween.tween_callback(func():
			_poner_leds(true)
			Sonido.reproducir("detector_bip"))
		_leds_tween.tween_interval(0.14)
		_leds_tween.tween_callback(func(): _poner_leds(false))
		_leds_tween.tween_interval(0.12)
	_leds_tween.tween_callback(func(): _animando_leds = false)


func _actualizar_depuracion() -> void:
	var activos := []
	for e in Director.eventos:
		activos.append("%s(%s,%ds)" % [e.tipo, "real" if e.real else "falso", int(e.restante)])
	_depuracion.text = "t=%s tramo=%d comp=%.0f%% muertes=%d\nproximo=%.0f gracia=%.0f bloqueo=%.0f\nactivos=%s marca=%s\nfijas=%s bolsa=%s\ncodigo=%s" % [
		EstadoJuego.tiempo_formateado(), EstadoJuego.tramo, EstadoJuego.compatibilidad, EstadoJuego.muertes,
		Director.proximo, Director.gracia, Director.bloqueo, str(activos), Director.sala_marcada,
		str(Director.fijas.keys()), str(Director.bolsa), str(EstadoJuego.codigo)]
