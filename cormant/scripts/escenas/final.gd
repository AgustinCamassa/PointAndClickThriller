extends Control
## Documento final y los dos finales que se resuelven aquí:
##  - Final bueno (no ha muerto): luz normal, mitad inferior ilegible, informe de sesión, corte a negro.
##  - Final malo (ha muerto una vez): luz roja, la tinta roja revela la segunda mitad, y al cerrar la hoja
##    la silueta aparece detrás de Alicia. Parpadeo y telón negro.
##  - Final del modo 3 (único): todo lo que se leía antes se tacha y, encima, la sombra escribe con sangre
##    «Sabes quién soy...». Después, el mismo cierre que el final malo.

const TextoTachado := preload("res://scripts/escenas/texto_tachado.gd")
const SANGRE := "res://assets/sprites/sangre_sabes_quien_soy.png"

var _malo := false
var _modo3 := false
var _hoja: Control
var _inferior: Label


func _ready() -> void:
	Interfaz.activar(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_malo = EstadoJuego.muertes > 0
	_modo3 = EstadoJuego.modo >= EstadoJuego.MODOS.size()
	_fondo_laboratorio()
	if _malo:
		var rojo := ColorRect.new()
		rojo.color = Color(0.7, 0.0, 0.0, 0.3)
		rojo.set_anchors_preset(Control.PRESET_FULL_RECT)
		rojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rojo)
	_mostrar_hoja()


func _fondo_laboratorio() -> void:
	var datos := DatosSalas.obtener("laboratorio")
	var textura := Recursos.fondo("laboratorio")
	if textura != null:
		var tr := TextureRect.new()
		tr.texture = textura
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(tr)
	else:
		var c := ColorRect.new()
		c.color = datos["color"]
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(c)


func _etiqueta(padre: Control, t: String, pos: Vector2, tam: Vector2, fuente := 20, color := Color(0.1, 0.08, 0.06)) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = tam
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fuente)
	l.add_theme_color_override("font_color", color)
	padre.add_child(l)
	return l


func _mostrar_hoja() -> void:
	_hoja = Control.new()
	_hoja.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hoja)
	var papel := ColorRect.new()
	papel.color = Color(0.88, 0.84, 0.72)
	papel.position = Vector2(320, 30)
	papel.size = Vector2(640, 660)
	_hoja.add_child(papel)
	if _modo3:
		_hoja_sangre()
	else:
		_etiqueta(_hoja, Textos.DOCUMENTO_SUPERIOR, Vector2(350, 50), Vector2(580, 280))
	if _modo3:
		pass
	elif _malo:
		# La parte inferior está impresa con dos tintas; la luz roja revela la segunda.
		_inferior = _etiqueta(_hoja, Textos.DOCUMENTO_INFERIOR_BUENO, Vector2(350, 350), Vector2(580, 160))
		var roja := _etiqueta(_hoja, Textos.DOCUMENTO_ROJO, Vector2(350, 350), Vector2(580, 200), 20, Color(0.75, 0.05, 0.05))
		roja.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(roja, "modulate:a", 1.0, 2.5)
		tween.parallel().tween_property(_inferior, "modulate:a", 0.0, 2.5)
		Sonido.reproducir("tono_revelacion")
	else:
		_inferior = _etiqueta(_hoja, Textos.DOCUMENTO_INFERIOR_BUENO, Vector2(350, 350), Vector2(580, 200))
	var cerrar := Button.new()
	cerrar.text = "Cerrar la hoja"
	cerrar.position = Vector2(540, 620)
	cerrar.size = Vector2(200, 50)
	cerrar.pressed.connect(_cerrar_hoja.bind(cerrar))
	_hoja.add_child(cerrar)


## Modo 3: se ven los textos de los finales anteriores, se tachan uno a uno y la sombra escribe encima.
func _hoja_sangre() -> void:
	var superior = TextoTachado.new()
	superior.position = Vector2(350, 50)
	_hoja.add_child(superior)
	superior.preparar(Textos.DOCUMENTO_SUPERIOR, 580.0)
	var anterior = TextoTachado.new()
	anterior.position = Vector2(350, 350)
	anterior.color_texto = Color(0.55, 0.05, 0.05)
	_hoja.add_child(anterior)
	anterior.preparar(Textos.DOCUMENTO_ROJO, 580.0)
	# Rótulo de la hoja de sangre: aparece recortado de izquierda a derecha, como si se escribiera.
	var tex: Texture2D = load(SANGRE)
	var marco := Control.new()
	marco.clip_contents = true
	marco.position = Vector2(332, 272)
	marco.size = Vector2(0, 150)
	marco.rotation = deg_to_rad(-3.0)
	_hoja.add_child(marco)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.size = tex.get_size() * 0.5
		marco.add_child(tr)
		marco.custom_minimum_size = Vector2(0, tr.size.y)
	Sonido.reproducir("tono_revelacion")
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_method(func(v: float): superior.tachado = v, 0.0, 1.0, 1.6)
	tween.parallel().tween_method(func(v: float): anterior.tachado = v, 0.0, 1.0, 1.6)
	tween.tween_interval(0.7)
	tween.tween_callback(Sonido.reproducir.bind("susurro_terminal"))
	var ancho_final: float = tex.get_size().x * 0.5 if tex != null else 600.0
	tween.tween_property(marco, "size:x", ancho_final, 3.2)


func _cerrar_hoja(boton: Button) -> void:
	boton.disabled = true
	_hoja.queue_free()
	if _malo:
		await _cierre_malo()
	else:
		_informe_bueno()


# --- Final bueno ---------------------------------------------------------------------------------------

func _informe_bueno() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.05, 0.06)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var texto := Textos.INFORME_BUENO % [
		EstadoJuego.tiempo_formateado(), EstadoJuego.aciertos,
		EstadoJuego.falsas_alarmas, int(round(EstadoJuego.compatibilidad))]
	_etiqueta(panel, texto, Vector2(400, 150), Vector2(520, 360), 24, Color(0.75, 0.95, 0.8))
	var seguir := Button.new()
	seguir.text = "Continuar"
	seguir.position = Vector2(540, 560)
	seguir.size = Vector2(200, 50)
	seguir.pressed.connect(_corte_a_negro)
	panel.add_child(seguir)


func _corte_a_negro() -> void:
	# Corte seco a negro, sin silueta.
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(negro)
	await get_tree().create_timer(2.5).timeout
	Transicion.ir_a_escena("res://escenas/pantalla_final.tscn", 0.2)


# --- Final malo -------------------------------------------------------------------------------------------

func _cierre_malo() -> void:
	var alicia := Alicia.new()
	alicia.configurar("de_espaldas", Vector2(640, 600), Vector2(97, 336))
	add_child(alicia)
	alicia.aparecer(0.2)
	await get_tree().create_timer(2.0).timeout
	# La silueta aparece siempre detrás de Alicia.
	var silueta := Alicia.new()
	silueta.configurar("de_espaldas", Vector2(540, 590), Vector2(97, 336), true)
	add_child(silueta)
	move_child(silueta, alicia.get_index())
	silueta.aparecer(0.05)
	Sonido.reproducir("golpe_grave")
	# Parpadeo de la imagen y telón negro.
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.size = Vector2(1280, 720)
	negro.position = Vector2(0, -720)
	negro.modulate.a = 0.0
	add_child(negro)
	for i in 6:
		negro.modulate.a = 1.0
		negro.position.y = 0.0
		await get_tree().create_timer(0.06).timeout
		negro.modulate.a = 0.0
		await get_tree().create_timer(randf_range(0.08, 0.3)).timeout
	negro.modulate.a = 1.0
	negro.position.y = -720.0
	var tween := create_tween()
	tween.tween_property(negro, "position:y", 0.0, 1.2)
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	Transicion.ir_a_escena("res://escenas/pantalla_final.tscn", 0.2)
