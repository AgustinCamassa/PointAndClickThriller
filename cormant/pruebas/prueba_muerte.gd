extends SceneTree
## Flujo completo de muertes: partida -> 1ª muerte (habitación secreta) -> 2ª muerte (game over).
var fallos := 0
func comprobar(c: bool, t: String) -> void:
	if c: print("  ok  ", t)
	else:
		fallos += 1
		print("  FALLO  ", t)

func _initialize() -> void:
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	estado.invulnerable = true
	var titulo = load("res://escenas/titulo.tscn").instantiate()
	root.add_child(titulo)
	current_scene = titulo
	await process_frame
	comprobar(not estado.invulnerable, "el título apaga los trucos")
	titulo._nueva_partida(1)
	await create_timer(2.5).timeout
	comprobar(current_scene != null and current_scene.name == "Escenario", "Nueva partida lleva al escenario")
	comprobar(estado.sala_actual == "recepcion", "empieza en la recepción")
	estado.fijar_compatibilidad(65.0)
	director.morir()
	await create_timer(1.5).timeout
	comprobar(current_scene.name == "Muerte", "primera muerte -> escena de muerte")
	await create_timer(9.0).timeout
	comprobar(current_scene.name == "Escenario", "tras morir se vuelve al escenario")
	comprobar(estado.sala_actual == "habitacion_secreta", "despierta en la habitación secreta")
	comprobar(is_equal_approx(estado.compatibilidad, 60.0), "compatibilidad 60 % tras morir (modo 1)")
	comprobar(estado.jugando and estado.muertes == 1, "se puede seguir jugando")
	comprobar(estado.filtro_rojo(), "filtro rojo activo")
	current_scene._viajar("pasillo_alterado")
	await create_timer(2.5).timeout
	comprobar(estado.sala_actual == "pasillo_alterado", "sale por la puerta morada")
	current_scene._viajar("oficina")
	await create_timer(2.5).timeout
	comprobar(estado.sala_actual == "oficina", "la puerta azul lleva a la oficina")
	director.morir()
	await create_timer(1.5).timeout
	comprobar(current_scene.name == "GameOver", "segunda muerte -> game over")
	current_scene._reintentar()
	await create_timer(2.5).timeout
	comprobar(current_scene.name == "Escenario" and estado.muertes == 0 and estado.sala_actual == "recepcion", "reintentar reinicia la partida")
	print("== Resultado: ", "TODO OK" if fallos == 0 else "%d FALLOS" % fallos)
	quit(fallos)
