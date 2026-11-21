extends SceneTree
## Capturas de los fondos macabros. xvfb-run -a godot --path . --script res://pruebas/capturas_macabro.gd -- <carpeta>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var salida: String = args[0] if args.size() > 0 else "/tmp"
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var escena = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(escena)
	await create_timer(0.6).timeout
	var guardar := func(n: String) -> void:
		await create_timer(0.6).timeout
		root.get_viewport().get_texture().get_image().save_png("%s/m_%s.png" % [salida, n])
	# laboratorio con cuadro macabro
	director.fijas["cuadro"] = true
	director.emit_signal("anomalias_cambiadas") if director.has_signal("anomalias_cambiadas") else null
	escena._mostrar_sala("laboratorio"); escena._refrescar_anomalias()
	await guardar.call("laboratorio")
	escena._mostrar_sala("vigilancia"); await guardar.call("vigilancia_cuadro")
	director.fijas.erase("cuadro")
	# silueta
	director.silueta_visible = true
	for s in ["recepcion", "recepcion_reverso"]:
		escena._mostrar_sala(s); escena._refrescar_anomalias(); await guardar.call(s)
	director.silueta_visible = false
	# parpadeo
	director.parpadeo_restante = 5.0; director.parpadeo_cambiado.emit(true)
	escena._mostrar_sala("vigilancia"); await guardar.call("vigilancia")
	director.parpadeo_restante = 0.0; director.parpadeo_cambiado.emit(false)
	# glifo 5
	estado.solicitados = 5; estado.confirmados = 4; estado.glifos_cambiado.emit()
	escena._mostrar_sala("oficina"); await guardar.call("oficina")
	escena._abrir(PanelVentana.crear("secreta")); await guardar.call("panel_secreta")
	escena._panel_abierto.cerrar()
	quit()
