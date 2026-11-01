extends Control
## Casiopea en el cielo del título: una estrella por final alcanzado. Con las cinco aparece la línea blanca que las une.
## Posiciones reales (AR/Dec) de Segin, Ruchbah, Gamma, Schedar y Caph, de izquierda a derecha, en el orden en que se unen.
## No usa autoloads: el título le pasa los ids conseguidos.

## Orden de las estrellas = orden de ESTRELLAS en EstadoJuego (m1_bueno, m1_malo, m2_bueno, m2_malo, m3).
const IDS := ["m1_bueno", "m1_malo", "m2_bueno", "m2_malo", "m3"]
const POSICIONES := [
	Vector2(0.0, 0.0),        # Segin (ε Cas)
	Vector2(3.5, 3.5),        # Ruchbah (δ Cas)
	Vector2(7.15, 3.0),       # Gamma (γ Cas)
	Vector2(9.2, 7.2),        # Schedar (α Cas)
	Vector2(13.1, 4.5),       # Caph (β Cas)
]
const ESCALA := 17.0

var conseguidas: Array = []
var nueva := ""                   # estrella que aparece con fundido al entrar al título
var origen := Vector2(529, 22)
var _alfa := {}                   # id -> opacidad actual
var _linea := 0.0
var _t := 0.0


func configurar(ids: Array, nueva_ := "") -> void:
	conseguidas = ids.duplicate()
	nueva = nueva_
	for id in IDS:
		_alfa[id] = 1.0 if conseguidas.has(id) and id != nueva else 0.0
	_linea = 1.0 if completa() and nueva == "" else 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if nueva != "":
		var tween := create_tween()
		tween.tween_interval(0.8)
		tween.tween_method(func(v: float): _fijar(nueva, v), 0.0, 1.0, 2.0)
		if completa():
			tween.tween_interval(0.6)
			tween.tween_method(func(v: float): _linea = v, 0.0, 1.0, 3.0)
	queue_redraw()


func _fijar(id: String, v: float) -> void:
	_alfa[id] = v


func completa() -> bool:
	for id in IDS:
		if not conseguidas.has(id):
			return false
	return true


func posicion(i: int) -> Vector2:
	return origen + POSICIONES[i] * ESCALA


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# Línea: de estrella a estrella, en el orden de la constelación.
	if _linea > 0.0:
		var total := 4.0 * _linea
		for i in 4:
			var tramo := clampf(total - i, 0.0, 1.0)
			if tramo <= 0.0:
				break
			var a := posicion(i)
			var b := posicion(i + 1)
			draw_line(a, a.lerp(b, tramo), Color(1, 1, 1, 0.85), 1.6, true)
	for i in IDS.size():
		var alfa: float = _alfa.get(IDS[i], 0.0)
		if alfa <= 0.0:
			continue
		var p := posicion(i)
		var brillo := 0.85 + 0.15 * sin(_t * 1.7 + i * 1.9)
		var a := alfa * brillo
		draw_circle(p, 18.0, Color(0.75, 0.85, 1.0, 0.06 * a))
		draw_circle(p, 11.0, Color(0.8, 0.9, 1.0, 0.13 * a))
		draw_circle(p, 7.0, Color(0.9, 0.95, 1.0, 0.3 * a))
		draw_circle(p, 4.6, Color(1.0, 1.0, 1.0, a))
		draw_line(p + Vector2(-15, 0), p + Vector2(15, 0), Color(1, 1, 1, 0.6 * a), 1.4)
		draw_line(p + Vector2(0, -15), p + Vector2(0, 15), Color(1, 1, 1, 0.6 * a), 1.4)
