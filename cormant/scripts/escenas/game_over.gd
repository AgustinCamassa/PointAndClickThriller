extends Control
## Segunda muerte: fin de la partida.


func _ready() -> void:
	Interfaz.activar(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sonido.detener_todo()
	Sonido.reproducir("pitido_plano")
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var t := Label.new()
	t.text = Textos.GAME_OVER
	t.position = Vector2(0, 220)
	t.size = Vector2(1280, 100)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 72)
	t.add_theme_color_override("font_color", Color(0.8, 0.15, 0.15))
	add_child(t)
	var caja := VBoxContainer.new()
	caja.position = Vector2(520, 400)
	caja.size = Vector2(240, 140)
	caja.add_theme_constant_override("separation", 16)
	add_child(caja)
	var reintentar := Button.new()
	reintentar.text = Textos.REINTENTAR
	reintentar.custom_minimum_size = Vector2(240, 56)
	reintentar.pressed.connect(_reintentar)
	caja.add_child(reintentar)
	var menu := Button.new()
	menu.text = Textos.VOLVER_MENU
	menu.custom_minimum_size = Vector2(240, 56)
	menu.pressed.connect(func(): Transicion.ir_a_escena("res://escenas/titulo.tscn"))
	caja.add_child(menu)


func _reintentar() -> void:
	if Transicion.ocupada:
		return
	EstadoJuego.nueva_partida()
	Transicion.ir_a_escena("res://escenas/escenario.tscn", 0.7)
