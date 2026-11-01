class_name ZonaPoligono
extends Button
## Zona clicable con forma de polígono (puertas y objetos en perspectiva).
## Solo responde al ratón dentro del polígono. Con fondo real es invisible y se insinúa al pasar el ratón.

var poligono := PackedVector2Array()      # coordenadas locales
var insinuar := false


func _ready() -> void:
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _has_point(punto: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(punto, poligono)


func _draw() -> void:
	if insinuar and is_hovered() and poligono.size() >= 3:
		draw_colored_polygon(poligono, Color(1, 1, 1, 0.07))
		var cierre := poligono.duplicate()
		cierre.append(poligono[0])
		draw_polyline(cierre, Color(1, 1, 1, 0.3), 1.5)
