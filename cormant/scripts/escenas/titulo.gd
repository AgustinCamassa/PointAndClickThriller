extends Control

const Constelacion := preload("res://scripts/escenas/constelacion.gd")
## Pantalla de título. Sin menú de opciones: un botón por modo desbloqueado y Salir.
## No hay texto de título: el título es el cartel del edificio (CORMANT · Medical Systems), borroso hasta superar los tres modos.

const MENU_POS := Vector2(56, 330)
const ANCHO_BOTON := 360.0
const ALTO_BOTON := 50.0
const SEPARACION := 12.0
const CARTEL_POS := Vector2(550, 316)    # dónde van los recortes de titulo_cartel_N.png sobre el fondo (ver fondo_titulo.py)


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
	var cielo = Constelacion.new()
	add_child(cielo)
	cielo.configurar(EstadoJuego.estrellas, EstadoJuego.estrella_reciente)
	EstadoJuego.estrella_reciente = ""
	# Menú a la izquierda, para dejar siempre a la vista el cartel del edificio (centro) y el cielo (arriba).
	var n_modos: int = EstadoJuego.modo_desbloqueado
	var alto := 24.0 + (n_modos + 1) * (ALTO_BOTON + SEPARACION) - SEPARACION
	var cortina := ColorRect.new()
	cortina.color = Color(0, 0, 0, 0.62)
	cortina.position = Vector2(MENU_POS.x - 24.0, MENU_POS.y - 16.0)
	cortina.size = Vector2(ANCHO_BOTON + 48.0, alto + 8.0)
	add_child(cortina)
	var caja := VBoxContainer.new()
	caja.position = MENU_POS
	caja.size = Vector2(ANCHO_BOTON, alto - 24.0)
	caja.add_theme_constant_override("separation", int(SEPARACION))
	add_child(caja)
	for m in n_modos:
		var boton := Button.new()
		boton.text = "MODO %d · %s" % [m + 1, EstadoJuego.MODOS[m + 1]["nombre"]]
		boton.custom_minimum_size = Vector2(ANCHO_BOTON, ALTO_BOTON)
		_estilo_boton(boton)
		boton.pressed.connect(_nueva_partida.bind(m + 1))
		caja.add_child(boton)
	var salir := Button.new()
	salir.text = "Salir"
	salir.custom_minimum_size = Vector2(ANCHO_BOTON, ALTO_BOTON)
	_estilo_boton(salir)
	salir.pressed.connect(func(): get_tree().quit())
	caja.add_child(salir)
	Sonido.bucle("musica_titulo", -6.0)


func _nueva_partida(modo: int) -> void:
	if Transicion.ocupada:
		return
	EstadoJuego.modo = modo
	EstadoJuego.nueva_partida()
	Sonido.detener_todo()
	Transicion.ir_a_escena("res://escenas/escenario.tscn", 0.7)


func _estilo_boton(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 22)
	for estado in ["normal", "hover", "pressed"]:
		var caja := StyleBoxFlat.new()
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
