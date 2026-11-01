extends Control

const Constelacion := preload("res://scripts/escenas/constelacion.gd")
## Pantalla de título. Sin menú de opciones: un botón por modo desbloqueado y Salir.


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
	# Cielo: una estrella por cada final alcanzado (Casiopea). La recién ganada aparece con fundido.
	var cielo = Constelacion.new()
	add_child(cielo)
	cielo.configurar(EstadoJuego.estrellas, EstadoJuego.estrella_reciente)
	EstadoJuego.estrella_reciente = ""
	var titulo := Label.new()
	titulo.text = Textos.TITULO
	titulo.position = Vector2(0, 150)
	titulo.size = Vector2(1280, 120)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 110)
	titulo.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	add_child(titulo)
	var sub := Label.new()
	sub.text = Textos.SUBTITULO
	sub.position = Vector2(0, 280)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.modulate = Color(1, 1, 1, 0.5)
	add_child(sub)
	# Debajo del título: un botón por modo desbloqueado (aparecen a medida que se superan) y Salir.
	var n_modos: int = EstadoJuego.modo_desbloqueado
	var alto := 24.0 + (n_modos + 1) * 72.0
	var cortina := ColorRect.new()
	cortina.color = Color(0, 0, 0, 0.62)
	cortina.position = Vector2(430, 366)
	cortina.size = Vector2(420, alto)
	add_child(cortina)
	var caja := VBoxContainer.new()
	caja.position = Vector2(470, 382)
	caja.size = Vector2(340, alto - 24.0)
	caja.add_theme_constant_override("separation", 16)
	add_child(caja)
	for m in n_modos:
		var boton := Button.new()
		boton.text = "MODO %d · %s" % [m + 1, EstadoJuego.MODOS[m + 1]["nombre"]]
		boton.custom_minimum_size = Vector2(340, 56)
		_estilo_boton(boton)
		boton.pressed.connect(_nueva_partida.bind(m + 1))
		caja.add_child(boton)
	var salir := Button.new()
	salir.text = "Salir"
	salir.custom_minimum_size = Vector2(340, 56)
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
	b.add_theme_font_size_override("font_size", 24)
	for estado in ["normal", "hover", "pressed"]:
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(0.08, 0.1, 0.14, 0.9) if estado == "normal" else Color(0.18, 0.24, 0.32, 0.95)
		caja.border_color = Color(0.6, 0.7, 0.8, 0.8)
		caja.set_border_width_all(2)
		b.add_theme_stylebox_override(estado, caja)
