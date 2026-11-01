extends SceneTree
## Guarda capturas de cada sala (necesita pantalla; con xvfb-run sirve en servidores).
## godot --path . --script res://pruebas/capturas.gd -- <carpeta_salida>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var salida: String = args[0] if args.size() > 0 else "/tmp"
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	estado.nueva_partida()
	var escena = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(escena)
	await create_timer(0.6).timeout
	for sala in ["recepcion", "recepcion_reverso", "pasillo", "vigilancia", "laboratorio", "oficina", "habitacion_secreta", "pasillo_alterado"]:
		escena._mostrar_sala(sala)
		await create_timer(0.5).timeout
		root.get_viewport().get_texture().get_image().save_png("%s/sala_%s.png" % [salida, sala])
	# Tras morir: a los 3 s Alicia se incorpora (fondo "sentada")
	estado.muertes = 1
	escena._mostrar_sala("habitacion_secreta")
	await create_timer(3.6).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/sala_habitacion_secreta_sentada.png" % salida)
	estado.muertes = 0
	# Primer clic en las cámaras: se consigue el detector
	escena._mostrar_sala("vigilancia")
	await create_timer(0.4).timeout
	escena._abrir_panel("camaras")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/detector_obtenido.png" % salida)
	escena._panel_abierto.cerrar()
	await create_timer(0.4).timeout
	escena._panel_abierto.cerrar()
	await create_timer(0.3).timeout
	# HUD nuevo: libreta abierta, mensaje sobre los botones, señales en el detector, pausa
	escena._mostrar_sala("vigilancia")
	director.forzar("cuadro")
	director.forzar("mancha")
	director.forzar("pitidos")
	estado.solicitar()
	root.get_node("Interfaz")._alternar_notas()
	root.get_node("Interfaz").mensaje("Un mensaje de prueba sobre los botones inferiores.", 20.0)
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/hud_vigilancia.png" % salida)
	root.get_node("Interfaz")._alternar_notas()
	escena._abrir_panel("ventana")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/hud_panel_ventana.png" % salida)
	escena._cerrar_panel()
	root.get_node("Interfaz").alternar_pausa()
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/hud_pausa.png" % salida)
	root.get_node("Interfaz").alternar_pausa()
	director.eventos.clear()
	director.pitidos_restante = 0.0
	estado.nueva_partida()
	# Anomalías nuevas en las salas
	director.numero_recepcion = true
	director.marca_restante = 0.0
	escena._mostrar_sala("recepcion")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/anom_recepcion_numero.png" % salida)
	director.silueta_visible = true
	director._silueta_restante = 60.0
	director.forzar("pitidos")
	director.forzar("voz")
	escena._mostrar_sala("vigilancia")
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/anom_vigilancia_silueta_hud.png" % salida)
	director.silueta_visible = false
	director.fijas["mancha"] = true
	escena._mostrar_sala("pasillo")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/anom_pasillo_mancha.png" % salida)
	director.fijas.erase("mancha")
	director.parpadeo_restante = 3.0
	escena._mostrar_sala("vigilancia")
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/anom_vigilancia_parpadeo.png" % salida)
	director.parpadeo_restante = 0.0
	director.eventos.clear()
	director.pitidos_restante = 0.0
	# paneles
	escena._mostrar_sala("vigilancia")
	director.forzar("cuadro")
	director.evento_de("cuadro").real = true
	await create_timer(0.4).timeout
	estado.obtener_detector()
	escena._abrir_panel("camaras")
	await create_timer(0.5).timeout
	escena._panel_abierto._elegir("1")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_1.png" % salida)
	escena._panel_abierto._elegir("2")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_2.png" % salida)
	director.forzar("mancha")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_2_mancha.png" % salida)
	director.eventos.clear()
	estado.visibles["mancha"] = 30.0
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_2_digito.png" % salida)
	escena._panel_abierto._elegir("1")
	director.eventos.clear()
	estado.visibles["retrato"] = 30.0
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_1_digito.png" % salida)
	director.forzar("voz")
	escena._panel_abierto._elegir("3")
	await create_timer(0.35).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_3_a.png" % salida)
	await create_timer(0.23).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_camara_3_b.png" % salida)
	director.silueta_visible = true
	director._silueta_restante = 30.0
	escena._panel_abierto.cerrar()
	await create_timer(0.2).timeout
	escena._abrir_panel("ventana")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_ventana_recepcion.png" % salida)
	escena._panel_abierto.cerrar()
	director.silueta_visible = false
	await create_timer(0.2).timeout
	escena._abrir_panel("ventana_secreta")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_ventana_secreta.png" % salida)
	escena._panel_abierto.cerrar()
	await create_timer(0.2).timeout
	# Último dígito: viento y manchas en el pasillo de la sala 5 (código 7 manchas)
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.codigo[i])
	estado.solicitar()
	estado.codigo[4] = 7
	escena._mostrar_sala("oficina")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/anom_oficina_viento_hud.png" % salida)
	escena._abrir_panel("ventana_secreta")
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_ventana_secreta_manchas.png" % salida)
	escena._panel_abierto.cerrar()
	await create_timer(0.2).timeout
	estado.nueva_partida()
	estado.solicitar()
	estado.confirmar(0, estado.codigo[0])
	estado.solicitar()
	escena._mostrar_sala("laboratorio")
	await create_timer(0.3).timeout
	escena._abrir_panel("terminal_lab")
	await create_timer(0.4).timeout
	escena._panel_abierto._archivos()
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_terminal_codigo.png" % salida)
	escena._panel_abierto.cerrar()
	await create_timer(0.2).timeout
	escena._mostrar_sala("laboratorio")
	estado.muertes = 1
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/sala_laboratorio_cuadro_girado_rojo.png" % salida)
	escena._mostrar_sala("habitacion_secreta")
	await create_timer(1.0).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/sala_habitacion_tumbado_rojo.png" % salida)
	await create_timer(3.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/sala_habitacion_levantandose_rojo.png" % salida)
	estado.ayuda_pitidos = true
	escena._funcion("mesita")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_mesita_nota.png" % salida)
	escena._panel_abierto.cerrar()
	await create_timer(0.2).timeout
	escena._abrir_panel("ficha_14b")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/panel_ficha_14b.png" % salida)
	escena._panel_abierto.cerrar()
	# Modo 3: sombra con botón AGACHARSE
	estado.modo_desbloqueado = 3
	estado.modo = 3
	estado.nueva_partida()
	escena._mostrar_sala("vigilancia")
	await create_timer(0.3).timeout
	director._iniciar_advertencia()
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/modo3_entidad_pasos.png" % salida)
	director.mantener(true)
	await create_timer(1.2).timeout
	director.mantener(false)
	estado.modo_desbloqueado = 3
	var tit = load("res://escenas/titulo.tscn").instantiate()
	escena.queue_free()
	root.add_child(tit)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/titulo_3_modos.png" % salida)
	tit.queue_free()
	estado.modo_desbloqueado = 1
	var tit1 = load("res://escenas/titulo.tscn").instantiate()
	root.add_child(tit1)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/titulo.png" % salida)
	tit1.queue_free()
	# Estrellas: dos conseguidas y las cinco con la línea de Casiopea.
	estado.estrellas = ["m1_bueno", "m2_malo"]
	estado.estrella_reciente = ""
	var tit2 = load("res://escenas/titulo.tscn").instantiate()
	root.add_child(tit2)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/titulo_2_estrellas.png" % salida)
	tit2.queue_free()
	estado.estrellas = estado.ESTRELLAS.duplicate()
	var tit3 = load("res://escenas/titulo.tscn").instantiate()
	root.add_child(tit3)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/titulo_5_estrellas.png" % salida)
	tit3.queue_free()
	# Final del modo 3: hoja tachada y texto de sangre.
	estado.modo_desbloqueado = 3
	estado.modo = 3
	estado.nueva_partida()
	var fin = load("res://escenas/final.tscn").instantiate()
	root.add_child(fin)
	await create_timer(3.2).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/final_modo3_tachando.png" % salida)
	await create_timer(5.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/final_modo3_sangre.png" % salida)
	quit()
