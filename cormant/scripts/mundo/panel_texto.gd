class_name PanelTexto
extends PanelBase
## Panel con un texto (cuaderno, fragmentos, expedientes...).

var cuerpo := ""


static func crear(titulo_: String, cuerpo_: String) -> PanelTexto:
	var p := PanelTexto.new()
	p.titulo = titulo_
	p.cuerpo = cuerpo_
	return p


func _construir() -> void:
	var hoja := ColorRect.new()
	hoja.color = Color(0.86, 0.82, 0.7)
	hoja.position = Vector2(240, 100)
	hoja.size = Vector2(800, 540)
	contenido.add_child(hoja)
	var texto := Label.new()
	# Primero el ajuste de línea y el ancho; si se asigna el texto antes, el Label toma el ancho de una sola línea.
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(720, 0)
	texto.position = Vector2(280, 130)
	texto.size = Vector2(720, 480)
	texto.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	texto.add_theme_font_size_override("font_size", 20)
	texto.text = cuerpo
	contenido.add_child(texto)
