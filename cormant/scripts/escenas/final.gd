extends Control
## Documento final y los dos finales que se resuelven aquí:
##  - Final bueno (no ha muerto): luz normal, mitad inferior ilegible, informe de sesión, corte a negro.
##  - Final malo (ha muerto una vez): luz roja, la tinta roja revela la segunda mitad, y al cerrar la hoja
##    la silueta aparece detrás de Alicia. Parpadeo y telón negro.
##  - Final del modo 3 (único): todo lo que se leía antes se tacha y, encima, la sombra escribe con sangre
##    «Sabes quién soy...». Después, el mismo cierre que el final malo.

const TextoTachado := preload("res://scripts/escenas/texto_tachado.gd")
const FiltroRojo := preload("res://scripts/nucleo/filtro_rojo.gd")
const SANGRE := "res://assets/sprites/sangre_sabes_quien_soy.png"

var _malo := false
var _modo3 := false
var _hoja: Control
var _rojas: Array = []
const MESA_LINEA_Y := 403.0   # borde superior de la mesa blanca (en el fondo de 1280x720): corte a ras, sin hueco
var _rojo: Control   # filtro rojo del final malo (debe quedar por encima de los sprites)


func _ready() -> void:
	Interfaz.activar(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_malo = EstadoJuego.muertes > 0
	_modo3 = EstadoJuego.modo >= EstadoJuego.MODOS.size()
	_fondo_laboratorio()
	if _malo:
		_rojo = FiltroRojo.new()
		_rojo.intensidad = 1.0
		add_child(_rojo)
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
		_hoja_documento()
	var cerrar := Button.new()
	cerrar.text = "Cerrar la hoja"
	cerrar.position = Vector2(540, 620)
	cerrar.size = Vector2(200, 50)
	cerrar.pressed.connect(_cerrar_hoja.bind(cerrar))
	_hoja.add_child(cerrar)


## Documento por bloques (Textos.documento): lo que se tapa o se revela depende del modo y del final.
func _hoja_documento() -> void:
	var modo2: bool = EstadoJuego.modo == 2
	var tam := 14 if modo2 else 17
	var caja := VBoxContainer.new()
	caja.position = Vector2(350, 50)
	caja.custom_minimum_size = Vector2(580, 0)
	caja.add_theme_constant_override("separation", 12)
	_hoja.add_child(caja)
	for b in Textos.documento(EstadoJuego.modo, _malo):
		var roja: bool = b["rojo"]
		var l := _etiqueta(caja, b["texto"], Vector2.ZERO, Vector2(580, 0), tam, Color(0.75, 0.05, 0.05) if roja else Color(0.1, 0.08, 0.06))
		l.custom_minimum_size = Vector2(580, 0)
		l.add_theme_constant_override("line_spacing", -3 if modo2 else 0)
		if roja:
			l.modulate.a = 0.0
			_rojas.append(l)
		if b.has("nota") and _malo:
			# Nota en tinta roja al lado de una línea del bloque (Modo 2 malo).
			var n := _etiqueta(l, b["nota"], Vector2.ZERO, Vector2(260, 0), tam, Color(0.75, 0.05, 0.05))
			var linea: String = String(b["texto"]).split("\n")[b["nota_linea"]]
			n.position = Vector2(l.get_theme_default_font().get_string_size(linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 14.0, (l.get_line_height() + (-3 if modo2 else 0)) * b["nota_linea"])
			n.autowrap_mode = TextServer.AUTOWRAP_OFF
			n.modulate.a = 0.0
			_rojas.append(n)
	if not _rojas.is_empty():
		# La luz roja revela la tinta roja.
		var tween := create_tween()
		tween.tween_interval(1.5)
		for r in _rojas:
			tween.parallel().tween_property(r, "modulate:a", 1.0, 2.5)
		Sonido.reproducir("tono_revelacion")


## Modo 3: se ven los textos de los finales anteriores, se tachan uno a uno y la sombra escribe encima.
func _hoja_sangre() -> void:
	var superior = TextoTachado.new()
	superior.position = Vector2(350, 50)
	_hoja.add_child(superior)
	superior.preparar(Textos.BLOQUE_A + "\n\n" + Textos.BLOQUE_D, 580.0, 13)
	var anterior = TextoTachado.new()
	anterior.position = Vector2(350, 395)
	anterior.color_texto = Color(0.55, 0.05, 0.05)
	_hoja.add_child(anterior)
	anterior.preparar(Textos.BLOQUE_B + "\n\n" + Textos.BLOQUE_E, 580.0, 13)
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
	# Recorte a la altura de los muslos: Alicia está detrás de la mesa blanca, frente al ordenador. Todo lo que queda por
	# debajo de la línea de la mesa (y de la mesa misma) se corta: no se ven piernas ni pies.
	var recorte := Control.new()
	recorte.position = Vector2.ZERO
	recorte.size = Vector2(1280, MESA_LINEA_Y)
	recorte.clip_contents = true
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(recorte)
	var alicia := Alicia.new()
	alicia.configurar("de_espaldas", Vector2(622, 511), Vector2(67, 231))
	recorte.add_child(alicia)
	move_child(_rojo, get_child_count() - 1)
	alicia.aparecer(0.2)
	await get_tree().create_timer(2.0).timeout
	# La silueta aparece siempre detrás de Alicia.
	# Más alta que Alicia (antes 231 de alto, igual que ella) para que domine la escena.
	var silueta := Alicia.new()
	var alto_entidad := 268.0
	silueta.configurar("silueta", Vector2(566, 511), Vector2(alto_entidad * Alicia.ASPECTO_ENTIDAD, alto_entidad), true)
	recorte.add_child(silueta)
	recorte.move_child(silueta, alicia.get_index())
	# Velo oscuro sobre toda la escena (debajo del filtro rojo): la sala se apaga mientras la entidad se forma.
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0)
	velo.size = Vector2(1280, 720)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	move_child(_rojo, get_child_count() - 1)   # el filtro rojo tiñe también a Alicia y a la entidad, como al resto
	# No aparece de golpe: se insinúa con la luz bajando, parpadea y por fin se vuelve sólida.
	silueta.modulate = Color(0.5, 0.52, 0.58, 0.0)
	var aparicion := create_tween()
	aparicion.tween_property(velo, "color:a", 0.4, 0.7)
	aparicion.parallel().tween_property(silueta, "modulate:a", 0.3, 0.7)
	aparicion.tween_property(silueta, "modulate:a", 0.0, 0.06)
	aparicion.tween_property(velo, "color:a", 0.55, 0.05)
	aparicion.tween_property(silueta, "modulate:a", 0.6, 0.2)
	aparicion.tween_property(silueta, "modulate:a", 0.1, 0.06)
	aparicion.parallel().tween_property(velo, "color:a", 0.3, 0.06)
	aparicion.tween_callback(Sonido.reproducir.bind("golpe_grave"))
	aparicion.tween_property(silueta, "modulate", Color(1, 1, 1, Alicia.ALFA_ENTIDAD), 0.6)
	aparicion.parallel().tween_property(velo, "color:a", 0.35, 0.6)
	await aparicion.finished
	await get_tree().create_timer(0.5).timeout
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
