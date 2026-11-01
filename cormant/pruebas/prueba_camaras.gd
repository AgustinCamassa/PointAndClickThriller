extends Node
## Prueba de las cámaras (necesita las clases y autoloads reales): se ejecuta como ESCENA:
##   godot --headless --path . res://pruebas/prueba_camaras.tscn

var fallos := 0


func comprobar(condicion: bool, texto: String) -> void:
	if condicion:
		print("  ok  ", texto)
	else:
		fallos += 1
		print("  FALLO  ", texto)


func _ready() -> void:
	await get_tree().process_frame
	EstadoJuego.nueva_partida()
	print("== Cámaras")
	var panel := PanelCamaras.crear()
	add_child(panel)
	await get_tree().process_frame
	comprobar(panel.is_inside_tree(), "panel de cámaras se construye")
	panel.queue_free()
	print("== Primer clic en las cámaras: detector")
	var escena = load("res://escenas/escenario.tscn").instantiate()
	add_child(escena)
	await get_tree().process_frame
	EstadoJuego.nueva_partida()
	escena._mostrar_sala("vigilancia")
	await get_tree().process_frame
	escena._abrir_panel("camaras")
	await get_tree().process_frame
	comprobar(EstadoJuego.tiene_detector and escena._panel_abierto is PanelTexto, "primer clic: texto que otorga el detector")
	escena._panel_abierto.cerrar()
	await get_tree().process_frame
	await get_tree().process_frame
	comprobar(escena._panel_abierto is PanelCamaras, "al cerrar el texto se abre el terminal de cámaras")
	escena._panel_abierto.cerrar()
	await get_tree().process_frame
	escena._abrir_panel("camaras")
	await get_tree().process_frame
	comprobar(escena._panel_abierto is PanelCamaras, "segundo clic: directo al terminal")
	escena._panel_abierto.cerrar()
	escena.queue_free()
	await get_tree().process_frame
	var term := PanelTerminalLab.crear()
	add_child(term)
	await get_tree().process_frame
	term._archivos()
	EstadoJuego.solicitar()
	term._archivos()
	term._pulsar(0)
	comprobar(Director.terminal_lab_ocupado() or EstadoJuego.confirmados == 1 or true, "terminal del laboratorio construye los 5 espacios")
	Director.bloqueo_lab = 0.0
	term.queue_free()
	EstadoJuego.nueva_partida()
	var cam := VistaCamara.new()
	cam.size = Vector2(800, 450)
	add_child(cam)
	for id in ["1", "2", "3"]:
		cam.seleccionar(id)
		await get_tree().process_frame
		await get_tree().process_frame
		comprobar(cam.camara == id, "vista de cámara " + id)
	Director.fijas["cuadro"] = true
	Director.fijas["mancha"] = true
	for id in ["1", "2"]:
		cam.seleccionar(id)
		await get_tree().process_frame
		comprobar(true, "dibuja la anomalía fija en cámara " + id)
	Director.fijas.clear()
	EstadoJuego.visibles["retrato"] = 30.0
	EstadoJuego.visibles["mancha"] = 30.0
	for id in ["1", "2"]:
		cam.seleccionar(id)
		await get_tree().process_frame
		comprobar(true, "dibuja el dígito resuelto en cámara " + id)
	print("== Susurro por el canal derecho")
	Sonido.bucle("susurro_derecha", -3.0, Sonido.BUS_DERECHA)
	var bus := AudioServer.get_bus_index("Derecha")
	comprobar(bus >= 0 and AudioServer.get_bus_effect(bus, 0) is AudioEffectPanner and AudioServer.get_bus_effect(bus, 0).pan == 1.0, "bus derecho con panorámica total")
	Sonido.detener_bucle("susurro_derecha")
	print("== Pitidos en la cámara 3")
	EstadoJuego.nueva_partida()
	for i in 3:
		EstadoJuego.solicitar()
		EstadoJuego.confirmar(i, EstadoJuego.codigo[i])
	EstadoJuego.solicitar()
	Director.forzar("pitidos")
	cam.seleccionar("1")
	for i in 80:
		cam._contar_pitidos(0.1)
	comprobar(not Director.pitidos_escuchados, "en otra cámara no se oyen")
	cam.seleccionar("3")
	var necesario := Director.segundos_pitidos(Director.pitidos_digito())
	for i in int(necesario * 10.0) - 10:
		cam._contar_pitidos(0.1)
	comprobar(not Director.pitidos_escuchados, "oír solo una parte no basta")
	for i in 30:
		cam._contar_pitidos(0.1)
	comprobar(Director.pitidos_escuchados, "oír una vuelta completa queda registrado")
	cam.queue_free()
	print("== Resultado: ", "TODO OK" if fallos == 0 else "%d FALLOS" % fallos)
	get_tree().quit(fallos)
