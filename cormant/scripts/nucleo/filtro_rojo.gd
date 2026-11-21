extends Control
## Filtro rojo (luz roja): un rojo apagado mezclado con negro y una pequeña viñeta en los bordes.
## `intensidad` va de 0 (nada) a 1 (completo).

var intensidad := 0.0:
	set(v):
		intensidad = clampf(v, 0.0, 1.0)
		_aplicar()

var _rojo: ColorRect
var _negro: ColorRect
var _vineta: TextureRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rojo = _capa()
	_negro = _capa()
	_vineta = TextureRect.new()
	_vineta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vineta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vineta.stretch_mode = TextureRect.STRETCH_SCALE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.7)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 144
	_vineta.texture = t
	add_child(_vineta)
	_aplicar()


func _capa() -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _aplicar() -> void:
	if _rojo == null:
		return
	_rojo.color = Color(0.5, 0.03, 0.02, 0.2 * intensidad)
	_negro.color = Color(0.0, 0.0, 0.0, 0.2 * intensidad)
	_vineta.modulate.a = intensidad
	visible = intensidad > 0.0
