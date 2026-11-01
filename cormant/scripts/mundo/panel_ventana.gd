class_name PanelVentana
extends PanelBase
## Ventanas de cristal unidireccional.
##  - "recepcion": desde Vigilancia, zona de entrada de la recepción (se ve la silueta).
##  - "secreta": desde la Oficina, el pasillo secreto con la puerta morada y su placa.

var tipo := "recepcion"
var _silueta: Alicia
var _temporizador := 6.0
var _silueta_restante := 0.0
var _cristal: ColorRect
var _manchas: Array[Control] = []
## Posiciones (relativas al cristal) de las manchas del suelo; se usan las N primeras.
const POSICIONES_MANCHAS := [Vector2(160, 500), Vector2(380, 500), Vector2(600, 500), Vector2(270, 500), Vector2(490, 500),
	Vector2(710, 500), Vector2(215, 468), Vector2(705, 468), Vector2(300, 468)]


static func crear(tipo_: String) -> PanelVentana:
	var p := PanelVentana.new()
	p.tipo = tipo_
	p.titulo = "Ventana · recepción" if tipo_ == "recepcion" else "Ventana · pasillo"
	return p


func _construir() -> void:
	var cristal := ColorRect.new()
	# Las dos vistas son 16:9 (924x520).
	cristal.size = Vector2(924, 520)
	cristal.position = Vector2((1280.0 - cristal.size.x) / 2.0, 100)
	cristal.color = Color(0.1, 0.15, 0.18) if tipo == "recepcion" else Color(0.12, 0.1, 0.14)
	contenido.add_child(cristal)
	_cristal = cristal
	var fondo_tex := Recursos.fondo("ventana_recepcion" if tipo == "recepcion" else "pasillo_secreto")
	if fondo_tex != null:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture = fondo_tex
		tr.position = cristal.position
		tr.size = cristal.size
		contenido.add_child(tr)
	var nota := Label.new()
	nota.position = Vector2(220, 560)
	nota.size = Vector2(840, 50)
	nota.add_theme_font_size_override("font_size", 18)
	if tipo == "recepcion":
		nota.visible = false  # la imagen ya lleva el marco de la ventana
	else:
		nota.text = "[Pasillo secreto]"
		_puerta_morada()
		Director.ver_manchas_viento()
	contenido.add_child(nota)
	_silueta = Alicia.new()
	# Posición de la silueta según el fondo: pies (x, y) y alto relativos al cristal.
	var v: Vector3 = ZonasFondos.SILUETA_VENTANA if tipo == "recepcion" else ZonasFondos.SILUETA_SECRETO
	var alto := v.z * cristal.size.y
	_silueta.configurar("de_espaldas", cristal.position + Vector2(v.x * cristal.size.x, v.y * cristal.size.y),
		Vector2(alto * 0.29, alto), true)
	_silueta.visible = false
	contenido.add_child(_silueta)
	if tipo == "recepcion":
		Director.silueta_cambiada.connect(_al_cambiar_silueta)
		_silueta.visible = Director.silueta_visible


func _puerta_morada() -> void:
	var origen := _cristal.position
	if Recursos.fondo("pasillo_secreto") == null:
		var puerta := ColorRect.new()
		puerta.color = Color(0.45, 0.15, 0.55)
		var rp := ZonasFondos.rect("pasillo_secreto", "puerta_morada")
		puerta.position = origen + rp.position
		puerta.size = rp.size
		contenido.add_child(puerta)
	# Placa colgada sobre la puerta (el fondo no la lleva dibujada).
	var rpl := ZonasFondos.rect("pasillo_secreto", "placa")
	var fondo_placa := ColorRect.new()
	fondo_placa.color = Color(0.1, 0.11, 0.1, 0.92)
	fondo_placa.position = origen + rpl.position
	fondo_placa.size = rpl.size
	fondo_placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(fondo_placa)
	var placa := Label.new()
	placa.position = fondo_placa.position
	placa.size = rpl.size
	placa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placa.add_theme_font_size_override("font_size", 12)
	placa.add_theme_color_override("font_color", Color(0.78, 0.8, 0.7))
	# Antes de morir la placa dice una cosa; después, otra.
	placa.text = "NO ESTÁ EN LOS REGISTROS" if EstadoJuego.muertes == 0 else "14-B"
	contenido.add_child(placa)


func _al_cambiar_silueta(visible_: bool) -> void:
	if is_instance_valid(_silueta):
		_silueta.visible = visible_
		if visible_:
			_silueta.aparecer(0.05)


func _actualizar_manchas() -> void:
	## Con el viento, aparecen en el suelo tantas manchas como indica el último dígito; se desvanecen solas.
	var debe := Director.manchas_viento_visibles()
	if debe and _manchas.is_empty():
		var n: int = EstadoJuego.digito_de("viento")
		for i in mini(n, POSICIONES_MANCHAS.size()):
			var tr := TextureRect.new()
			tr.texture = Recursos.sprite("mancha_suelo")
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.size = Vector2(66, 22)
			tr.position = _cristal.position + POSICIONES_MANCHAS[i] - tr.size / 2.0
			tr.modulate = Color(0.75, 0.55, 0.8)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			contenido.add_child(tr)
			_manchas.append(tr)
	elif not debe and not _manchas.is_empty():
		for m in _manchas:
			m.queue_free()
		_manchas.clear()


func _process(delta: float) -> void:
	if tipo != "secreta":
		return
	_actualizar_manchas()
	# Con compatibilidad alta, una silueta puede asomar un instante en el pasillo secreto.
	if _silueta_restante > 0.0:
		_silueta_restante -= delta
		if _silueta_restante <= 0.0:
			_silueta.visible = false
		return
	if EstadoJuego.compatibilidad < Director.UMBRAL_ADVERTENCIA:
		return
	_temporizador -= delta
	if _temporizador <= 0.0:
		_temporizador = randf_range(6.0, 12.0)
		if randf() < 0.5:
			_silueta.visible = true
			_silueta.aparecer(0.05)
			_silueta_restante = 2.0
			Sonido.reproducir("estatica_breve")


func _exit_tree() -> void:
	if tipo == "recepcion" and Director.silueta_cambiada.is_connected(_al_cambiar_silueta):
		Director.silueta_cambiada.disconnect(_al_cambiar_silueta)
