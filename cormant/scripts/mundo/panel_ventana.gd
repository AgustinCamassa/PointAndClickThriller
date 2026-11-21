class_name PanelVentana
extends PanelBase
## Ventanas de cristal unidireccional.
##  - "recepcion": desde Vigilancia, zona de entrada de la recepción (se ve la silueta).
##  - "secreta": desde la Oficina, el pasillo secreto con la puerta morada y su placa.

var tipo := "recepcion"
var _silueta: Alicia
var _velo: ColorRect
var _clip: Control   # recorte al cristal para la entidad de la ventana de recepción
var _temporizador := 6.0
var _silueta_restante := 0.0
var _cristal: ColorRect
var _tr_fondo: TextureRect
var _manchas: Array[Control] = []
## Zona del suelo del pasillo (relativa al cristal) donde las manchas dibujan el glifo: ancha y baja, por la perspectiva.
const AREA_GLIFO_SUELO := Rect2(110, 385, 700, 135)


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
	var fondo_tex := _textura_fondo()
	if fondo_tex != null:
		var tr := TextureRect.new()
		_tr_fondo = tr
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
	Director.apagon_cambiado.connect(_al_cambiar_apagon)
	if tipo == "recepcion":
		_construir_entidad(cristal)
	else:
		_silueta = Alicia.new()
		# Pies (x, y) y alto relativos al cristal.
		var v: Vector3 = ZonasFondos.SILUETA_SECRETO
		var alto := v.z * cristal.size.y
		_silueta.configurar("silueta", cristal.position + Vector2(v.x * cristal.size.x, v.y * cristal.size.y),
			Vector2(alto * Alicia.ASPECTO_ENTIDAD, alto), true)
		_silueta.visible = false
		contenido.add_child(_silueta)


func _nombre_fondo() -> String:
	return "ventana_recepcion" if tipo == "recepcion" else "pasillo_secreto"


## Con el apagón se ve la versión oscura de la vista (la ventana no es un ordenador y sigue abierta).
func _textura_fondo() -> Texture2D:
	var base := _nombre_fondo()
	# Con la entidad de la ventana (recepción) o con el 5.º glifo pedido (pasillo secreto) se ve la vista macabra.
	if Director.macabro(base) and Recursos.fondo(base + "_macabro") != null:
		base += "_macabro"
	if Director.apagon_activo():
		var oscura := Recursos.fondo(base + "_apagon")
		if oscura != null:
			return oscura
	return Recursos.fondo(base)


func _al_cambiar_apagon(_activo: bool) -> void:
	if is_instance_valid(_tr_fondo):
		_tr_fondo.texture = _textura_fondo()
	if is_instance_valid(_silueta):
		_silueta.modulate = Color(0.4, 0.42, 0.48, Alicia.ALFA_ENTIDAD) if Director.apagon_activo() else Color(1, 1, 1, Alicia.ALFA_ENTIDAD)


func _geometria_fase(fase: int) -> Dictionary:
	## Pies y tamaño (relativos al recorte) de la entidad en cada fase, a partir de ENTIDAD_PANEL.
	var f: Vector3 = ZonasFondos.ENTIDAD_PANEL["fases"][clampi(fase, 1, 3) - 1]
	var alto := f.z * _cristal.size.y
	return {"pies": Vector2(f.x * _cristal.size.x, f.y * _cristal.size.y) - _clip.position, "tam": Vector2(alto * Alicia.ASPECTO_ENTIDAD, alto)}


func _construir_entidad(cristal: ColorRect) -> void:
	## La entidad vista de cerca por la ventana: la misma fase que lleva en la sala, recortada al cristal.
	Director.ventana_abierta = true
	var r: Rect2 = ZonasFondos.ENTIDAD_PANEL["clip"]
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(r.position.x * cristal.size.x, r.position.y * cristal.size.y)
	_clip.size = Vector2(r.size.x * cristal.size.x, r.size.y * cristal.size.y)
	var marco := Control.new()
	marco.position = cristal.position
	marco.size = cristal.size
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(_clip)
	contenido.add_child(marco)
	_velo = Alicia.crear_velo(_clip.size)
	_velo.visible = Director.silueta_visible
	_clip.add_child(_velo)
	_silueta = Alicia.new()
	var g := _geometria_fase(maxi(Director.entidad_fase, 1))
	_silueta.configurar("silueta", g["pies"], g["tam"], true)
	_clip.add_child(_silueta)
	_silueta.visible = Director.silueta_visible
	Director.silueta_cambiada.connect(_al_cambiar_silueta)
	Director.silueta_fase_cambiada.connect(_al_cambiar_fase)


func _al_cambiar_fase(fase: int) -> void:
	if is_instance_valid(_silueta) and fase > 1:
		var g := _geometria_fase(fase)
		_silueta.mover_a(g["pies"], g["tam"], Director.duracion_fase_entidad() * 0.8)


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
	if EstadoJuego.muertes == 0:
		return   # antes de morir la puerta no lleva placa ni texto
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
	placa.text = "14-B"
	contenido.add_child(placa)


func _al_cambiar_silueta(visible_: bool) -> void:
	if is_instance_valid(_tr_fondo):
		_tr_fondo.texture = _textura_fondo()
	if is_instance_valid(_silueta):
		_silueta.visible = visible_
		if is_instance_valid(_velo):
			_velo.visible = visible_
		if visible_:
			_silueta.aparecer(0.05)


func _actualizar_manchas() -> void:
	## Con el viento, las manchas del suelo dibujan el último glifo (Andrómeda), unidas por trazos tenues; se desvanecen solas.
	var debe := Director.manchas_viento_visibles()
	if debe and _manchas.is_empty():
		var v := VistaGlifo.crear(EstadoJuego.glifo_de("viento"), AREA_GLIFO_SUELO.size)
		v.position = _cristal.position + AREA_GLIFO_SUELO.position
		v.textura_mancha = Recursos.sprite("mancha_suelo")
		v.tinte_mancha = Color(0.75, 0.55, 0.8)
		v.color = Color(0.78, 0.58, 0.85, 0.8)
		v.radio = 13.0
		v.grosor = 3.0
		v.margen = 0.0
		contenido.add_child(v)
		_manchas.append(v)
	elif not debe and not _manchas.is_empty():
		for m in _manchas:
			m.queue_free()
		_manchas.clear()


func _process(delta: float) -> void:
	if tipo == "recepcion":
		# Detenida por el clic: parpadea antes de desaparecer.
		if is_instance_valid(_silueta) and Director.silueta_visible:
			_silueta.visible = Director.entidad_parpadeo <= 0.0 or int(Director.entidad_parpadeo * 14.0) % 2 == 0
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
	if Director.apagon_cambiado.is_connected(_al_cambiar_apagon):
		Director.apagon_cambiado.disconnect(_al_cambiar_apagon)
	if tipo == "recepcion":
		Director.ventana_abierta = false
		if Director.silueta_cambiada.is_connected(_al_cambiar_silueta):
			Director.silueta_cambiada.disconnect(_al_cambiar_silueta)
		if Director.silueta_fase_cambiada.is_connected(_al_cambiar_fase):
			Director.silueta_fase_cambiada.disconnect(_al_cambiar_fase)
