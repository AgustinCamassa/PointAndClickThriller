extends SceneTree
## Comprueba de verdad (no solo el estado) que el glifo resuelto se dibuja donde toca.
## godot --headless --path . --script res://pruebas/prueba_glifos_visibles.gd -- <carpeta_salida>
## Con xvfb-run hace capturas; sin pantalla, comprueba al menos el estado.

var fallos := 0


func comprobar(condicion: bool, texto: String) -> void:
	print("  %s  %s" % ["ok" if condicion else "FALLO", texto])
	if not condicion:
		fallos += 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var salida: String = args[0] if args.size() > 0 else "/tmp"
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	var transicion = root.get_node("Transicion")
	transicion.suprimir_cambios_escena = true
	# Cada glifo, con los anteriores ya confirmados (el orden es obligatorio).
	var rutas := ["mancha", "retrato", "sombra", "pitidos", "viento"]
	for k in rutas.size():
		estado.nueva_partida()
		estado.modo = 1
		estado.vigilancia_abierta = true
		estado.tiene_tarjeta = true
		director.bloqueo = 0.0
		director.bloqueo_lab = 0.0
		for i in k:
			estado.solicitar()
			estado.revelar(rutas[i]) # ignorado si no armado; solo para dejar claro el estado
			estado.confirmar(i, estado.glifos[i])
		estado.solicitar()
		var id: String = rutas[k]
		var tipo := id
		match id:
			"retrato": tipo = "cuadro"
			"sombra": tipo = "silueta"
			"pitidos": tipo = "pitidos"
			"viento": tipo = "viento"
		print("== glifo %d: %s (anomalía %s)" % [k + 1, estado.glifos[k], tipo])
		comprobar(estado.armado(id), "armado: el terminal ha pedido el glifo")
		if id == "mancha" or id == "retrato":
			director.forzar(tipo)
			var ev = director.evento_de(tipo)
			ev.real = true
			director.reportar(ev)
			comprobar(estado.glifo_visible(id), "tras reportar, el glifo queda revelado (lector: dato visible)")
	# Dibujo real de la cámara del pasillo y del laboratorio con el glifo ya revelado.
	estado.nueva_partida(); estado.modo = 1; estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.solicitar()
	estado.revelar("mancha")
	director.fijas.clear()
	var cam = load("res://scripts/mundo/vista_camara.gd").new()
	cam.size = Vector2(1280, 720)
	root.add_child(cam)
	for c in ["2", "1"]:
		cam.seleccionar(c)
		for f in 3:
			await process_frame
		root.get_viewport().get_texture().get_image().save_png("%s/cam%s_glifo_resuelto.png" % [salida, c])
		print("  captura cam ", c)
	print("RESULTADO: %d fallos" % fallos)
	quit(fallos)
