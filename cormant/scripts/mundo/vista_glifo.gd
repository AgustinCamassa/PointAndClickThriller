class_name VistaGlifo
extends Control
## Control que dibuja un glifo (constelación) con Glifos.dibujar; sirve para el terminal, los paneles y la ventana del pasillo.

var glifo := "" :
	set(v):
		glifo = v
		queue_redraw()
var color := Color(0.7, 1.0, 0.75, 0.95)
var radio := 4.0
var grosor := 1.6
var fondo := Color(0, 0, 0, 0)
var textura_mancha: Texture2D = null
var tinte_mancha := Color.WHITE
var margen := 0.12      # fracción de la caja que se deja libre alrededor del dibujo


static func crear(glifo_: String, tam: Vector2) -> VistaGlifo:
	var v := VistaGlifo.new()
	v.glifo = glifo_
	v.custom_minimum_size = tam
	v.size = tam
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


func _draw() -> void:
	if fondo.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), fondo)
	var m := size * margen
	Glifos.dibujar(self, glifo, Rect2(m, size - m * 2.0), color, radio, grosor, textura_mancha, tinte_mancha)
