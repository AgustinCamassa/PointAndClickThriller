class_name PanelCorreo
extends PanelBase
## Ordenador de la recepción: correo con el PIN de la puerta de Vigilancia. La pantalla está rota y el 4.º número no se lee.
## Los tres primeros salen de la tira de sprites de dígitos (Digitos); la grieta se dibuja con líneas.

const PANTALLA := Rect2(190, 90, 900, 520)
const TAM_DIGITO := Vector2(56, 84)


static func crear() -> PanelCorreo:
	var p := PanelCorreo.new()
	p.es_ordenador = true
	p.titulo = "Ordenador de la recepción"
	return p


func _construir() -> void:
	var marco := ColorRect.new()
	marco.color = Color(0.1, 0.1, 0.11)
	marco.position = PANTALLA.position - Vector2(18, 18)
	marco.size = PANTALLA.size + Vector2(36, 36)
	contenido.add_child(marco)
	var pantalla := ColorRect.new()
	pantalla.color = Color(0.05, 0.1, 0.12)
	pantalla.position = PANTALLA.position
	pantalla.size = PANTALLA.size
	contenido.add_child(pantalla)
	_texto(Textos.CORREO_CABECERA, Vector2(40, 30), Vector2(820, 130), 18, Color(0.55, 0.85, 0.8))
	_texto(Textos.CORREO_CUERPO, Vector2(40, 170), Vector2(820, 110), 22, Color(0.75, 0.95, 0.9))
	# PIN: tres dígitos legibles y un cuarto tapado por la grieta.
	var origen := PANTALLA.position + Vector2(40, 320)
	var etiqueta := _texto("PIN:", Vector2(40, 345), Vector2(120, 40), 30, Color(0.75, 0.95, 0.9))
	etiqueta.add_theme_font_size_override("font_size", 30)
	for i in 4:
		var pos := origen + Vector2(130 + i * (TAM_DIGITO.x + 22), 0)
		if i < 3:
			var c := Digitos.casilla(EstadoJuego.pin[i], TAM_DIGITO)
			c.position = pos
			contenido.add_child(c)
	_texto(Textos.CORREO_PIE, Vector2(40, 440), Vector2(820, 60), 17, Color(0.45, 0.65, 0.65))
	# Cristal roto: el punto de impacto cae sobre la 4.ª casilla.
	var g := Grieta.new()
	g.position = PANTALLA.position
	g.size = PANTALLA.size
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.impacto = origen + Vector2(130 + 3 * (TAM_DIGITO.x + 22) + TAM_DIGITO.x / 2.0, TAM_DIGITO.y / 2.0) - PANTALLA.position
	g.radio_mancha = 52.0
	contenido.add_child(g)


func _texto(t: String, pos: Vector2, tam: Vector2, tamano: int, color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(tam.x, 0)
	l.position = PANTALLA.position + pos
	l.size = tam
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(l)
	return l
