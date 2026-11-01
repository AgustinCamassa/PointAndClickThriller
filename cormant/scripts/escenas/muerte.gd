extends Control
## Primera muerte: pantalla negra con estática, el monitor de pulso se queda plano
## y se vuelve a la vida en la habitación secreta.

const DURACION := 6.0
var _t := 0.0
var _ruido := RandomNumberGenerator.new()
var _terminando := false


func _ready() -> void:
	Interfaz.activar(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sonido.reproducir("pitido_plano")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURACION and not _terminando:
		_terminando = true
		_despertar()


func _despertar() -> void:
	EstadoJuego.sala_actual = "habitacion_secreta"
	Director.reanudar_tras_morir()
	Transicion.ir_a_escena("res://escenas/escenario.tscn", 1.2)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	_ruido.seed = int(_t * 20.0)
	# Estática intensa al principio, que se apaga.
	var fuerza := clampf(1.0 - _t / 2.5, 0.0, 1.0)
	for i in int(300 * fuerza):
		var y := _ruido.randf() * size.y
		var x := _ruido.randf() * size.x
		draw_rect(Rect2(x, y, 10.0 + _ruido.randf() * 160.0, 2.0), Color(1, 1, 1, _ruido.randf() * 0.5))
	# Monitor de pulso: latidos que se espacian hasta la línea plana.
	var y0 := size.y * 0.5
	var puntos := PackedVector2Array()
	for px in range(0, int(size.x), 4):
		var tiempo_punto := _t - (size.x - px) / 300.0
		puntos.append(Vector2(px, y0 + _latido(tiempo_punto)))
	draw_polyline(puntos, Color(0.3, 1.0, 0.4), 3.0)


func _latido(t: float) -> float:
	if t < 0.0 or t > 3.0:
		return 0.0
	# Tres latidos cada vez más lentos y débiles.
	var fase := fmod(t, 1.0)
	var fuerza := 1.0 - t / 3.0
	if fase < 0.1:
		return -70.0 * fuerza * sin(fase / 0.1 * PI)
	return 0.0
