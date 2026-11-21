class_name PanelGlifo
extends PanelBase
## Panel con una nota y un glifo grande dibujado encima (el trazo del mostrador de la recepción).

var cuerpo := ""
var glifo := ""


static func crear(titulo_: String, cuerpo_: String, glifo_: String) -> PanelGlifo:
	var p := PanelGlifo.new()
	p.titulo = titulo_
	p.cuerpo = cuerpo_
	p.glifo = glifo_
	return p


func _construir() -> void:
	var hoja := ColorRect.new()
	hoja.color = Color(0.86, 0.82, 0.7)
	hoja.position = Vector2(240, 100)
	hoja.size = Vector2(800, 540)
	contenido.add_child(hoja)
	var texto := Label.new()
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(720, 0)
	texto.position = Vector2(280, 130)
	texto.size = Vector2(720, 90)
	texto.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	texto.add_theme_font_size_override("font_size", 20)
	texto.text = cuerpo
	contenido.add_child(texto)
	var v := VistaGlifo.crear(glifo, Vector2(420, 360))
	v.position = Vector2(430, 230)
	v.color = Color(0.45, 0.07, 0.07, 0.95)   # «algo que no es tinta»
	v.radio = 6.0
	v.grosor = 3.0
	v.rotation = deg_to_rad(-4.0)
	v.pivot_offset = v.size / 2.0
	contenido.add_child(v)
