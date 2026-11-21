class_name VistaCamara
extends Control
## Pantalla CRT de una cámara (filtro verde). Dibuja la vista, estática y las señales de los eventos.
## Cámara 1: laboratorio (con la anomalía del cuadro enseña el laboratorio macabro y el cuadro macabro; el glifo del retrato aparece sobre el cuadro normal al resolverla).
## Cámara 2: pasillo (mancha; el glifo de la mancha aparece trazado donde estaba, solo aquí).
## Cámara 3: SIN SEÑAL; parpadea y emite audio con susurros o con pitidos; con los pitidos, suenan tantos como estrellas tiene la constelación (no se dibuja nada).

const NOMBRES := {
	"1": "CAM 1 · LABORATORIO",
	"2": "CAM 2 · PASILLO",
	"3": "CAM 3 · SIN SEÑAL",
}
const COLORES := {
	"1": Color(0.05, 0.14, 0.1),
	"2": Color(0.05, 0.14, 0.1),
	"3": Color(0.02, 0.07, 0.04),
}
const FONDO_TEXTURA := {"1": "cam_1", "2": "cam_2"}
const VERDE := Color(0.45, 1.0, 0.65)  # verde del filtro de cámaras (el mismo tono que los monitores de Vigilancia)

var camara := "1"
var _t := 0.0
var _ruido := RandomNumberGenerator.new()
var _semilla_tiempo := 0.0
var _semilla := 1
var _destello := 0.0          # tiempo restante del destello actual en la cámara 3
var _destello_gris := false
var _proximo_destello := 0.0
var _audio_activo := false
var _pitidos_sonando := ""
var _oido := 0.0               # segundos mirando la estática de la cámara 3 mientras emite


func seleccionar(id: String) -> void:
	camara = id
	Sonido.reproducir("cambio_camara")
	_actualizar_audio()


func _exit_tree() -> void:
	Sonido.detener_bucle("susurro_fijo")
	_parar_pitidos()


func _process(delta: float) -> void:
	_t += delta
	_contar_pitidos(delta)
	if _t - _semilla_tiempo > 0.07:
		_semilla_tiempo = _t
		_semilla = randi()
	if camara == "3":
		_actualizar_destellos(delta)
	_actualizar_audio()
	queue_redraw()


func _anomalia_audio() -> bool:
	return Director.evento_de("voz") != null or Director.pitidos_activos()


func _pitidos_audibles() -> bool:
	return camara == "3" and Director.pitidos_activos() and not Director.terminal_ocupado()


func _parar_pitidos() -> void:
	if _pitidos_sonando != "":
		Sonido.detener_bucle(_pitidos_sonando)
		_pitidos_sonando = ""
	_oido = 0.0


func _contar_pitidos(delta: float) -> void:
	## El glifo solo cuenta si se mira la cámara 3 el tiempo suficiente mientras emite (los pitidos son ambiente).
	if not _pitidos_audibles():
		_parar_pitidos()
		return
	var nombre := "pitidos_%d" % Director.pitidos_cantidad()   # tantos pitidos como estrellas
	if _pitidos_sonando != nombre:
		_parar_pitidos()
		_pitidos_sonando = nombre
		Sonido.bucle(nombre, -4.0)
	_oido += delta
	if _oido >= Director.SEGUNDOS_ESTATICA:
		Director.pitidos_oidos()


func _actualizar_destellos(delta: float) -> void:
	_destello = maxf(0.0, _destello - delta)
	_proximo_destello -= delta
	if _proximo_destello <= 0.0:
		var activa := _anomalia_audio()
		_destello = randf_range(0.05, 0.3) if activa else randf_range(0.03, 0.08)
		_destello_gris = randf() < 0.5
		_proximo_destello = randf_range(0.1, 0.7) if activa else randf_range(2.0, 5.0)


func _actualizar_audio() -> void:
	## El audio de la cámara 3 solo se oye mientras se mira esa cámara.
	var voz := Director.evento_de("voz") != null
	var debe := camara == "3" and (voz or Director.fijas.has("voz")) and not Director.terminal_ocupado()
	if debe:
		Sonido.bucle("susurro_fijo", -6.0 if voz else -22.0)
	elif _audio_activo:
		Sonido.detener_bucle("susurro_fijo")
	_audio_activo = debe


func _draw() -> void:
	_ruido.seed = _semilla
	var fuente := ThemeDB.fallback_font
	# Terminal bloqueado
	if Director.terminal_ocupado():
		draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
		draw_string(fuente, Vector2(0, size.y / 2.0), "TERMINAL BLOQUEADO  (%d)" % int(ceil(Director.bloqueo)),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 36, Color(0.9, 0.2, 0.2))
		return
	if camara == "3":
		_dibujar_sin_senal()
		_dibujar_cabecera(fuente)
		return
	# Vista base
	var nombre_fondo: String = FONDO_TEXTURA[camara]
	if camara == "1" and Director.cuadro_en_camara():
		nombre_fondo = "cam_1_macabro"
	var textura := Recursos.fondo(nombre_fondo)
	if textura == null and nombre_fondo != FONDO_TEXTURA[camara]:
		textura = Recursos.fondo(FONDO_TEXTURA[camara])
	if textura != null:
		draw_texture_rect(textura, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), COLORES[camara])
		draw_string(fuente, Vector2(0, size.y - 30), "[vista provisional]", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(1, 1, 1, 0.25))
	if camara == "1":
		_dibujar_laboratorio(fuente)
	elif camara == "2":
		_dibujar_pasillo(fuente)
	var artefactos := EstadoJuego.compatibilidad >= Director.UMBRAL_ADVERTENCIA and _ruido.randf() < 0.05
	if artefactos:
		_dibujar_artefactos()
	_dibujar_ruido(0.12 + EstadoJuego.compatibilidad / 100.0 * 0.25)
	_dibujar_cabecera(fuente)


func _dibujar_cabecera(fuente: Font) -> void:
	draw_string(fuente, Vector2(14, 28), NOMBRES[camara], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.7, 1.0, 0.8))
	draw_string(fuente, Vector2(0, 28), "ACCESO: TECNICO_N01", HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, 18, Color(0.7, 1.0, 0.8, 0.8))
	if camara != "3" and int(_t * 2.0) % 2 == 0:
		draw_circle(Vector2(size.x - 24, size.y - 24), 7, Color(0.9, 0.1, 0.1))


func _dibujar_sin_senal() -> void:
	var fuente := ThemeDB.fallback_font
	var activa := _anomalia_audio()
	# Fondo: negro verdoso; durante un destello pasa a gris-verde brillante.
	var fondo := COLORES["3"]
	if _destello > 0.0:
		fondo = Color(0.16, 0.26, 0.2) if _destello_gris else Color(0.04, 0.4, 0.2)
		if activa and _ruido.randf() < 0.15:
			fondo = Color.BLACK
	draw_rect(Rect2(Vector2.ZERO, size), fondo)
	# Nieve: más densa y más brillante cuando hay anomalía.
	_dibujar_ruido(0.9 if activa else 0.35)
	if activa:
		for i in 6:
			var y := _ruido.randf() * size.y
			draw_rect(Rect2(0, y, size.x, 3.0 + _ruido.randf() * 14.0), Color(0.45, 1.0, 0.65, 0.12 + _ruido.randf() * 0.18))
	# Texto de error (parpadea; con anomalía se corta y desplaza).
	var visible := int(_t * 1.5) % 2 == 0
	var dx := 0.0
	if activa:
		visible = _ruido.randf() > 0.25
		dx = (_ruido.randf() - 0.5) * 30.0
	if visible:
		draw_string(fuente, Vector2(dx, size.y * 0.5), "SIN SEÑAL", HORIZONTAL_ALIGNMENT_CENTER, size.x, 54, VERDE)
		draw_string(fuente, Vector2(dx, size.y * 0.5 + 40), "ERROR DE ENLACE · CÓDIGO 0x05", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(VERDE, 0.7))
	if activa:
		# Barra de nivel de audio: el único dato que sigue llegando.
		var alto := 10.0 + 70.0 * absf(sin(_t * 7.0)) * (0.5 + _ruido.randf() * 0.5)
		draw_rect(Rect2(size.x * 0.5 - 20, size.y - 40 - alto, 40, alto), Color(0.4, 1.0, 0.6, 0.65))
		draw_string(fuente, Vector2(0, size.y - 18), "◉ SEÑAL DE AUDIO", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, VERDE)


func _dibujar_laboratorio(fuente: Font) -> void:
	var evento = Director.evento_de("cuadro")
	_dibujar_cuadro(Director.cuadro_en_camara())
	# La cámara avisa de una anomalía, pero no dice si es real o una lectura falsa.
	if evento != null and int(_t * 3.0) % 2 == 0:
		_marca_aviso(fuente, _centro_cuadro() + Vector2(size.x * 0.1, -size.y * 0.2))


func _marca_aviso(fuente: Font, marca: Vector2) -> void:
	draw_rect(Rect2(marca, Vector2(22, 22)), Color(0.95, 0.15, 0.15))
	draw_string(fuente, marca + Vector2(5, 18), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)


func _centro_cuadro() -> Vector2:
	var d: Dictionary = ZonasFondos.CAMARAS.get(camara, {})
	var c: Vector2 = d.get("cuadro_centro", Vector2(0.78, 0.42))
	return Vector2(size.x * c.x, size.y * c.y)


## El filtro verde de la cámara también afecta a lo que se superpone al feed: se convierte a monocromo verde.
static var _cache_verde := {}


static func _en_verde(textura: Texture2D, clave: String) -> Texture2D:
	if _cache_verde.has(clave):
		return _cache_verde[clave]
	var img := textura.get_image()
	if img == null:
		return textura
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var l := clampf(c.get_luminance() * 1.15, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.38 * l, 1.0 * l, 0.82 * l, c.a))
	var t := ImageTexture.create_from_image(img)
	_cache_verde[clave] = t
	return t


func _dibujar_cuadro(macabro: bool) -> void:
	var d: Dictionary = ZonasFondos.CAMARAS.get(camara, {})
	var ancho: float = size.x * d.get("cuadro_ancho", 0.15)
	var nombre := "cuadro_macabro" if macabro else "cuadro"
	var textura := Recursos.sprite(nombre)
	var alto := ancho * 0.7
	if textura != null:
		alto = ancho * textura.get_height() / textura.get_width()
	draw_set_transform(_centro_cuadro(), 0.0, Vector2.ONE)
	if textura != null:
		draw_texture_rect(_en_verde(textura, nombre), Rect2(-ancho / 2.0, -alto / 2.0, ancho, alto), false)
	else:
		draw_rect(Rect2(-ancho / 2.0, -alto / 2.0, ancho, alto), Color(0.55, 0.5, 0.4))
		draw_rect(Rect2(-ancho / 2.0 + 8, -alto / 2.0 + 8, ancho - 16, alto - 16), Color(0.2, 0.2, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# El glifo del laboratorio se ve sobre el cuadro una vez resuelta la anomalía.
	if EstadoJuego.glifo_visible("retrato") and not macabro:
		var c := _centro_cuadro()
		Glifos.dibujar(self, EstadoJuego.glifo_de("retrato"), Rect2(c.x - ancho * 0.36, c.y - alto * 0.36, ancho * 0.72, alto * 0.72),
			Color(0.7, 1.0, 0.75, 0.9), maxf(2.0, ancho * 0.02), 1.5)


func _centro_mancha() -> Vector2:
	var d: Dictionary = ZonasFondos.CAMARAS.get("2", {})
	var c: Vector2 = d.get("mancha_centro", Vector2(0.5, 0.88))
	return Vector2(size.x * c.x, size.y * c.y)


func _dibujar_pasillo(fuente: Font) -> void:
	var d: Dictionary = ZonasFondos.CAMARAS.get("2", {})
	var ancho: float = size.x * d.get("mancha_ancho", 0.14)
	var centro := _centro_mancha()
	if Director.mancha_en_camara():
		# La anomalía de la sangre es el fondo entero del pasillo también en esta cámara.
		var fondo_mancha := Recursos.fondo("pasillo_macabro")
		if fondo_mancha != null:
			draw_texture_rect(_en_verde(fondo_mancha, "pasillo_macabro"), Rect2(Vector2.ZERO, size), false)
		if Director.evento_de("mancha") != null and int(_t * 3.0) % 2 == 0:
			_marca_aviso(fuente, centro + Vector2(ancho * 0.6, -size.y * 0.12))
	elif EstadoJuego.glifo_visible("mancha"):
		# Trazado en el suelo donde estaba la mancha; solo se ve desde esta cámara. Cuadrado y de tamaño legible
		# (antes era un rectángulo pequeño de verde sobre verde, casi invisible con el filtro).
		var lado := ancho * 1.05
		Glifos.dibujar(self, EstadoJuego.glifo_de("mancha"), Rect2(centro.x - lado / 2.0, centro.y - lado * 0.85, lado, lado),
			Color(0.85, 1.0, 0.9, 1.0), maxf(4.0, ancho * 0.035), maxf(3.0, ancho * 0.03))


func _dibujar_ruido(fuerza: float) -> void:
	var n := int(60 * fuerza) + 4
	for i in n:
		var y := _ruido.randf() * size.y
		var x := _ruido.randf() * size.x
		var largo := 20.0 + _ruido.randf() * 200.0
		draw_rect(Rect2(x, y, largo, 1.0 + _ruido.randf() * 2.0), Color(1, 1, 1, _ruido.randf() * 0.25 * fuerza + 0.03))


func _dibujar_artefactos() -> void:
	for i in 5:
		var y := _ruido.randf() * size.y
		var desfase := (_ruido.randf() - 0.5) * 120.0
		draw_rect(Rect2(maxf(0.0, desfase), y, size.x - absf(desfase), 4.0 + _ruido.randf() * 8.0), Color(0.7, 1.0, 0.8, 0.22))
