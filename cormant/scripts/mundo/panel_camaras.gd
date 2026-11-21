class_name PanelCamaras
extends PanelBase
## Terminal de vigilancia: tres monitores: laboratorio, pasillo y una cámara sin señal que solo emite audio.

var _vista: VistaCamara
var _botones := {}
var _boton_nota: Button
var _papel_nota: ColorRect
var _texto_nota: Label


static func crear() -> PanelCamaras:
	var p := PanelCamaras.new()
	p.es_ordenador = true
	p.titulo = "Terminal de vigilancia"
	return p


func _construir() -> void:
	var marco := ColorRect.new()
	marco.color = Color(0.05, 0.05, 0.06)
	marco.position = Vector2(100, 76)
	marco.size = Vector2(920, 470)
	contenido.add_child(marco)
	_vista = VistaCamara.new()
	_vista.position = Vector2(120, 92)
	_vista.size = Vector2(880, 438)
	_vista.clip_contents = true
	contenido.add_child(_vista)
	var fila := HBoxContainer.new()
	fila.position = Vector2(160, 558)
	fila.add_theme_constant_override("separation", 20)
	contenido.add_child(fila)
	for id in ["1", "2", "3"]:
		var b := Button.new()
		b.text = "CAM " + id
		b.custom_minimum_size = Vector2(160, 44)
		b.pressed.connect(func(): _elegir(id))
		fila.add_child(b)
		_botones[id] = b
	# Hoja pegada bajo el monitor de la CAM 3: solo se ve con esa cámara elegida.
	_boton_nota = Button.new()
	_boton_nota.text = "Hoja bajo el monitor"
	_boton_nota.position = Vector2(132, 486)
	_boton_nota.size = Vector2(200, 32)
	_boton_nota.visible = false
	_boton_nota.pressed.connect(_abrir_nota)
	contenido.add_child(_boton_nota)
	_papel_nota = ColorRect.new()
	_papel_nota.color = Color(0.86, 0.82, 0.7)
	_papel_nota.position = Vector2(240, 100)
	_papel_nota.size = Vector2(800, 440)
	_papel_nota.visible = false
	_papel_nota.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_papel_nota.visible = false)
	contenido.add_child(_papel_nota)
	_texto_nota = Label.new()
	_texto_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_nota.custom_minimum_size = Vector2(720, 0)
	_texto_nota.position = Vector2(40, 30)
	_texto_nota.size = Vector2(720, 380)
	_texto_nota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto_nota.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	_texto_nota.add_theme_font_size_override("font_size", 20)
	_papel_nota.add_child(_texto_nota)
	_elegir("1")


func _abrir_nota() -> void:
	_texto_nota.text = Textos.nota_tecnico(EstadoJuego.pista_pitidos())
	_papel_nota.visible = true
	Sonido.reproducir("papel")


func _elegir(id: String) -> void:
	if Director.terminal_ocupado():
		return
	_vista.seleccionar(id)
	_boton_nota.visible = id == "3"
	if id != "3":
		_papel_nota.visible = false
