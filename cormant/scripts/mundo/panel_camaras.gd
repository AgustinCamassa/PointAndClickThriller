class_name PanelCamaras
extends PanelBase
## Terminal de vigilancia: tres monitores: laboratorio, pasillo y una cámara sin señal que solo emite audio.

var _vista: VistaCamara
var _botones := {}


static func crear() -> PanelCamaras:
	var p := PanelCamaras.new()
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
	_elegir("1")


func _elegir(id: String) -> void:
	if Director.terminal_ocupado():
		return
	_vista.seleccionar(id)
