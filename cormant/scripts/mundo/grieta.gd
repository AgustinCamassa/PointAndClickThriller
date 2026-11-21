class_name Grieta
extends Control
## Cristal roto dibujado con líneas (sin imágenes): grietas que parten de un punto de impacto y una mancha oscura opaca alrededor
## del impacto, que tapa lo que haya debajo. Se dibuja una sola vez (draw estático), no consume nada por fotograma.

var impacto := Vector2.ZERO          # relativo a este control
var radio_mancha := 40.0
var semilla := 7


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	# Mancha oscura irregular: tapa por completo lo que hay bajo el impacto.
	var contorno := PackedVector2Array()
	for i in 14:
		var ang := TAU * i / 14.0
		contorno.append(impacto + Vector2(cos(ang), sin(ang)) * radio_mancha * rng.randf_range(0.8, 1.15))
	draw_colored_polygon(contorno, Color(0.02, 0.025, 0.03))
	# Grietas radiales con quiebros, y algunas ramas.
	for i in 11:
		var ang := TAU * i / 11.0 + rng.randf_range(-0.2, 0.2)
		var p := impacto + Vector2(cos(ang), sin(ang)) * radio_mancha * 0.7
		var largo := rng.randf_range(90.0, 330.0)
		var pasos := 6
		for k in pasos:
			var q := p + Vector2(cos(ang), sin(ang)) * largo / pasos + Vector2(rng.randf_range(-7, 7), rng.randf_range(-7, 7))
			draw_line(p, q, Color(0.82, 0.88, 0.9, 0.75 - 0.08 * k), 1.5, true)
			if k == 2 and rng.randf() < 0.6:
				var rama := ang + rng.randf_range(0.5, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
				draw_line(q, q + Vector2(cos(rama), sin(rama)) * rng.randf_range(30, 80), Color(0.8, 0.86, 0.9, 0.5), 1.0, true)
			p = q
