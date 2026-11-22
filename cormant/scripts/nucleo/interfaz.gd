extends CanvasLayer
## Interfaz persistente: compatibilidad, móvil con las señales activas (derecha), mensajes (sobre los botones),
## botones inferiores Volver/Cerrar, libreta de objetivos (abajo a la izquierda), menú de eventos (reportar/descartar),
## botón de ocultarse, filtros de color (sin shaders) y menú de pausa.

signal volver_pedido
signal cerrar_pedido
signal dev_fin_pedido   # DEV (K): se resolvió el 5.º glifo; la escena lanza el documento final

var activa := false

var _raiz: Control
var _tinte_compat: ColorRect
var _tinte_rojo: Control   # filtro rojo (FiltroRojo) en una capa por encima de toda la interfaz
var _capa_filtro: CanvasLayer
var _atenuacion := 1.0
var _parpadeo: ColorRect
var _oculto: ColorRect
var _boton_notas: Button
var _mensaje: Label
var _texto_evento: Label
var _lcd_rect := Rect2()
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
var _capa_flash: CanvasLayer
var _claves_previas := {}         # señales de anomalía del fotograma anterior (para detectar las nuevas)
var _leds_tween: Tween
var _detector: Control            # detector de señales (sprite + LCD); solo visible tras conseguirlo
var _boton_volver: Button
var _boton_cerrar: Button
var _hay_panel := false
var _etiqueta_dev: Label
var _tween_mensaje: Tween
var _tiempo_parpadeo := 0.0
var _apagon: ColorRect
var _tween_apagon: Tween
var _tiempo_alarma := 0.0
var _tween_alarma: Tween
const FiltroRojo := preload("res://scripts/nucleo/filtro_rojo.gd")
const ALARMA_PERIODO := 1.5
const ALARMA_APAGADO := 0.45   # parte del periodo en que los LEDs se apagan al destellar
var _mensaje_oculto_en := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	EstadoJuego.compatibilidad_cambiada.connect(_al_cambiar_compatibilidad)
	EstadoJuego.fragmento_obtenido.connect(func(_id): _refrescar_notas())
	EstadoJuego.glifos_cambiado.connect(_refrescar_notas)
	EstadoJuego.partida_nueva.connect(_al_nueva_partida)
	Director.mensaje.connect(mensaje)
	Director.apagon_cambiado.connect(_al_cambiar_apagon)
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
	# La luz roja tiñe también el detector, la libreta y los botones: va en una capa por encima de la interfaz.
	_capa_filtro = CanvasLayer.new()
	_capa_filtro.layer = layer + 1
	add_child(_capa_filtro)
	_tinte_rojo = FiltroRojo.new()
	_capa_filtro.add_child(_tinte_rojo)
	_parpadeo = _rect_filtro(Color(0, 0, 0, 0))
	_oculto = _rect_filtro(Color(0, 0, 0, 0))
	_apagon = _rect_filtro(Color(0, 0, 0, 0))   # luces apagadas: por debajo del detector, que sigue encendido

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
	_mensaje.position = Vector2(360, 446)   # centrado en la pantalla (1280 px): 640 - 560 / 2
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


## Detector de señales, pegado al borde inferior derecho (el sprite está recortado: se ve de la antena a los botones).
##  - LCD (grande, marcos laterales reducidos): lista de señales activas y, debajo, el texto de la señal seleccionada.
##  - LEDs = compatibilidad: 9 luces de 10 % cada una (verdes 1-5, amarillas 6-8, roja 9). Con cada señal nueva las luces
##    encendidas parpadean 2 veces y el detector pita; con 0 % parpadea solo la primera luz y queda apagada.
##  - Los botones del dibujo (◀ ■ ▶) son decorativos; descartar / reportar / otra señal son tres botones en la franja
##    inferior de la pantalla (sobre Volver y Cerrar) que solo aparecen en Vigilancia.
## Las constantes salen de importar_detector.py (coordenadas del PNG original de 468x1040). Antena a la derecha, ruleta a la izquierda.
const DETECTOR_TAM := Vector2(161.5, 358.7)   # 15 % menos que antes: así no tapa la libreta de la recepción
const LCD_REL := Rect2(0.1175, 0.5635, 0.7991, 0.2923)
const DET_ORIGINAL := Vector2(468, 1040)
const LEDS_X := [107, 138, 169, 200, 231, 262, 293, 325, 356]
const LEDS_Y := 528
const LEDS_COLOR := [Color(0.4, 0.82, 0.2), Color(0.4, 0.82, 0.2), Color(0.43, 0.84, 0.2), Color(0.45, 0.85, 0.19), Color(0.48, 0.86, 0.2),
	Color(0.9, 0.83, 0.15), Color(0.9, 0.79, 0.15), Color(0.9, 0.72, 0.13), Color(0.89, 0.2, 0.27)]


func _escala_det() -> Vector2:
	return DETECTOR_TAM / DET_ORIGINAL


func _construir_detector() -> void:
	_detector = Control.new()
	_detector.position = Vector2(1280.0 - DETECTOR_TAM.x - 8.0, 720.0 - DETECTOR_TAM.y)
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
	_lcd_rect = lcd
	_senales.size = Vector2(lcd.size.x - 8, 54)
	_senales.clip_text = true
	_estilo_lcd(_senales, Color(0.4, 1.0, 0.55))
	_detector.add_child(_senales)
	_texto_evento = Label.new()
	_texto_evento.position = lcd.position + Vector2(5, 60)
	_texto_evento.size = Vector2(lcd.size.x - 8, lcd.size.y - 64)
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
		halo.position = Vector2(-6.5, -7)
		halo.size = Vector2(13, 14)
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		led.add_child(halo)
		var luz := ColorRect.new()
		luz.color = c
		luz.position = Vector2(-3.2, -3.5)
		luz.size = Vector2(6.4, 7)
		luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		led.add_child(luz)
		led.visible = false
		_detector.add_child(led)
		_leds.append(led)
	_refrescar_menu()


## El texto de la señal elegida va justo debajo de la lista (que crece con cada señal), sin pisarla.
func _acomodar_lcd() -> void:
	var alto := float(_senales.get_line_count()) * float(_senales.get_line_height())
	_senales.size.y = alto
	_texto_evento.position.y = _senales.position.y + alto + 3.0
	_texto_evento.size.y = maxf(_lcd_rect.end.y - _texto_evento.position.y - 4.0, 0.0)


func _estilo_lcd(l: Label, color: Color) -> void:
	l.add_theme_font_size_override("font_size", 11)
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
		_al_terminar_advertencia()   # nada de ocultarse (barra, botón, oscurecimiento) pillado al cambiar de escena
		_pausa.visible = false
		get_tree().paused = false


## Al volver al título se apagan todos los trucos: invulnerabilidad y panel de depuración.
func desactivar_trucos() -> void:
	EstadoJuego.desactivar_trucos()
	Director.entidades_pausadas = false
	_etiqueta_dev.visible = false
	_depuracion.visible = false


func _al_cambiar_apagon(activo: bool) -> void:
	## Se van las luces (oscuridad casi total salvo el detector) y se bloquea todo salvo OCULTARSE; al volver, un chasquido de luz.
	if _tween_apagon != null:
		_tween_apagon.kill()
	_tween_apagon = create_tween()
	_apagon.color = Color(0, 0, 0, 0)
	if activo:
		_claves_previas = {}
		if _leds_tween != null:
			_leds_tween.kill()
		_animando_leds = false
		# Destello de caída de tensión (el fondo ya cambia a su versión oscura): nada de pantallazo negro.
		_tween_apagon.tween_property(_apagon, "color:a", 0.45, 0.05)
		_tween_apagon.tween_property(_apagon, "color:a", 0.0, 0.2)
	else:
		_tween_apagon.tween_property(_apagon, "color:a", 0.3, 0.05)
		_tween_apagon.tween_property(_apagon, "color:a", 0.0, 0.2)
		_claves_previas = {}   # al volver la luz no se considera «señal nueva» lo que ya estaba
	_poner_leds(nivel_leds())
	_refrescar_menu()
	_actualizar_botones()


## En el apagón el detector y la libreta se oscurecen con el resto de la imagen (siguen legibles, pero ya no «pegados» encima).
func _atenuar_ui_apagon(delta: float) -> void:
	var objetivo := 0.45 if Director.apagon_activo() else 1.0
	_atenuacion = move_toward(_atenuacion, objetivo, delta * 6.0)
	var c := Color(_atenuacion, _atenuacion, _atenuacion, 1.0)
	for n in [_detector, _boton_notas, _notas, _boton_volver, _boton_cerrar]:
		if n != null:
			n.modulate = c


func _al_nueva_partida() -> void:
	_apagon.color.a = 0.0
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


## DEV (K) va por _input para que ningún panel o botón con foco se trague la tecla.
func _input(evento: InputEvent) -> void:
	if activa and OS.is_debug_build() and evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_K:
		_dev_paso_resolver()
		get_viewport().set_input_as_handled()


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
			KEY_H:
				Director.entidades_pausadas = not Director.entidades_pausadas
				mensaje("[DEV] Entidades %s" % ("PAUSADAS: sin sorteo ni anomalías (H para reanudar)" if Director.entidades_pausadas else "reanudadas"), 2.0)


## DEV (tecla K): 1.ª pulsación mete el PIN de Vigilancia; las siguientes resuelven el glifo 1, 2, 3, 4 y 5 del puzzle
## (solicitándolo antes si hace falta). Cada pulsación simula la partida real (solicita, resuelve la anomalía, confirma y deja pedido el siguiente); tras el 5.º lanza el documento final.
func _dev_paso_resolver() -> void:
	if not EstadoJuego.vigilancia_abierta:
		EstadoJuego.abrir_vigilancia()
		mensaje("[DEV] PIN de Vigilancia resuelto", 2.0)
		return
	if EstadoJuego.glifos_completos():
		dev_fin_pedido.emit()
		return
	# Simula la partida real: se solicita el glifo, su anomalía se resuelve (el glifo se ve), se confirma en el terminal
	# y se solicita el siguiente, para que las anomalías que dependen del glifo pedido/resuelto se comporten como al jugar.
	var i := EstadoJuego.confirmados
	if EstadoJuego.solicitados == i:
		EstadoJuego.solicitar()
	var id: String = EstadoJuego.ORDEN_FRAGMENTOS[i]
	EstadoJuego.revelar(id)
	if not EstadoJuego.confirmar(i, EstadoJuego.glifos[i]):
		return
	mensaje("[DEV] Glifo %d de 5 resuelto" % (i + 1), 2.0)
	if EstadoJuego.glifos_completos():
		dev_fin_pedido.emit()
	else:
		EstadoJuego.solicitar()


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
	## Ya no hay medidor numérico: la compatibilidad se lee en los LEDs del detector.
	_tinte_compat.color.a = clampf(valor / 100.0 * 0.38, 0.0, 0.38)
	if not _animando_leds:
		_poner_leds(nivel_leds())


func _al_pedir_sonido(nombre: String) -> void:
	if _depuracion.visible:
		mensaje("[sonido: %s]" % nombre, 1.2)


# --- Notas -----------------------------------------------------------------------------------------

func _alternar_notas() -> void:
	_notas.visible = not _notas.visible
	_refrescar_notas()


func _refrescar_notas() -> void:
	## La libreta guarda los objetivos y el avance, no los dibujos: hay que recordarlos.
	if _texto_notas == null:
		return
	var lineas := ["OBJETIVOS", "Abrir el terminal del laboratorio con los 5 glifos.", "Ahora: " + _objetivo_actual(), "", "GLIFOS"]
	for i in EstadoJuego.NUM_GLIFOS:
		var nombre: String = Textos.NOMBRE_FRAGMENTO[EstadoJuego.ORDEN_FRAGMENTOS[i]]
		var estado := "bloqueado"
		if i < EstadoJuego.confirmados:
			estado = "confirmado"
		elif i < EstadoJuego.solicitados:
			estado = "por introducir en el terminal"
		lineas.append("%d. %s: %s" % [i + 1, nombre, estado])
	lineas.append("")
	lineas.append("Los dibujos no se anotan solos.")
	_texto_notas.text = "\n".join(lineas)
	call_deferred("_ajustar_libreta")


## La hoja crece hacia arriba desde el botón de la libreta.
func _ajustar_libreta() -> void:
	if _notas == null:
		return
	_notas.reset_size()
	_notas.position = Vector2(14, 654.0 - _notas.size.y)


## Siguiente paso del puzzle según lo que lleva el jugador (sin revelar ningún glifo).
func _objetivo_actual() -> String:
	var e := EstadoJuego
	if not e.vigilancia_abierta:
		return "encontrar el PIN de la puerta de Vigilancia (el ordenador de la recepción)."
	if not e.tiene_tarjeta:
		return "encontrar una tarjeta de seguridad para abrir el laboratorio."
	if e.glifos_completos():
		return "El terminal está abierto."
	if e.solicitados > e.confirmados:
		var id: String = e.ORDEN_FRAGMENTOS[e.confirmados]
		if e.visibles.has(id):
			return "introducir en el terminal el glifo que has visto."
		return "buscar el glifo %d. %s" % [e.confirmados + 1, Textos.PISTA_SOLICITUD[id]]
	return "solicitar el glifo %d en el terminal del laboratorio." % (e.confirmados + 1)


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
	var libre := activa and en_vigilancia and e != null and not Director.terminal_ocupado() and not Director.apagon_activo()
	# Los tres botones solo existen en Vigilancia, con el detector y alguna señal activa.
	var mostrar := activa and en_vigilancia and EstadoJuego.tiene_detector and e != null
	for b in [_boton_reportar, _boton_descartar, _boton_siguiente]:
		b.visible = mostrar
	_boton_reportar.disabled = not libre
	_boton_descartar.disabled = not libre
	_boton_siguiente.disabled = not (mostrar and Director.eventos.size() > 1) or Director.apagon_activo()
	if Director.apagon_activo():
		_texto_evento.text = "SIN ENERGÍA"
		return
	if e == null or not en_vigilancia:
		_texto_evento.text = "" if e == null else "Esto se decide desde Vigilancia."
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
	_boton_volver.disabled = _hay_panel or (DatosSalas.volver_a(EstadoJuego.sala_actual) == "" and not DatosSalas.volver_bloqueado(EstadoJuego.sala_actual))
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
	_tinte_rojo.intensidad = move_toward(_tinte_rojo.intensidad, 1.0 if EstadoJuego.filtro_rojo() else 0.0, delta * 4.0)
	_atenuar_ui_apagon(delta)
	_etiqueta_dev.visible = EstadoJuego.invulnerable
	_actualizar_parpadeo(delta)
	_actualizar_alarma_detector(delta)
	_refrescar_senales()
	_acomodar_lcd()
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


func _actualizar_alarma_detector(delta: float) -> void:
	## Con 90 % o más el detector pita sin parar (pitido grave y suave; los pitidos de la CAM 3 lo silencian mientras suenan para no
	## mezclarse con la estática) y los LEDs destellan al ritmo de cada pitido. En el modo 3 (99 %) es toda la partida.
	if not EstadoJuego.tiene_detector or not EstadoJuego.jugando or EstadoJuego.compatibilidad < 90.0 or Director.apagon_activo():
		_tiempo_alarma = 0.0
		return
	_tiempo_alarma -= delta
	if _tiempo_alarma > 0.0:
		return
	_tiempo_alarma = ALARMA_PERIODO
	if _animando_leds:
		return   # el aviso de una señal nueva ya los está haciendo parpadear
	if not Director.pitidos_activos():
		Sonido.reproducir("detector_alarma", -9.0)
	if _tween_alarma != null:
		_tween_alarma.kill()
	_poner_leds(0)
	_tween_alarma = create_tween()
	_tween_alarma.tween_interval(ALARMA_APAGADO)
	_tween_alarma.tween_callback(func():
		if not _animando_leds:
			_poner_leds(nivel_leds()))


func _actualizar_parpadeo(delta: float) -> void:
	# Intensidad según tramo y advertencia: luces que parpadean (rectángulo negro, sin shaders).
	var intensidad := 0.0
	match EstadoJuego.tramo:
		2: intensidad = 0.15
		3: intensidad = 0.35
	if Director.advertencia_activa:
		intensidad = 1.0
	var factor := 1.0
	if Director.entidad_parpadeo > 0.0 or Director.parpadeo_ambiente > 0.0 or Director.apagon_aviso > 0.0:
		intensidad = 1.0   # la entidad se detiene tras el clic: parpadeos hasta desaparecer
	elif Director.parpadeo_restante > 0.0 and EstadoJuego.sala_actual == "vigilancia":
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


## Dónde se ve el dato resuelto (el LCD lo dice para que el jugador sepa dónde mirar).
const DONDE_DATO := {"mancha": "CAM 2", "retrato": "CAM 1", "sombra": "PC2", "viento": "oficina"}
const NOMBRE_SENAL := {"cuadro": "CAM1 cuadro", "mancha": "CAM2 mancha", "voz": "CAM3 susurro"}


func _refrescar_senales() -> void:
	## Todo lo activo en un solo sitio (LCD del detector), sin decir si las señales son reales.
	if Director.apagon_activo():
		# Apagón: el detector sigue encendido pero muestra un error y enciende todas las luces.
		_senales.text = "ERROR 0xE5\nSISTEMA CAÍDO\n▒▒▒▒▒▒▒▒"
		_poner_leds(_leds.size())
		return
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
	if Director.parpadeo_pendiente:
		lineas.append("Parpadeo pend.")
		claves["parpadeo"] = true
	if Director.viento_activo():
		lineas.append("Oficina viento")
		claves["viento"] = true
	for id in EstadoJuego.visibles:
		lineas.append("Dato visible %s %ds" % [DONDE_DATO.get(id, ""), int(ceil(EstadoJuego.visibles[id]))])
	if Director.glifo_recepcion_visible():
		lineas.append("Dato visible %s %ds" % [DONDE_DATO.get("sombra", ""), int(ceil(Director.glifo_restante))])
	if Director.manchas_viento_visibles():
		lineas.append("Dato visible %s %ds" % [DONDE_DATO.get("viento", ""), int(ceil(Director.viento_manchas_restante))])
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
		_poner_leds(nivel_leds())


## Luces que corresponden a la compatibilidad: una por cada 10 % (60 % = 6 luces; 90 % o más = las 9, con la roja).
func nivel_leds() -> int:
	## LEDs encendidos según la compatibilidad: 1–15 % → 1; 16–29 → 2; 30–39 → 3; 40–49 → 4; 50–59 → 5;
	## 60–69 → 6 (5 verdes + 1 amarillo); 70–79 → 7; 80–89 → 8; 90–100 → 9 (el rojo).
	if Director.apagon_activo():
		return _leds.size()   # durante el apagón el detector enciende todas las luces
	return mini(EstadoJuego.nivel_detector(EstadoJuego.compatibilidad), _leds.size())


## Aturdimiento de las ayudas ocultas: destello blanco intenso (~2 s) con un pitido y una frase en negro que se funde con la vista normal.
## No pausa el juego (es un aturdimiento, no una pausa) y no bloquea el ratón.
func flash_blanco(texto: String) -> void:
	if _capa_flash != null and is_instance_valid(_capa_flash):
		_capa_flash.queue_free()
	_capa_flash = CanvasLayer.new()
	_capa_flash.layer = layer + 2   # por encima del filtro rojo: tapa también el detector y los botones
	add_child(_capa_flash)
	var blanco := ColorRect.new()
	blanco.color = Color(1, 1, 1, 1)
	blanco.set_anchors_preset(Control.PRESET_FULL_RECT)
	blanco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_flash.add_child(blanco)
	var frase := Label.new()
	frase.text = texto
	frase.set_anchors_preset(Control.PRESET_FULL_RECT)
	frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.add_theme_font_size_override("font_size", 38)
	frase.add_theme_color_override("font_color", Color(0, 0, 0))
	frase.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))   # contorno oscuro: se lee aunque el blanco se esté yendo
	frase.add_theme_constant_override("outline_size", 3)
	frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_flash.add_child(frase)
	Sonido.reproducir("aturdimiento", -6.0)
	var capa := _capa_flash
	var t := create_tween()
	t.tween_interval(0.7)                                  # blanco pleno
	t.tween_property(blanco, "modulate:a", 0.0, 1.3)       # y se funde con la vista normal (≈ 2 s en total)
	t.parallel().tween_property(frase, "modulate:a", 0.0, 0.7).set_delay(0.6)   # el texto aguanta algo más que el blanco pleno
	t.tween_callback(func():
		if is_instance_valid(capa):
			capa.queue_free())


func _poner_leds(nivel: int) -> void:
	for i in _leds.size():
		_leds[i].visible = i < nivel
		_pintar_led(i)


## El LED marcado por la libreta se ve blanco hasta que el daño recibido iguala lo que restó; los demás, con su color natural.
func _pintar_led(i: int) -> void:
	var c: Color = Color(1, 1, 1) if i == EstadoJuego.led_blanco else LEDS_COLOR[i]
	_leds[i].get_child(0).color = Color(c, 0.28 if i != EstadoJuego.led_blanco else 0.4)
	_leds[i].get_child(1).color = c


## Señal nueva: parpadean 2 veces las luces del nivel de compatibilidad actual (solo la primera si es 0 %, que luego queda
## apagada) y el detector pita en cada destello (solo si se tiene el detector).
func _alerta_detector() -> void:
	if not EstadoJuego.tiene_detector:
		return
	if _leds_tween != null:
		_leds_tween.kill()
	_animando_leds = true
	_leds_tween = create_tween()
	var nivel := nivel_leds()
	var destello := maxi(nivel, 1)
	if nivel > 0:
		_leds_tween.tween_callback(func(): _poner_leds(0))
		_leds_tween.tween_interval(0.1)
	for i in 2:
		_leds_tween.tween_callback(func():
			_poner_leds(destello)
			Sonido.reproducir("detector_bip"))
		_leds_tween.tween_interval(0.14)
		_leds_tween.tween_callback(func(): _poner_leds(0))
		_leds_tween.tween_interval(0.12)
	_leds_tween.tween_callback(func():
		_animando_leds = false
		_poner_leds(nivel_leds()))


func _actualizar_depuracion() -> void:
	var activos := []
	for e in Director.eventos:
		activos.append("%s(%s,%ds)" % [e.tipo, "real" if e.real else "falso", int(e.restante)])
	_depuracion.text = "t=%s tramo=%d comp=%.0f%% muertes=%d\nproximo=%.0f gracia=%.0f bloqueo=%.0f\nactivos=%s silueta_en_rodaje=%s\nfijas=%s bolsa=%s\nglifos=%s" % [
		EstadoJuego.tiempo_formateado(), EstadoJuego.tramo, EstadoJuego.compatibilidad, EstadoJuego.muertes,
		Director.proximo, Director.gracia, Director.bloqueo, str(activos), EstadoJuego.silueta_en_rodaje(),
		str(Director.fijas.keys()), str(Director.bolsa), str(EstadoJuego.glifos)]
