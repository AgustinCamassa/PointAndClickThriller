extends SceneTree
## Regresión: una muerte que ocurre dentro de un fundido (p. ej. durante un viaje entre salas) debe cargar la escena de muerte,
## no quedarse parada con el juego bloqueado.
## godot --headless --path . --script res://pruebas/prueba_muerte_transicion.gd

func _initialize() -> void:
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	var transicion = root.get_node("Transicion")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var escena = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(escena)
	await create_timer(0.5).timeout
	transicion.cambiar(func(): director.morir())
	await create_timer(3.0).timeout
	var nombres: Array = root.get_children().map(func(n): return n.name)
	var ok: bool = nombres.has(&"Muerte") and estado.muertes == 1 and not transicion.ocupada
	print("  ", "ok " if ok else "FALLO", " morir dentro de un fundido carga la escena de muerte ", nombres)
	print("== Resultado: ", "TODO OK" if ok else "FALLOS")
	quit()
