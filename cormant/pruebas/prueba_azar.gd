extends SceneTree
## Bot aleatorio: juega ~6 min simulados por partida (2 partidas por modo) con acciones al azar y busca errores de script.
## xvfb-run -a godot --path . --script res://pruebas/prueba_azar.gd   (tarda ~1,5 min; no debe aparecer ningún SCRIPT ERROR)
var ACCIONES := 0
func _initialize() -> void:
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	var transicion = root.get_node("Transicion")
	transicion.suprimir_cambios_escena = true
	estado.modo_desbloqueado = 3
	var salas := ["recepcion", "recepcion_reverso", "pasillo", "vigilancia", "laboratorio", "oficina"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for modo in [1, 2, 3]:
		estado.modo = modo
		for ronda in 2:
			estado.nueva_partida()
			var escena = load("res://escenas/escenario.tscn").instantiate()
			root.add_child(escena)
			await create_timer(0.3).timeout
			var muertes_vistas := 0
			for paso in 1400:
				estado._process(0.25)
				director._process(0.25)
				if paso % 4 == 0:
					await process_frame
				if not estado.jugando:
					if estado.muertes >= 2:
						estado.nueva_partida()
						escena._mostrar_sala("recepcion")
					else:
						estado.sala_actual = "habitacion_secreta"
						director.reanudar_tras_morir()
						estado.jugando = true
						escena._mostrar_sala("habitacion_secreta")
					continue
				if rng.randf() < 0.25:
					ACCIONES += 1
					var r := rng.randi_range(0, 9)
					match r:
						0, 1:
							if not transicion.ocupada and escena._panel_abierto == null:
								escena._viajar(salas[rng.randi_range(0, salas.size() - 1)])
						2, 3:
							if not transicion.ocupada:
								var hs: Array = DatosSalas.obtener(escena.sala_id).get("hotspots", [])
								if hs.size() > 0:
									escena._al_pulsar(hs[rng.randi_range(0, hs.size() - 1)])
						4:
							if escena._panel_abierto != null:
								escena._cerrar_panel()
						5:
							for e in director.eventos.duplicate():
								if rng.randf() < 0.5: director.reportar(e)
								else: director.descartar(e)
								break
						6:
							director.mantener(rng.randf() < 0.5)
						7:
							if director.silueta_visible and rng.randf() < 0.6: director.detener_entidad()
						8:
							if estado.puede_solicitar(): estado.solicitar()
							elif estado.glifos_completos() == false and estado.solicitados > estado.confirmados:
								var i: int = estado.confirmados
								estado.confirmar(i, estado.glifos[i] if rng.randf() < 0.7 else "cisne")
						9:
							for nombre in ["camaras", "terminal_lab", "ventana", "cuaderno", "libreta", "pin"]:
								if rng.randf() < 0.15 and escena._panel_abierto == null:
									escena._abrir_panel(nombre)
			while transicion.ocupada:
				await process_frame
			escena.queue_free()
			await process_frame
	print("FUZZ FIN acciones=", ACCIONES)
	quit()
