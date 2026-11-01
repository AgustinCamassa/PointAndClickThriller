extends Control
## Párrafo que se va tachando línea a línea con trazos gruesos de tinta roja (final del modo 3).
## No usa autoloads: recibe el texto y el ancho, y `tachado` (0..1) controla cuánto del tachado se ha dibujado.

var texto := ""
var ancho := 580.0
var tam_fuente := 20
var color_texto := Color(0.1, 0.08, 0.06)
var color_trazo := Color(0.55, 0.02, 0.03, 0.95)
var tachado := 0.0:
	set(v):
		tachado = v
		queue_redraw()

var _parrafo := TextParagraph.new()
var _lineas: Array = []   # [y, alto, ancho_linea] por cada línea
var _semilla := 7


func preparar(texto_: String, ancho_: float, tam_ := 20) -> void:
	texto = texto_
	ancho = ancho_
	tam_fuente = tam_
	_parrafo.clear()
	_parrafo.width = ancho
	_parrafo.add_string(texto, get_theme_default_font(), tam_fuente)
	_lineas.clear()
	var y := 0.0
	for i in _parrafo.get_line_count():
		var t := _parrafo.get_line_size(i)
		_lineas.append([y, t.y, _parrafo.get_line_width(i)])
		y += t.y
	custom_minimum_size = Vector2(ancho, y)
	size = Vector2(ancho, y)
	queue_redraw()


func numero_lineas() -> int:
	return _lineas.size()


func _draw() -> void:
	_parrafo.draw(get_canvas_item(), Vector2.ZERO, color_texto)
	var n := _lineas.size()
	if n == 0 or tachado <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _semilla
	var hecho := tachado * n
	for i in n:
		var avance := clampf(hecho - i, 0.0, 1.0)
		var l: Array = _lineas[i]
		if avance <= 0.0 or l[2] < 2.0:
			rng.randf()
			rng.randf()
			continue
		# Dos pasadas por línea, levemente torcidas, como un tachón hecho a mano.
		for pasada in 2:
			var y0: float = l[0] + l[1] * (0.5 + rng.randf_range(-0.12, 0.12))
			var y1: float = l[0] + l[1] * (0.5 + rng.randf_range(-0.12, 0.12))
			var x1: float = (l[2] + 10.0) * avance
			draw_line(Vector2(-4, y0), Vector2(x1, lerpf(y0, y1, avance)), color_trazo, 3.5 if pasada == 0 else 2.0, true)
