class_name PanelCuadro
extends PanelBase
## Vista ampliada del cuadro del laboratorio (normal o macabro): ocupa el 50 % de la pantalla, centrado.

var macabro := false


static func crear(macabro_: bool) -> PanelCuadro:
	var p := PanelCuadro.new()
	p.macabro = macabro_
	p.titulo = "Cuadro"
	return p


func _construir() -> void:
	var tr := TextureRect.new()
	tr.texture = Recursos.sprite("cuadro_macabro_zoom" if macabro else "cuadro_zoom")
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(640, 360)
	tr.position = Vector2(320, 180)   # 50 % de 1280x720, centrado
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(tr)
