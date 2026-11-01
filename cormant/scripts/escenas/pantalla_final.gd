extends Control
## Cierre de la demo: agradecimiento y lista de deseos.


func _ready() -> void:
	Interfaz.activar(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sonido.detener_todo()
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_texto(Textos.FIN_DEMO, 180, 64)
	_texto(Textos.FIN_GRACIAS, 290, 30)
	_texto(Textos.FIN_LISTA_DESEOS, 350, 24)
	if EstadoJuego.desbloqueo_reciente > 0:
		var n: int = EstadoJuego.desbloqueo_reciente
		_texto(Textos.MODO_DESBLOQUEADO % [n, EstadoJuego.MODOS[n]["nombre"]], 420, 26)
	var menu := Button.new()
	menu.text = Textos.VOLVER_MENU
	menu.position = Vector2(520, 500)
	menu.size = Vector2(240, 56)
	menu.pressed.connect(func(): Transicion.ir_a_escena("res://escenas/titulo.tscn"))
	add_child(menu)


func _texto(t: String, y: float, tam: int) -> void:
	var l := Label.new()
	l.text = t
	l.position = Vector2(0, y)
	l.size = Vector2(1280, tam + 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	add_child(l)
