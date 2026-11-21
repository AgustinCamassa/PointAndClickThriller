extends SceneTree
## Prueba de humo (sin pantalla): godot --headless --path . --script res://pruebas/prueba_humo.gd
## Simula el paso del tiempo llamando a los _process a mano.

var fallos := 0

func comprobar(condicion: bool, texto: String) -> void:
	if condicion:
		print("  ok  ", texto)
	else:
		fallos += 1
		print("  FALLO  ", texto)

func avanzar(segundos: float, paso := 0.1) -> void:
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	var t := 0.0
	while t < segundos:
		estado._process(paso)
		director._process(paso)
		t += paso

func _initialize() -> void:
	await process_frame
	var estado = root.get_node("EstadoJuego")
	var director = root.get_node("Director")
	root.get_node("Transicion").suprimir_cambios_escena = true   # las muertes simuladas no cargan la escena de muerte
	print("== Bolsa y orden de eventos")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var vistos := []
	var anterior := ""
	var consecutivos := false
	director.evento_iniciado.connect(func(e): vistos.append(e.tipo))
	var intentos := 0
	# Evento 'silueta' no emite evento_iniciado; seguimos por ultimo_tipo.
	var secuencia := []
	var t := 0.0
	while t < 1800.0 and secuencia.size() < 30:
		estado._process(0.1)
		director._process(0.1)
		if director.ultimo_tipo != "" and director.desde_ultimo < 0.15:
			if secuencia.is_empty() or t - secuencia.back()[1] > 1.0:
				secuencia.append([director.ultimo_tipo, t])
		# Resolver al azar para que no se acumule todo
		for e in director.eventos.duplicate():
			if e.restante < 20.0:
				if e.real: director.reportar(e)
				else: director.descartar(e)
		if estado.compatibilidad > 55.0:
			estado.fijar_compatibilidad(10.0)
		t += 0.1
	var tipos := []
	for s in secuencia: tipos.append(s[0])
	print("  secuencia: ", tipos)
	comprobar(tipos.size() > 3 and tipos[0] == "cuadro", "primer evento es el cuadro")
	var repetido := false
	for i in range(1, tipos.size()):
		# El parpadeo puede repetirse si es lo único elegible (el límite de 15 s lo fuerza).
		if tipos[i] == tipos[i - 1] and tipos[i] != "parpadeo": repetido = true
	comprobar(not repetido, "nunca el mismo tipo dos veces seguidas (salvo parpadeo)")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var ordenada: Array = director.bolsa.duplicate()
	ordenada.sort()
	var esperada: Array = ["cuadro", "mancha", "parpadeo", "pitidos", "voz"]
	comprobar(ordenada == esperada, "la bolsa inicial no lleva la silueta (sale una de cada 2 rondas hasta pedir su glifo)")
	comprobar(director.bolsa[0] == "cuadro", "la primera de la bolsa es el cuadro")

	print("== Penalizaciones")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var c0: float = estado.compatibilidad
	director.forzar("voz")
	var ev = director.evento_de("voz")
	ev.real = false
	director.reportar(ev)
	comprobar(is_equal_approx(estado.compatibilidad, c0 + 5.0), "falsa alarma +5 %")
	comprobar(director.terminal_ocupado(), "terminal bloqueado")
	comprobar(director.gracia > 9.0, "10 s sin eventos tras error")
	director.bloqueo = 0.0
	director.forzar("cuadro")
	ev = director.evento_de("cuadro")
	ev.real = true
	director.descartar(ev)
	comprobar(is_equal_approx(estado.compatibilidad, c0 + 15.0), "real ignorada +10 %")
	comprobar(director.cuadro_macabro(), "el cuadro se queda macabro")
	var muertes0: int = estado.muertes
	director.entrar_sala("recepcion")
	comprobar(estado.muertes == muertes0, "entrar en la recepción nunca mata")

	print("== Cámaras y verificación")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.forzar("voz")
	ev = director.evento_de("voz")
	ev.real = true
	director.entrar_sala("oficina")
	comprobar(ev.pista.begins_with("Oficina comprobada: se oye"), "la oficina confirma el susurro real")
	ev.real = false
	director.entrar_sala("oficina")
	comprobar(ev.pista.ends_with("silencio."), "la oficina descarta el susurro falso")
	comprobar(not director.DESCRIPCION["voz"].is_empty() and director.DESCRIPCION["voz"].contains("CAM 3"), "la anomalía de audio apunta a la cámara 3")

	print("== Modo 1: la sombra suma 20 % y se muere al llegar a 100 %")
	estado.ruta_progreso = "user://prueba_progreso.cfg"
	estado.modo_desbloqueado = 3
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(is_equal_approx(director.duracion_evento(), 50.0) and director.maximo_activos() == 2, "modo 1: señales de 50 s y máximo 2 activas")
	comprobar(is_equal_approx(director.ventana_aviso(), 8.0) and is_equal_approx(director.ocultarse_necesario(), 5.0), "modo 1: esconderse 5 s de 8 s (un segundo más de margen)")
	estado.fijar_compatibilidad(70.0)
	director.proximo_aviso = 0.05
	avanzar(0.3)
	comprobar(director.advertencia_activa, "salta advertencia por encima de 60 %")
	director.mantener(true)
	avanzar(5.5)
	comprobar(not director.advertencia_activa and estado.jugando and is_equal_approx(estado.compatibilidad, 70.0), "mantener 5 s sobrevive")
	director.proximo_aviso = 0.05
	avanzar(0.3)
	director.mantener(false)
	avanzar(8.5)
	comprobar(estado.muertes == 0 and estado.jugando and is_equal_approx(estado.compatibilidad, 90.0), "no esconderse no mata: +20 %")
	director.proximo_aviso = 0.05
	avanzar(0.3)
	avanzar(8.5)
	comprobar(estado.muertes == 1 and not estado.jugando, "al llegar a 100 % se muere (muerte 1)")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.fijar_compatibilidad(95.0)
	estado.sumar_compatibilidad(10.0)
	avanzar(0.2)
	comprobar(estado.muertes == 1 and not estado.jugando, "100 % mata aunque no haya sombra")

	print("== Modo 2: sombra mortal, ventana a la mitad, 5 activas")
	estado.modo = 2
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(is_equal_approx(director.duracion_evento(), 35.0) and director.maximo_activos() == 5, "modo 2: 35 s y máximo 5 activas")
	comprobar(is_equal_approx(director.ventana_aviso(), 3.5) and is_equal_approx(director.ocultarse_necesario(), 2.5), "modo 2: ventana de 3,5 s y 2,5 s seguidos")
	estado.fijar_compatibilidad(70.0)
	director.proximo_aviso = 0.05
	avanzar(0.3)
	director.mantener(true)
	avanzar(2.8)
	comprobar(not director.advertencia_activa and estado.jugando, "modo 2: mantener 2,5 s sobrevive")
	director.proximo_aviso = 0.05
	avanzar(0.3)
	director.mantener(false)
	avanzar(4.0)
	comprobar(estado.muertes == 1 and not estado.jugando, "modo 2: no esconderse mata al instante")
	director.reanudar_tras_morir()
	comprobar(is_equal_approx(estado.compatibilidad, 80.0), "modo 2: reaparece con 80 %")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.muertes = 1
	director.reanudar_tras_morir()
	comprobar(is_equal_approx(estado.compatibilidad, 60.0), "modo 1: reaparece con 60 %")

	print("== Herramientas del desarrollador (G invulnerable, F +20 %)")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.invulnerable = true
	estado.sumar_compatibilidad(10.0)
	comprobar(is_equal_approx(estado.compatibilidad, 0.0), "invulnerable: las penalizaciones no suben la compatibilidad")
	estado.sumar_compatibilidad(20.0, true)
	comprobar(is_equal_approx(estado.compatibilidad, 20.0), "F suma 20 % aunque seas invulnerable")
	director.morir()
	comprobar(estado.jugando and estado.muertes == 0, "invulnerable: no se muere")
	estado.fijar_compatibilidad(100.0)
	avanzar(0.3)
	comprobar(estado.jugando and estado.muertes == 0, "invulnerable: ni siquiera al 100 %")
	estado.invulnerable = false
	avanzar(0.3)
	comprobar(not estado.jugando and estado.muertes == 1, "al desactivarla, vuelve el daño")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.invulnerable = true
	estado.desactivar_trucos()
	comprobar(not estado.invulnerable, "al volver al título se apaga la invulnerabilidad")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true

	print("== Modo 3: el parpadeo no suma, pero dura el doble")
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.fijar_compatibilidad(50.0)
	estado.sala_actual = "vigilancia"
	director.forzar("parpadeo")
	avanzar(0.3)
	comprobar(is_equal_approx(estado.compatibilidad, 50.0), "modo 3: el parpadeo no suma compatibilidad")
	comprobar(director.parpadeo_restante > 6.0, "modo 3: el parpadeo dura el doble (7 s)")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true

	print("== Modo 3: empieza al máximo, pasos de la entidad cada 4 anomalías en cualquier sala")
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(is_equal_approx(estado.compatibilidad, 99.0) and estado.filtro_rojo() and estado.tramo == 3, "modo 3: 99 %, modo rojo y último tramo")
	comprobar(director.maximo_activos() == 5 and is_equal_approx(director.duracion_evento(), 35.0), "modo 3: 35 s y 5 activas")
	comprobar(is_equal_approx(director.ventana_aviso(), 3.0) and is_equal_approx(director.ocultarse_necesario(), 1.0), "modo 3: ventana de 3 s y 1 s mantenido")
	director.proximo_aviso = 0.05
	avanzar(0.5)
	comprobar(not director.advertencia_activa, "modo 3: no hay sombra por el 60 %")
	estado.sala_actual = "pasillo"
	for i in 3:
		director.eventos.clear()
		director.silueta_visible = false
		director._crear("silueta")
	avanzar(0.3)
	comprobar(not director.advertencia_activa and director.anomalias_desde_sombra == 3, "modo 3: 3 anomalías (en cualquier sala), aún sin pasos")
	director.eventos.clear()
	director.silueta_visible = false
	director._crear("silueta")
	director.detener_entidad()   # aquí se prueba la sombra de advertencia, no el golpe de la silueta
	director._quitar_entidad()   # (sombra y entidad no atacan a la vez: la entidad ya terminó)
	avanzar(0.3)
	comprobar(director.advertencia_activa and director.aviso_restante > 2.0 and director.aviso_restante <= 3.0, "modo 3: la 4.ª anomalía, en el pasillo, trae a la entidad con 3 s")
	director.mantener(true)
	avanzar(0.6)
	comprobar(director.advertencia_activa, "modo 3: con 0,6 s mantenidos aún no basta")
	avanzar(0.6)
	comprobar(not director.advertencia_activa and estado.jugando, "modo 3: mantener 1 s dentro de la ventana la esquiva")
	director.mantener(false)
	for i in 4:
		director.eventos.clear()
		director.silueta_visible = false
		director._crear("silueta")
		director.detener_entidad()
	director._quitar_entidad()
	avanzar(0.3)
	comprobar(director.advertencia_activa, "modo 3: otras 4 anomalías, otra entidad")
	director.mantener(true)
	avanzar(0.5)
	director.mantener(false)    # suelta antes del segundo: se reinicia la cuenta de ocultación
	avanzar(3.0)
	comprobar(estado.muertes == 2 and not estado.jugando, "modo 3: no mantener 1 s seguido en 2 s es game over")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.anomalias_desde_sombra = 0
	director.eventos.clear()
	estado.sala_actual = "vigilancia"
	for i in 4:
		director.eventos.clear()
		director.silueta_visible = false
		director._crear("silueta")
		director.detener_entidad()
	director._quitar_entidad()
	avanzar(0.3)
	comprobar(director.advertencia_activa, "modo 3: también aparece estando en Vigilancia")
	director.mantener(true)
	avanzar(1.2)
	comprobar(not director.advertencia_activa and estado.jugando, "modo 3: en Vigilancia se esquiva igual")
	director.mantener(false)
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.sumar_compatibilidad(1.0)
	avanzar(0.2)
	comprobar(estado.muertes == 2 and not estado.jugando, "modo 3: llegar a 100 % es game over")

	print("== Desbloqueo de modos")
	DirAccess.remove_absolute("user://prueba_progreso.cfg")
	estado.modo_desbloqueado = 1
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(estado.superar_modo() == 2 and estado.modo_desbloqueado == 2, "superar el modo 1 desbloquea el 2")
	comprobar(estado.superar_modo() == 0, "volver a superar el 1 no desbloquea nada más")
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(estado.modo == 2, "no se puede jugar un modo bloqueado")
	estado.superar_modo()
	comprobar(estado.modo_desbloqueado == 3, "superar el modo 2 desbloquea el 3")
	estado.modo_desbloqueado = 1
	estado.cargar_progreso()
	comprobar(estado.modo_desbloqueado == 3, "el desbloqueo se guarda en disco")
	estado.modo_desbloqueado = 2
	estado.modo = 2
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.muertes = 1   # final malo (una muerte)
	comprobar(estado.superar_modo() == 3, "el final malo del modo 2 también desbloquea el 3")
	estado.modo_desbloqueado = 2
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.muertes = 0   # final bueno
	comprobar(estado.superar_modo() == 3, "el final bueno del modo 2 desbloquea el 3")
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.superar_modo()
	comprobar(estado.modo_desbloqueado == 3, "superar el 3 no desbloquea más")
	DirAccess.remove_absolute("user://prueba_progreso.cfg")
	estado.modo_desbloqueado = 1
	estado.modo = 1

	print("== Estrellas de Casiopea (una por final)")
	DirAccess.remove_absolute("user://prueba_progreso.cfg")
	estado.estrellas.clear()
	estado.modo_desbloqueado = 3
	var esperado := {[1, 0]: "m1_bueno", [1, 1]: "m1_malo", [2, 0]: "m2_bueno", [2, 1]: "m2_malo"}
	for clave in esperado:
		estado.modo = clave[0]
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		estado.muertes = clave[1]
		comprobar(estado.id_final() == esperado[clave], "id del final: " + esperado[clave])
		estado.superar_modo()
		comprobar(estado.estrellas.has(esperado[clave]) and estado.estrella_reciente == esperado[clave], "estrella ganada: " + esperado[clave])
	comprobar(estado.estrellas.size() == 4, "4 estrellas tras los finales de los modos 1 y 2")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.superar_modo()
	comprobar(estado.estrellas.size() == 4, "repetir un final no duplica la estrella")
	comprobar(estado.modos_superados_de([]) == 0 and estado.modos_superados_de(["m1_malo"]) == 1 and estado.modos_superados_de(["m1_bueno", "m1_malo", "m2_bueno"]) == 2 and estado.modos_superados_de(["m1_bueno", "m2_malo", "m3"]) == 3, "el cartel del título se aclara con cada modo superado (0–3)")
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(estado.estrella_reciente == "", "una partida nueva limpia la estrella reciente")
	estado.superar_modo()
	comprobar(estado.id_final() == "m3" and estado.estrellas.size() == 5, "el final único del modo 3 da la quinta estrella")
	estado.estrellas.clear()
	estado.cargar_progreso()
	comprobar(estado.estrellas.size() == 5 and estado.estrellas.has("m3"), "las estrellas se guardan en disco")
	var cons = load("res://scripts/escenas/constelacion.gd").new()
	cons.configurar(["m1_bueno", "m3"])
	comprobar(not cons.completa(), "sin las 5 no hay línea de constelación")
	cons.configurar(estado.estrellas)
	comprobar(cons.completa() and cons._linea == 1.0, "con las 5 la constelación se conecta")
	cons.free()
	DirAccess.remove_absolute("user://prueba_progreso.cfg")
	estado.estrellas.clear()
	estado.estrella_reciente = ""
	estado.modo_desbloqueado = 1
	estado.modo = 1

	print("== Glifos por orden")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(estado.glifos.size() == 5 and estado.glifos[4] == "andromeda", "5 glifos; el último es siempre Andrómeda")
	var ordenes := {}
	var todos_reales := true
	for k in 30:
		estado.nueva_partida()
		ordenes[",".join(estado.glifos)] = true
		var primeros: Array = estado.glifos.slice(0, 4)
		primeros.sort()
		todos_reales = todos_reales and primeros == ["geminis", "lira", "ofiuco", "orion"] and estado.glifos[4] == "andromeda"
	comprobar(todos_reales and ordenes.size() > 5, "los otros 4 glifos se sortean en cada partida (%d órdenes en 30 partidas) y Andrómeda no se mueve" % ordenes.size())
	estado.modo_desbloqueado = 3
	estado.modo = 2
	var pos_andromeda := {}
	var reales_ok := true
	for k in 60:
		estado.nueva_partida()
		pos_andromeda[estado.glifos.find("andromeda")] = true
		var todos: Array = estado.glifos.duplicate()
		todos.sort()
		reales_ok = reales_ok and todos == ["andromeda", "geminis", "lira", "ofiuco", "orion"]
	comprobar(reales_ok and pos_andromeda.size() > 2, "modos 2 y 3: Andrómeda cae en posiciones distintas (%d en 60 partidas)" % pos_andromeda.size())
	estado.modo = 1
	estado.modo_desbloqueado = 1
	estado.nueva_partida()
	estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(estado.puede_solicitar() and not estado.armado("mancha"), "al inicio solo se puede solicitar el primero")
	comprobar(not estado.confirmar(0, estado.glifos[0]), "no se confirma un glifo sin solicitarlo")
	comprobar(estado.solicitar() and estado.armado("mancha") and not estado.armado("sombra") and not estado.silueta_solicitada(), "solicitar el 1º arma solo el pasillo")
	comprobar(not estado.solicitar(), "no se solicita el siguiente sin confirmar el actual")
	comprobar(not estado.confirmar(0, ("cisne" if estado.glifos[0] != "cisne" else "leo")), "glifo equivocado rechazado")
	comprobar(estado.confirmar(0, estado.glifos[0]) and estado.confirmados == 1, "glifo correcto confirmado")
	comprobar(not estado.confirmar(2, estado.glifos[2]), "no se salta el orden")
	var c_cod: float = estado.compatibilidad
	director.glifo_erroneo()
	comprobar(is_equal_approx(estado.compatibilidad, c_cod + 5.0) and director.terminal_lab_ocupado(), "error de glifo: +5 % y bloqueo")
	comprobar(is_equal_approx(director.bloqueo_lab, 30.0), "modo 1: bloqueo de 30 s")
	comprobar(estado.confirmados == 0 and estado.solicitados == 1, "error de glifo: lo confirmado vuelve a 0 y lo desbloqueado sigue desbloqueado")
	avanzar(29.0)
	comprobar(director.terminal_lab_ocupado(), "a los 29 s sigue bloqueado")
	avanzar(2.0)
	comprobar(not director.terminal_lab_ocupado(), "el bloqueo del terminal termina a los 30 s")
	comprobar(estado.confirmar(0, estado.glifos[0]) and estado.confirmados == 1, "tras el bloqueo se vuelve a introducir el glifo")
	print("== Error de glifo por modo y reinicio total")
	estado.modo_desbloqueado = 3
	for par in [[1, 30.0, 5.0], [2, 45.0, 5.0], [3, 60.0, 0.0]]:
		estado.modo = par[0]
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		estado.fijar_compatibilidad(50.0 if par[0] < 3 else 90.0)
		for i in 3:
			estado.solicitar()
			estado.confirmar(i, estado.glifos[i])
		estado.solicitar()
		var antes: float = estado.compatibilidad
		director.glifo_erroneo()
		comprobar(is_equal_approx(director.bloqueo_lab, par[1]), "modo %d: bloqueo de %d s" % [par[0], int(par[1])])
		comprobar(is_equal_approx(estado.compatibilidad, antes + par[2]), "modo %d: +%d %% al equivocarse" % [par[0], int(par[2])])
		comprobar(estado.confirmados == 0 and estado.solicitados == 4, "modo %d: los 3 confirmados vuelven a 0 y los 4 desbloqueados siguen" % par[0])
		director.bloqueo_lab = 0.0
	estado.modo = 1
	estado.modo_desbloqueado = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true

	print("== Habitación secreta: sin anomalías (salvo parpadeo y entidad)")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.sala_actual = "habitacion_secreta"
	estado.tramo = 3
	director.gracia = 0.0
	director.proximo = 0.1
	director.desde_parpadeo = 999.0
	estado.fijar_compatibilidad(20.0)
	var visto_otra := false
	for i in 1500:
		director._process(0.1)
		if not director.eventos.is_empty() or director.silueta_visible or director.pitidos_activos():
			visto_otra = true
	comprobar(not visto_otra, "en la habitación no surge ninguna anomalía de señal, silueta ni pitidos")
	comprobar(director.parpadeo_pendiente, "el parpadeo sí puede quedar pendiente en la habitación")
	estado.sala_actual = "pasillo"
	director.proximo = 0.1
	director.gracia = 0.0
	for i in 200:
		director._process(0.1)
	comprobar(not director.eventos.is_empty() or director.silueta_visible or director.pitidos_activos() or director.parpadeo_pendiente, "al salir de la habitación vuelven las anomalías")
	estado.sala_actual = "habitacion_secreta"
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.sala_actual = "habitacion_secreta"
	estado.fijar_compatibilidad(60.0)
	director.proximo_aviso = 0.05
	director._process(0.1)
	comprobar(director.advertencia_activa, "la entidad sí puede aparecer en la habitación secreta")
	director.mantener(true)
	avanzar(6.0)
	comprobar(not director.advertencia_activa and estado.jugando, "en la habitación hay que esconderse y se puede")
	director.mantener(false)
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true

	print("== Botón Volver: sala anterior")
	var salas = load("res://scripts/nucleo/datos_salas.gd")
	comprobar(salas.volver_a("pasillo") == "recepcion" and salas.volver_a("vigilancia") == "pasillo", "volver desde pasillo y vigilancia")
	comprobar(salas.volver_a("laboratorio") == "pasillo" and salas.volver_a("oficina") == "laboratorio", "volver desde laboratorio y oficina")
	comprobar(salas.volver_a("recepcion") == "" and salas.volver_a("habitacion_secreta") == "" and salas.volver_a("pasillo_alterado") == "", "sin vuelta atrás en el inicio, la habitación y el pasillo alterado")

	print("== Libreta de objetivos y detector de señales")
	var interfaz = root.get_node("Interfaz")
	estado.nueva_partida()
	comprobar(interfaz._objetivo_actual().contains("PIN"), "libreta: al empezar, el primer objetivo es el PIN de Vigilancia")
	estado.abrir_vigilancia()
	comprobar(interfaz._objetivo_actual().contains("tarjeta de seguridad"), "libreta: sin tarjeta, el primer objetivo es encontrarla")
	estado.obtener_tarjeta()
	comprobar(interfaz._objetivo_actual().contains("solicitar el glifo 1"), "libreta: primer objetivo = solicitar el glifo 1")
	estado.solicitar()
	comprobar(interfaz._objetivo_actual().contains("buscar el glifo 1") and interfaz._objetivo_actual().contains("pasillo"), "libreta: con el glifo pedido indica dónde buscar")
	estado.visibles["mancha"] = 20.0
	comprobar(interfaz._objetivo_actual().contains("introducir"), "libreta: con el glifo a la vista, introducirlo")
	estado.visibles.clear()
	interfaz._refrescar_notas()
	comprobar(not interfaz._texto_notas.text.contains(Glifos.nombre(estado.glifos[0])) and interfaz._texto_notas.text.contains("OBJETIVOS"), "la libreta tiene objetivos y no revela ningún glifo")
	comprobar(not estado.tiene_detector and not interfaz._detector.visible, "detector: al empezar la partida no se tiene ni se ve")
	estado.obtener_detector()
	comprobar(estado.tiene_detector and interfaz._detector.visible, "detector: al conseguirlo se muestra")
	interfaz._refrescar_senales()
	comprobar(interfaz._senales.text == "Sin actividad", "detector: sin señales muestra «Sin actividad»")
	director.forzar("cuadro")
	director.forzar("pitidos")
	interfaz._refrescar_senales()
	comprobar(interfaz._senales.text.contains("CAM1 cuadro") and interfaz._senales.text.contains("CAM3 pitidos"), "detector: lista todas las anomalías activas en un solo sitio")
	# LEDs, aviso de señal nueva y botones propios del detector
	director.eventos.clear()
	director.pitidos_restante = 0.0
	interfaz._claves_previas = {}
	interfaz._animando_leds = false
	interfaz._refrescar_senales()
	estado.fijar_compatibilidad(0.0)
	interfaz._refrescar_senales()
	comprobar(interfaz._leds.size() == 9 and not interfaz._leds[0].visible and not interfaz._leds[8].visible, "detector: con 0 % todos los LEDs están apagados")
	director.forzar("cuadro")
	interfaz._refrescar_senales()
	var destello_visto := false
	var otros_vistos := false
	for k in 20:
		await create_timer(0.02).timeout
		destello_visto = destello_visto or interfaz._leds[0].visible
		otros_vistos = otros_vistos or interfaz._leds[1].visible
	comprobar(destello_visto and not otros_vistos, "detector: con 0 % una señal nueva hace parpadear solo el LED 1")
	await create_timer(0.9).timeout
	interfaz._refrescar_senales()
	comprobar(not interfaz._animando_leds and not interfaz._leds[0].visible, "detector: con 0 % tras parpadear el LED 1 queda apagado")
	director.eventos.clear()
	interfaz._claves_previas = {}
	estado.fijar_compatibilidad(35.0)
	await process_frame
	var n_on := 0
	for l in interfaz._leds:
		if l.visible: n_on += 1
	comprobar(n_on == 3 and interfaz._leds[2].visible and not interfaz._leds[3].visible, "detector: 35 % = 3 LEDs encendidos")
	director.forzar("cuadro")
	interfaz._refrescar_senales()
	await create_timer(0.9).timeout
	interfaz._refrescar_senales()
	comprobar(not interfaz._animando_leds and interfaz._leds[2].visible and not interfaz._leds[3].visible, "detector: tras avisar quedan los LEDs del nivel (3)")
	estado.fijar_compatibilidad(95.0)
	await process_frame
	comprobar(interfaz._leds[8].visible and interfaz._leds[7].visible, "detector: con 95 % está encendido el LED rojo")
	estado.fijar_compatibilidad(20.0)
	director.eventos.clear()
	interfaz._refrescar_senales()
	comprobar(not interfaz._leds[2].visible and interfaz._leds[1].visible, "detector: al bajar la compatibilidad se apagan los LEDs de más")
	director.forzar("cuadro")
	estado.sala_actual = "vigilancia"
	interfaz.activa = true
	interfaz._refrescar_menu()
	comprobar(not interfaz._boton_reportar.disabled and not interfaz._boton_descartar.disabled, "detector: en Vigilancia con señal se puede reportar y descartar")
	comprobar(interfaz._boton_reportar.visible and interfaz._boton_descartar.visible and interfaz._boton_siguiente.visible, "botones: aparecen los tres en Vigilancia con señal")
	comprobar(interfaz._boton_descartar.position.x < interfaz._boton_reportar.position.x and interfaz._boton_reportar.position.x < interfaz._boton_siguiente.position.x and interfaz._boton_descartar.position.y == interfaz._boton_reportar.position.y and interfaz._boton_descartar.position.y + interfaz._boton_descartar.size.y < interfaz._boton_volver.position.y, "botones: en fila, centrados y justo sobre Volver/Cerrar")
	comprobar(interfaz._texto_evento.text.contains("CAM 1"), "detector: el texto de la anomalía sale en el LCD")
	estado.sala_actual = "pasillo"
	interfaz._refrescar_menu()
	comprobar(interfaz._boton_reportar.disabled and interfaz._boton_descartar.disabled, "detector: fuera de Vigilancia los botones no valen")
	comprobar(not interfaz._boton_reportar.visible and not interfaz._boton_siguiente.visible, "botones: fuera de Vigilancia no se ven")
	director.eventos.clear()
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	comprobar(not estado.tiene_detector and not interfaz._detector.visible, "detector: se pierde al empezar otra partida")

	print("== Anomalías con glifo")
	for tipo in ["cuadro", "mancha"]:
		var id: String = director.FRAGMENTO_DE[tipo]
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		director.forzar(tipo)
		ev = director.evento_de(tipo)
		ev.real = false
		director.reportar(ev)
		comprobar(not estado.glifo_visible(id), "%s: reporte falso no da glifo" % tipo)
		director.bloqueo = 0.0
		director.forzar(tipo)
		ev = director.evento_de(tipo)
		ev.real = true
		director.reportar(ev)
		comprobar(not estado.glifo_visible(id), "%s: real pero sin solicitar no da glifo" % tipo)
		# Se pide el glifo de esa anomalía (hay que confirmar los anteriores)
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		for i in estado.ORDEN_FRAGMENTOS.find(id):
			estado.solicitar()
			estado.confirmar(i, estado.glifos[i])
		estado.solicitar()
		director.eventos.clear()
		director.forzar(tipo)
		ev = director.evento_de(tipo)
		ev.real = true
		director.reportar(ev)
		comprobar(estado.glifo_visible(id), "%s: real y solicitado da glifo" % tipo)
		avanzar(29.0)
		comprobar(estado.glifo_visible(id), "%s: el glifo sigue a los 29 s" % tipo)
		avanzar(2.0)
		comprobar(not estado.glifo_visible(id), "%s: el glifo se desvanece a los 30 s" % tipo)
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.forzar("mancha")
	ev = director.evento_de("mancha")
	ev.real = true
	director.descartar(ev)
	comprobar(director.fijas.has("mancha") and director.mancha_visible(), "mancha ignorada se queda")
	director.gracia = 0.0
	director.eventos.clear()
	director.bolsa = ["mancha"]
	director._crear(director._elegir_tipo())
	comprobar(director.evento_de("mancha") != null and director.evento_de("mancha").real, "mancha fija reaparece como real")
	director.reportar(director.evento_de("mancha"))
	comprobar(not director.fijas.has("mancha"), "resolver la fija la quita")

	print("== Prioridad de la anomalía del glifo solicitado")
	var nunca_primera := true
	var siempre_2_o_3 := true
	for intento in 60:
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		director.bolsa = ["cuadro", "silueta", "voz", "parpadeo", "pitidos", "mancha"]
		estado.solicitar()          # toca el pasillo → mancha
		var pos: int = director.bolsa.find("mancha")
		if pos == 0: nunca_primera = false
		if pos < 1 or pos > 2: siempre_2_o_3 = false
	comprobar(nunca_primera, "la anomalía del glifo pedido nunca es la primera")
	comprobar(siempre_2_o_3, "la anomalía del glifo pedido sale segunda o tercera")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.bolsa = ["voz", "cuadro", "mancha", "silueta", "pitidos", "parpadeo"]
	estado.solicitar()                 # pasillo → mancha (ya en 3.ª posición), no toca el resto
	comprobar(director.bolsa[0] == "voz" and director.bolsa[2] == "mancha", "pedir un glifo no toca el resto de la bolsa")
	director.bolsa = ["cuadro", "voz", "pitidos"]
	director.fijas.clear()
	estado.solicitados = 3
	director._rellenar_bolsa()
	comprobar(director.bolsa.find("silueta") != 0, "al rellenar la bolsa tampoco sale primera")

	print("== Nota del técnico (CAM 3): pista de los pitidos solo en modo 1, sin hace falta morir")
	estado.modo_desbloqueado = 3
	for caso in [[1, true, true], [1, false, false], [2, true, false], [3, true, false]]:
		estado.modo = caso[0]
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		if caso[1]:
			for i in 3:
				estado.solicitar()
				estado.confirmar(i, estado.glifos[i])
			estado.solicitar()          # 4.º (pitidos) pedido y sin resolver
		else:
			estado.solicitar()          # solo el 1.º
		comprobar(estado.pista_pitidos() == caso[2], "pista con modo %d, pitidos pedido=%s → %s" % [caso[0], str(caso[1]), str(caso[2])])
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	for i in 3:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	estado.solicitar()
	director.morir()
	comprobar(estado.pista_pitidos(), "tras morir con el glifo pedido, la pista sigue disponible")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	comprobar(not estado.pista_pitidos(), "sin pista si ya resolvió el glifo de la cámara 3")
	comprobar(Textos.nota_tecnico(false).contains("Llevé la cuenta") and not Textos.nota_tecnico(false).contains("pitidos"), "nota sin pista: sin mención a los pitidos")
	comprobar(Textos.nota_tecnico(true).contains("cuántas veces"), "nota con pista de los pitidos")

	print("== Sombra y entidad no atacan a la vez; morir escondiéndose limpia el aviso")
	estado.modo = 1
	estado.nueva_partida(); estado.jugando = true
	estado.fijar_compatibilidad(80.0)
	director.advertencia_activa = false
	director.silueta_visible = true
	director.proximo_aviso = 0.01
	director._actualizar_entidad(1.0)
	comprobar(not director.advertencia_activa, "con la entidad en la ventana, la sombra espera")
	director.silueta_visible = false
	director._actualizar_entidad(0.1)
	comprobar(director.advertencia_activa, "al terminar la entidad, la sombra ataca")
	estado.sala_actual = "vigilancia"
	director.bolsa = ["silueta"]
	comprobar(director._elegir_tipo() == "", "con la sombra en curso no aparece la entidad de la ventana")
	var terminada := [false]
	director.advertencia_terminada.connect(func(_s): terminada[0] = true)
	director.manteniendo = true
	director.morir()
	comprobar(terminada[0] and not director.advertencia_activa and not director.manteniendo, "morir con ocultarse activo recoge el aviso y la barra")
	director.advertencia_activa = false
	estado.modo = 3
	estado.nueva_partida(); estado.jugando = true
	director.silueta_visible = true
	director.anomalias_desde_sombra = estado.SOMBRA_CADA
	estado.sala_actual = "vigilancia"
	director._actualizar_sombra_pasos()
	comprobar(not director.advertencia_activa and director.anomalias_desde_sombra == estado.SOMBRA_CADA, "modo 3: la sombra con la entidad presente espera sin perder la cuenta")
	director.silueta_visible = false
	director._actualizar_sombra_pasos()
	comprobar(director.advertencia_activa, "modo 3: ataca cuando la entidad termina")
	director.advertencia_activa = false
	estado.modo = 1
	estado.nueva_partida()

	print("== Pasillo manchado: puertas en su sitio")
	for z in ["puerta_vigilancia", "puerta_bloq1", "puerta_bloq2", "puerta_lab"]:
		comprobar(not ZonasFondos.poligono("pasillo_macabro", z).is_empty() and ZonasFondos.poligono("pasillo_macabro", z) != ZonasFondos.poligono("pasillo", z), "zona %s propia del fondo manchado" % z)

	print("== Documento final por bloques")
	var tapado: String = Textos.tapar(Textos.BLOQUE_B)
	comprobar(tapado.length() == Textos.BLOQUE_B.length() and tapado.contains("▒") and not tapado.contains("PARCIAL") and tapado.contains(" ..."), "tapar: letras a ▒ respetando espacios y puntos")
	comprobar(Textos.tapar(Textos.BLOQUE_A, 2).begins_with("CORMANT MEDICAL SYSTEMS\nHOJA DE SESIÓN · USO INTERNO\n"), "tapar: conserva las dos primeras líneas")
	var d1b: Array = Textos.documento(1, false)
	comprobar(d1b.size() == 2 and d1b[0]["texto"] == Textos.BLOQUE_A and d1b[1]["texto"] != Textos.BLOQUE_B, "modo 1 bueno: A legible, B tapado")
	var d1m: Array = Textos.documento(1, true)
	comprobar(d1m.size() == 3 and d1m[0]["texto"] != Textos.BLOQUE_A and d1m[1]["texto"] == Textos.BLOQUE_B and d1m[2]["rojo"], "modo 1 malo: A tapado, B legible, C en rojo")
	var d2b: Array = Textos.documento(2, false)
	comprobar(d2b.size() == 4 and not d2b[1].has("nota"), "modo 2 bueno: A, D, B, E sin nota roja")
	var d2m: Array = Textos.documento(2, true)
	comprobar(d2m.size() == 5 and d2m[1].has("nota") and d2m[4]["rojo"], "modo 2 malo: añade la nota roja y el bloque C")
	for modo_final in [1, 2]:
		for malo_final in [false, true]:
			estado.modo = modo_final
			estado.nueva_partida()
			estado.muertes = 1 if malo_final else 0
			var fin = load("res://escenas/final.tscn").instantiate()
			root.add_child(fin)
			await process_frame
			comprobar(fin._hoja != null and fin._rojas.size() == (0 if modo_final == 1 and not malo_final else (1 if modo_final == 1 else (2 if malo_final else 0))), "hoja final modo %d malo=%s: tinta roja correcta" % [modo_final, str(malo_final)])
			fin.queue_free()
			await process_frame
	estado.modo = 1
	estado.nueva_partida()

	print("== Muerte: el terminal vuelve a 0 pero lo desbloqueado sigue")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	for i in 3:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	estado.solicitar()                 # 4º pedido, sin confirmar
	estado.reiniciar_terminal()
	comprobar(estado.confirmados == 0 and estado.solicitados == 4, "tras morir: 0 introducidos, 4 siguen desbloqueados")
	comprobar(estado.armado("mancha") and not estado.puede_solicitar(), "hay que reintroducir antes de pedir más")
	comprobar(not estado.confirmar(0, ("cisne" if estado.glifos[0] != "cisne" else "leo")), "reintroducir mal se rechaza")
	for i in 4:
		comprobar(estado.confirmar(i, estado.glifos[i]), "reintroducir el glifo %d" % (i + 1))
	comprobar(estado.confirmados == 4 and estado.puede_solicitar(), "reintroducidos los 4, se puede solicitar el siguiente")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	comprobar(estado.quinto_disponible(), "con 4 confirmados, el 5º está disponible (susurro a la derecha)")
	estado.solicitar()
	estado.confirmar(4, estado.glifos[4])
	comprobar(not estado.quinto_disponible() and estado.glifos_completos(), "completo: ya no susurra")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.solicitar()
	director.forzar("silueta")
	estado.reiniciar_terminal()
	comprobar(estado.visibles.is_empty(), "al morir, los datos a la vista desaparecen")

	print("== Pitidos")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.forzar("pitidos")
	comprobar(director.pitidos_activos() and director.pitidos_restante > 25.0, "pitidos activos ~30 s")
	var real: String = estado.glifo_de("pitidos")
	comprobar(director.pitidos_glifo() != real and Glifos.PALETA.has(director.pitidos_glifo()), "sin solicitar suenan los pitidos de un señuelo")
	comprobar(director.pitidos_cantidad() != Glifos.estrellas(real), "sin solicitar, la cuenta de pitidos no es la real")
	for i in 3:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	estado.solicitar()
	comprobar(director.pitidos_cantidad() == Glifos.estrellas(real) and director.pitidos_cantidad() >= 4 and director.pitidos_cantidad() <= 9, "solicitado, suenan tantos pitidos como estrellas")
	director.pitidos_oidos()
	comprobar(director.pitidos_escuchados, "oír los pitidos queda registrado")
	estado.reiniciar_terminal()
	comprobar(director.pitidos_cantidad() == Glifos.estrellas(real), "pedido el glifo, sigue siendo el real aunque se reinicie el terminal")
	for k in 5:
		director.glifo_erroneo(0)
	comprobar(estado.glifo_de("pitidos") == real, "fallar otro puzzle no cambia el glifo de la CAM 3")
	for g in Glifos.PALETA:
		comprobar(Glifos.estrellas(g) >= 4 and Glifos.estrellas(g) <= 9, "constelación %s con 4 a 9 estrellas" % g)
	var antes: String = real
	director.glifo_erroneo(estado.ORDEN_FRAGMENTOS.find("pitidos"))
	comprobar(estado.glifo_de("pitidos") != antes and not director.pitidos_escuchados, "fallar el de la CAM 3 cambia su glifo y obliga a volver a oír")
	comprobar(director.SEGUNDOS_ESTATICA > 0.0, "tiempo mínimo mirando la estática")
	for n in range(4, 10):
		comprobar(root.get_node("Recursos").audio("pitidos_%d" % n) != null, "audio pitidos_%d" % n)
	avanzar(31.0)
	comprobar(not director.pitidos_activos(), "los pitidos caducan")

	print("== Silueta y glifo de recepción")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.sala_actual = "vigilancia"
	comprobar(not estado.silueta_solicitada(), "al inicio no se ha pedido el glifo de la silueta")
	director.forzar("silueta")
	comprobar(director.silueta_visible and is_equal_approx(director._silueta_restante, 2.5), "sin pedir su glifo, cada fase dura el doble (2,5 s)")
	director.detener_entidad()
	avanzar(2.0)
	comprobar(not director.silueta_visible and not director.glifo_recepcion_visible(), "esquivarla sin haber pedido su glifo no deja nada")
	comprobar(director.entidad_apariciones == 0, "las apariciones previas no aceleran a la entidad")
	for i in 2:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	comprobar(not estado.silueta_solicitada(), "con 2 glifos confirmados aún no se ha pedido el de la silueta")
	estado.solicitar()
	comprobar(estado.silueta_solicitada() and estado.armado("sombra"), "al pedir el 3.º se pide el glifo de la silueta")
	director.silueta_visible = false
	director.forzar("silueta")
	comprobar(is_equal_approx(director._silueta_restante, 1.25), "pedido su glifo, la entidad va a su velocidad normal (1,25 s por fase)")
	comprobar(not director.glifo_recepcion_visible(), "el glifo no está hasta esquivar la silueta")
	director.entrar_sala("recepcion")
	comprobar(estado.muertes == 0, "entrar en la recepción no mata")
	director.silueta_visible = false
	director.forzar("silueta")
	director.detener_entidad()
	comprobar(director.glifo_recepcion_visible(), "esquivada la silueta, el glifo se ve en el mostrador")
	avanzar(2.0)
	var m_rec: int = estado.muertes
	director.entrar_sala("recepcion")
	comprobar(estado.muertes == m_rec and director.glifo_recepcion_visible(), "tras esquivarla se puede entrar en la recepción sin daño")
	avanzar(31.0)
	comprobar(not director.glifo_recepcion_visible(), "el glifo se desvanece a los 30 s")
	# Daño: mitad antes de pedir su glifo
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.sala_actual = "vigilancia"
	estado.fijar_compatibilidad(0.0)
	director.forzar("silueta")
	avanzar(8.0)
	comprobar(not director.silueta_visible and is_equal_approx(estado.compatibilidad, 20.0), "sin pedir su glifo: la entidad hace 20 %")
	# Frecuencia: una de cada 2 rondas antes de pedir el glifo, todas después
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var con_silueta := 0
	for k in 8:
		director._rellenar_bolsa()
		if director.bolsa.has("silueta"): con_silueta += 1
	comprobar(con_silueta == 4, "sin pedir su glifo, la silueta está en 1 de cada 2 rondas (%d de 8)" % con_silueta)
	estado.solicitados = 3
	con_silueta = 0
	for k in 8:
		director._rellenar_bolsa()
		if director.bolsa.has("silueta"): con_silueta += 1
	comprobar(con_silueta == 8, "pedido su glifo, la silueta sale en todas las rondas")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.bolsa = ["cuadro", "voz"]
	for i in 2:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	estado.solicitar()
	comprobar(director.bolsa.has("silueta") and director.bolsa.find("silueta") in [1, 2], "al pedir su glifo, la silueta entra en la ronda en curso")

	# Fuera del rodaje (modos 2 y 3, o tras reaparecer en el modo 1) la silueta va siempre a su ritmo normal
	estado.modo_desbloqueado = 3
	for m in [2, 3]:
		estado.modo = m
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		comprobar(not estado.silueta_en_rodaje() and director.bolsa.has("silueta"), "modo %d: sin rodaje, la silueta está en la bolsa desde el principio" % m)
		director.silueta_visible = false
		director.forzar("silueta")
		var fase_esperada: float = float(estado.cfg("entidad_fase"))
		comprobar(is_equal_approx(director._silueta_restante, fase_esperada), "modo %d: fase de %.3f s (sin duplicar)" % [m, fase_esperada])
		director.detener_entidad(); avanzar(2.0)
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	director.entidad_apariciones = 20
	director.silueta_visible = false
	director.forzar("silueta")
	comprobar(is_equal_approx(director._silueta_restante, 0.6667 * 0.65), "modo 3: aunque acorte (65 %), cada fase dura 0,433 s (1,3 s en total)")
	director.detener_entidad(); avanzar(2.0)
	comprobar(absf(float(estado.MODOS[3]["entidad_fase"]) * 3.0 - 2.0) < 0.01, "modo 3: 2 s para reaccionar a la silueta")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.muertes = 1
	comprobar(not estado.silueta_en_rodaje(), "modo 1 tras reaparecer: la silueta ya no está en rodaje")
	director.silueta_visible = false
	director.forzar("silueta")
	comprobar(is_equal_approx(director._silueta_restante, 1.25), "modo 1 tras reaparecer: fase normal (1,25 s)")
	director.detener_entidad(); avanzar(2.0)
	estado.muertes = 0
	estado.modo = 1

	print("== Viento y manchas de la sala 5")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	comprobar(not director.viento_activo(), "sin solicitar el 5º no hay viento")
	estado.solicitar()
	comprobar(director.viento_activo(), "al solicitar el 5º suena el viento")
	comprobar(director.ver_manchas_viento() and director.manchas_viento_visibles() and not director.viento_activo(), "mirar por la ventana muestra las manchas")
	avanzar(31.0)
	comprobar(not director.manchas_viento_visibles() and not director.viento_activo(), "las manchas se desvanecen y el viento calla un rato")
	avanzar(41.0)
	comprobar(director.viento_activo(), "el viento vuelve para poder repetirlo")

	print("== Parpadeo inevitable")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.tramo = 2
	var c1: float = estado.compatibilidad
	director.forzar("parpadeo")
	comprobar(director.parpadeo_pendiente, "parpadeo queda pendiente")
	estado.sala_actual = "pasillo"
	avanzar(1.0)
	comprobar(is_equal_approx(estado.compatibilidad, c1), "no se aplica fuera de Vigilancia")
	estado.sala_actual = "vigilancia"
	avanzar(0.3)
	comprobar(is_equal_approx(estado.compatibilidad, c1 + 10.0) and director.parpadeo_restante > 0.0, "en Vigilancia: +10 % y parpadea")
	avanzar(5.0)
	comprobar(is_equal_approx(estado.compatibilidad, c1 + 10.0) and director.parpadeo_restante == 0.0, "solo penaliza una vez")

	print("== Partida simulada con jugador perfecto (glifos completos por orden)")
	for m in [1, 2, 3]:
		estado.modo = m
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		estado.sala_actual = "vigilancia"
		var seg := 0.0
		var visto := ""
		while seg < 1800.0 and not estado.glifos_completos():
			estado._process(0.1)
			director._process(0.1)
			seg += 0.1
			estado.fijar_compatibilidad(20.0)
			director.bloqueo = 0.0
			if director.advertencia_activa:
				director.mantener(true)
			# Terminal del laboratorio: si no hay nada pendiente, solicita el siguiente
			if estado.puede_solicitar():
				estado.solicitar()
			for e in director.eventos.duplicate():
				if e.restante < 30.0:
					if e.real: director.reportar(e)
					else: director.descartar(e)
			if director.pitidos_activos(): director.pitidos_oidos()
			if director.silueta_visible: director.detener_entidad()   # mira por la ventana: la entidad se detiene
			# Con el dato a la vista, lo confirma al instante
			var n: int = estado.confirmados
			if n < estado.NUM_GLIFOS:
				var id: String = estado.ORDEN_FRAGMENTOS[n]
				var disponible: bool = estado.glifo_visible(id)
				if id == "sombra":
					disponible = director.glifo_recepcion_visible()
				if id == "pitidos": disponible = director.pitidos_activos() and director.pitidos_escuchados
				if id == "viento":
					director.ver_manchas_viento()
					disponible = director.manchas_viento_visibles()
				if disponible:
					estado.confirmar(n, estado.glifos[n])
		print("  modo %d: glifos completos en %.0f s de juego (confirmados %d, solicitados %d, visibles %s, fijas %s, eventos %d)" % [m, seg, estado.confirmados, estado.solicitados, str(estado.visibles.keys()), str(director.fijas.keys()), director.eventos.size()])
		comprobar(estado.glifos_completos(), "con jugador perfecto se completa la secuencia")
		comprobar(seg < 1500.0, "se completa en menos de 25 min")

	print("== Escena de juego y paneles")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	var escena = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(escena)
	await process_frame
	for sala in ["recepcion", "recepcion_reverso", "pasillo", "vigilancia", "laboratorio", "oficina", "habitacion_secreta", "pasillo_alterado"]:
		escena._mostrar_sala(sala)
		await process_frame
		comprobar(escena.sala_id == sala, "sala " + sala)
	# Primer clic en las cámaras: texto que otorga el detector; al cerrarlo se abre el terminal. Después, directo.
	escena._mostrar_sala("vigilancia")
	await process_frame
	comprobar(not estado.tiene_detector, "sin detector antes del primer clic en las cámaras")
	escena._abrir_panel("camaras")
	await process_frame
	comprobar(estado.tiene_detector and escena._panel_abierto is PanelTexto, "primer clic en las cámaras: texto y detector conseguido")
	# (PanelCamaras no compila bajo --script; el resto del flujo se prueba en prueba_camaras.tscn.)
	escena._panel_abierto.queue_free()
	escena._panel_abierto = null
	root.get_node("Interfaz").set_panel_abierto(false)
	await process_frame
	for nombre in ["cuaderno", "ventana", "ventana_secreta", "terminal_lab"]:
		escena._abrir_panel(nombre)
		await process_frame
		await process_frame
		comprobar(escena._panel_abierto != null, "panel " + nombre)
		escena._panel_abierto.cerrar()
		await process_frame
	# Terminal del laboratorio: selector de glifos (se prueba la lógica de la casilla activa).
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.solicitar()
	escena._abrir_panel("terminal_lab")
	await process_frame
	var term = escena._panel_abierto
	term._archivos()
	await process_frame
	comprobar(term._valores[0] == -1 and term._nombres[0].text == "—", "terminal: la casilla activa empieza vacía")
	term._pulsar(0)
	comprobar(estado.confirmados == 0, "terminal: confirmar una casilla vacía no hace nada")
	var glifo_ok: String = estado.glifos[0]
	term._cambiar(0, 1)
	while Glifos.PALETA[term._valores[0]] != glifo_ok:
		term._cambiar(0, 1)
	term._pulsar(0)
	comprobar(estado.confirmados == 1 and term._mensaje.text.contains(Glifos.historia(glifo_ok)), "terminal: el glifo correcto se confirma y muestra su historia")
	term._pulsar(1)
	comprobar(estado.solicitados == 2, "terminal: se solicita el siguiente")
	term._cambiar(1, 1)
	var glifo_malo: String = estado.glifos[1]
	while Glifos.PALETA[term._valores[1]] == glifo_malo:
		term._cambiar(1, 1)
	term._pulsar(1)
	comprobar(director.terminal_lab_ocupado() and estado.confirmados == 0 and term._mensaje.text.begins_with("GLIFO INCORRECTO"), "terminal: un glifo equivocado bloquea y reinicia la secuencia")
	director.bloqueo_lab = 0.0
	escena._panel_abierto.cerrar()
	await process_frame
	# Glifo de recepción: limpio al principio; legible una vez esquivada la silueta.
	escena._mostrar_sala("recepcion")
	await process_frame
	escena._funcion("pc_senal")
	comprobar(escena._panel_abierto == null, "frente del mostrador limpio: sin glifo")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	for i in 2:
		estado.solicitar()
		estado.confirmar(i, estado.glifos[i])
	estado.solicitar()
	director.glifo_recepcion = true
	director.glifo_restante = 30.0
	escena._mostrar_sala("recepcion")
	await process_frame
	comprobar(escena._capa_anomalias.get_child_count() == 2, "el glifo aparece solo en la pantalla del ordenador 2 (pantalla + trazo)")
	escena._funcion("pc_senal")
	await process_frame
	comprobar(escena._panel_abierto != null, "leer el glifo abre su texto")
	escena._panel_abierto.cerrar()
	await process_frame
	# Silueta en la ventana de Vigilancia y mancha en el pasillo
	escena._mostrar_sala("habitacion_secreta")
	await process_frame
	escena._funcion("mesita")
	comprobar(escena._panel_abierto == null, "mesita: solo un mensaje (la nota del técnico ya no está aquí)")
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true; estado.obtener_detector()
	escena._mostrar_sala("vigilancia")
	await process_frame
	escena._abrir_panel("camaras")
	await process_frame
	var pc = escena._panel_abierto
	comprobar(pc != null and pc.has_method("_abrir_nota") and not pc._boton_nota.visible, "la hoja del técnico no se ve con CAM 1")
	pc._elegir("3")
	comprobar(pc._boton_nota.visible, "con la CAM 3 aparece la hoja bajo el monitor")
	pc._abrir_nota()
	comprobar(pc._papel_nota.visible and pc._texto_nota.text.contains("No sé de quién es esta letra") and not pc._texto_nota.text.contains("pitidos"), "la nota se lee sin la pista fuera del modo 1 / sin pedir el glifo")
	pc._elegir("2")
	comprobar(not pc._papel_nota.visible and not pc._boton_nota.visible, "al cambiar de cámara se cierra la hoja")
	pc.cerrar()
	await process_frame
	director.silueta_visible = true
	director.entidad_fase = 1
	director._silueta_restante = 30.0
	escena._mostrar_sala("vigilancia")
	await process_frame
	print("   hijos capa anomalías: ", escena._capa_anomalias.get_child_count(), " sala=", escena.sala_id, " vis=", director.silueta_visible)
	comprobar(escena._capa_anomalias.get_child_count() == 1, "la entidad aparece en el fondo de Vigilancia (recortada al cristal)")
	director.silueta_visible = false
	estado.modo = 1   # pasillo con la sangre en modo 1 (en el modo 3 se invierte)
	director.fijas["mancha"] = true
	escena._mostrar_sala("pasillo")
	await process_frame
	comprobar(escena._fondo_tr.texture == root.get_node("Recursos").fondo("pasillo_macabro"), "pasillo con la anomalía de la mancha: fondo macabro")
	director.fijas.erase("mancha")
	estado.modo = 1   # los fondos macabros de esta parte son los de los modos 1 y 2 (en el 3 se invierten)
	director.fijas["cuadro"] = true
	escena._mostrar_sala("laboratorio")
	await process_frame
	var rec = root.get_node("Recursos")
	comprobar(escena._fondo_tr.texture == rec.fondo("laboratorio_macabro"), "cuadro macabro: laboratorio con fondo macabro")
	comprobar(escena._cuadro_visual.texture == rec.sprite("cuadro_macabro"), "cuadro macabro en el laboratorio")
	director.fijas.erase("cuadro")
	escena._refrescar_anomalias()
	comprobar(escena._fondo_tr.texture == rec.fondo("laboratorio"), "sin anomalía del cuadro: laboratorio normal")
	comprobar(escena._cuadro_visual.texture == rec.sprite("cuadro"), "sin anomalía: cuadro normal")
	# Vigilancia: fondo macabro mientras dura el parpadeo; oficina y pasillo de la sala 5: al pedir el 5.º glifo (viento)
	escena._mostrar_sala("vigilancia")
	await process_frame
	comprobar(escena._fondo_tr.texture == rec.fondo("vigilancia"), "vigilancia normal sin parpadeo")
	director.parpadeo_restante = 3.0
	escena._refrescar_anomalias()
	comprobar(escena._fondo_tr.texture == rec.fondo("vigilancia_macabro"), "vigilancia macabra durante el parpadeo")
	director.parpadeo_restante = 0.0
	escena._refrescar_anomalias()
	comprobar(escena._fondo_tr.texture == rec.fondo("vigilancia"), "vigilancia vuelve a la normal")
	comprobar(not director.macabro("oficina"), "oficina normal sin el 5.º glifo pedido")
	var antes_sol: int = estado.solicitados
	var antes_conf: int = estado.confirmados
	estado.solicitados = 5
	estado.confirmados = 4
	comprobar(director.macabro("oficina") and director.macabro("pasillo_secreto"), "oficina y pasillo de la sala 5 macabros al pedir el 5.º glifo")
	estado.solicitados = antes_sol
	estado.confirmados = antes_conf
	director.silueta_visible = true
	comprobar(director.macabro("recepcion") and director.macabro("recepcion_reverso") and director.macabro("ventana_recepcion"), "entidad activa: recepción, reverso y ventana macabros")
	director.silueta_visible = false
	# Modo 3: los fondos se invierten (macabros siempre, normales con la anomalía)
	estado.modo = 3
	comprobar(director.macabro("vigilancia") and director.macabro("laboratorio") and director.macabro("recepcion"), "modo 3: los fondos macabros están puestos sin anomalía")
	comprobar(director.macabro("oficina") and director.macabro("pasillo_secreto"), "modo 3: oficina y pasillo macabros sin el viento")
	director.parpadeo_restante = 2.0
	comprobar(not director.macabro("vigilancia"), "modo 3: con el parpadeo, vigilancia normal")
	director.parpadeo_restante = 0.0
	director.silueta_visible = true
	comprobar(not director.macabro("recepcion") and not director.macabro("ventana_recepcion"), "modo 3: con la silueta, recepción y ventana normales")
	director.silueta_visible = false
	# Ordenador abierto: la silueta de la ventana no avanza (espera a la vista de la sala)
	director.silueta_visible = true; director.entidad_fase = 1; director._silueta_restante = 0.5
	director.ordenador_abierto = true
	avanzar(1.0)
	comprobar(director.entidad_fase == 1 and director._silueta_restante == 0.5 and director.silueta_visible, "con un ordenador abierto la silueta no ataca")
	director.ordenador_abierto = false
	director.silueta_visible = false
	comprobar(director.macabro("pasillo"), "modo 3: el pasillo va macabro sin anomalía")
	comprobar(director.macabro("pasillo") and not director.mancha_en_camara() == false, "modo 3: pasillo manchado sin anomalía (CAM 2 también)")
	director.fijas["mancha"] = true
	comprobar(not director.macabro("pasillo"), "modo 3: con la mancha, pasillo normal")
	director.fijas.erase("mancha")
	estado.modo = 1
	escena.queue_free()
	await process_frame

	print("== Entidad de la ventana de Vigilancia")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.solicitados = 3   # glifo de la silueta ya pedido: velocidad y daño normales
	estado.fijar_compatibilidad(0.0)
	estado.sala_actual = "vigilancia"
	director.eventos.clear()
	director.silueta_visible = false
	director._aparece_silueta()
	comprobar(director.silueta_visible and director.entidad_fase == 1, "la entidad aparece en la fase 1")
	avanzar(1.3)
	comprobar(director.entidad_fase == 2, "a los 1,25 s pasa a la fase 2")
	avanzar(1.3)
	comprobar(director.entidad_fase == 3, "otros 1,25 s y llega a la fase 3")
	avanzar(1.3)
	comprobar(not director.silueta_visible and is_equal_approx(estado.compatibilidad, 40.0), "sin reaccionar y sin haber muerto: +40 % y desaparece")
	estado.muertes = 1
	estado.fijar_compatibilidad(0.0)
	director._aparece_silueta()
	var m0: int = estado.muertes
	avanzar(4.0)
	comprobar(estado.muertes == m0 + 1, "sin reaccionar tras la primera muerte: mata")
	estado.muertes = 0
	estado.jugando = true
	estado.sala_actual = "vigilancia"
	estado.fijar_compatibilidad(0.0)
	director.silueta_visible = false
	director._aparece_silueta()
	avanzar(0.5)
	director.detener_entidad()
	comprobar(director.entidad_parpadeo > 0.0 and director.silueta_visible, "clic en la ventana: la entidad se detiene y parpadea")
	avanzar(0.7)
	comprobar(director.entidad_parpadeo > 0.0, "sigue parpadeando un rato")
	avanzar(1.2)
	comprobar(not director.silueta_visible and estado.compatibilidad < 1.0, "tras los parpadeos desaparece sin penalización")
	director._aparece_silueta()
	director.entrar_sala("pasillo")
	comprobar(not director.silueta_visible and is_equal_approx(estado.compatibilidad, 15.0), "salir de Vigilancia con la entidad activa reinicia y cuesta 15 %")
	comprobar(director.entidad_doble and director.bolsa.count("silueta") >= 1, "tras esquivarla, la próxima aparición tiene probabilidad doble")
	director._aparece_silueta()
	comprobar(director.bolsa.count("silueta") <= 1 and not director.entidad_doble, "al reaparecer se quitan las copias extra")

	print("== PIN de Vigilancia, tarjeta de seguridad y LEDs")
	estado.nueva_partida()
	comprobar(not estado.tiene_tarjeta and not estado.vigilancia_abierta, "al empezar no se tiene la tarjeta y Vigilancia está cerrada")
	comprobar(estado.pin.size() == 4, "hay un PIN de 4 dígitos")
	var malo: Array = estado.pin.duplicate()
	malo[3] = (malo[3] + 1) % 10
	comprobar(estado.comprobar_pin(estado.pin) and not estado.comprobar_pin(malo), "solo el PIN correcto abre")
	var t0: float = estado.tiempo
	estado._process(1.0)
	comprobar(is_equal_approx(estado.tiempo, t0), "con Vigilancia cerrada no corre el reloj")
	director._process(1.0)
	comprobar(director.eventos.is_empty() and not director.silueta_visible, "con Vigilancia cerrada no surgen anomalías")
	director._hasta_parpadeo_ambiente = 0.01
	var c_antes: float = estado.compatibilidad
	director._process(0.1)
	comprobar(director.parpadeo_ambiente > 0.0 and is_equal_approx(estado.compatibilidad, c_antes), "con Vigilancia cerrada solo hay parpadeo de ambiente, sin penalizar")
	director.parpadeo_ambiente = 0.0
	root.get_node("Transicion").ocupada = false   # las muertes simuladas antes dejan un cambio de escena sin terminar
	var esc3 = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(esc3)
	await process_frame
	esc3._mostrar_sala("recepcion")
	await process_frame
	esc3._funcion("pc_correo")
	await process_frame
	comprobar(esc3._panel_abierto != null and esc3._panel_abierto.get_script().get_global_name() == "PanelCorreo", "el ordenador de la recepción abre el correo")
	esc3._panel_abierto.cerrar()
	await process_frame
	esc3._mostrar_sala("pasillo")
	await process_frame
	esc3._al_pulsar({"accion": "ir", "valor": "vigilancia"})
	await process_frame
	comprobar(esc3._panel_abierto != null and esc3._panel_abierto.get_script().get_global_name() == "PanelPin", "la puerta de Vigilancia pide el PIN")
	var pan = esc3._panel_abierto
	var otro: Array = malo
	for d in otro:
		pan._pulsar(d)
	await create_timer(0.9).timeout
	comprobar(not estado.vigilancia_abierta and pan._escrito.is_empty(), "un PIN erróneo se borra y no abre")
	for d in estado.pin:
		pan._pulsar(d)
	await create_timer(1.6).timeout
	comprobar(estado.vigilancia_abierta and esc3.sala_id == "vigilancia", "el PIN correcto abre Vigilancia y entra")
	esc3.queue_free()
	await process_frame
	var esc2 = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(esc2)
	await process_frame
	esc2._mostrar_sala("pasillo")
	await process_frame
	esc2._al_pulsar({"accion": "ir", "valor": "laboratorio"})
	await create_timer(0.8).timeout
	comprobar(esc2.sala_id == "pasillo", "sin tarjeta el laboratorio está cerrado")
	esc2._mostrar_sala("vigilancia")
	await process_frame
	esc2._funcion("archivero")
	await process_frame
	comprobar(estado.tiene_tarjeta and esc2._panel_abierto != null, "el archivero da la tarjeta (sin inventario) y muestra el texto")
	esc2._panel_abierto.cerrar()
	await process_frame
	esc2._mostrar_sala("pasillo")
	await process_frame
	esc2._al_pulsar({"accion": "ir", "valor": "laboratorio"})
	await create_timer(1.2).timeout
	comprobar(esc2.sala_id == "laboratorio", "con la tarjeta el laboratorio se abre")
	estado.muertes = 1
	comprobar(estado.tiene_tarjeta, "la tarjeta se conserva tras morir")
	estado.muertes = 0
	esc2.queue_free()
	await process_frame
	var tabla := {0.0: 0, 0.5: 0, 1.0: 1, 15.0: 1, 16.0: 2, 29.0: 2, 30.0: 3, 39.0: 3, 40.0: 4, 49.0: 4, 50.0: 5, 59.0: 5, 60.0: 6, 69.0: 6, 70.0: 7, 79.0: 7, 80.0: 8, 89.0: 8, 90.0: 9, 100.0: 9}
	var ok_tabla := true
	for c in tabla:
		estado.compatibilidad = c
		if interfaz.nivel_leds() != tabla[c]:
			ok_tabla = false
			print("   LEDs mal: ", c, " -> ", interfaz.nivel_leds(), " (esperado ", tabla[c], ")")
	comprobar(ok_tabla, "tabla de LEDs por tramos de compatibilidad")
	estado.fijar_compatibilidad(0.0)

	print("== Dificultad de la entidad")
	var durs := []
	for m in [1, 2, 3]:
		estado.modo = m
		estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
		estado.solicitados = 3
		director.silueta_visible = false
		director._aparece_silueta()
		durs.append(director.duracion_fase_entidad())
	comprobar(durs[0] > durs[1] and durs[1] > durs[2], "cada modo acorta las fases de la entidad (%s)" % str(durs))
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.solicitados = 3
	var previa := 99.0
	var siempre_menor := true
	for i in 3:
		director.silueta_visible = false
		director._aparece_silueta()
		var d: float = director.duracion_fase_entidad()
		if d >= previa: siempre_menor = false
		previa = d
	comprobar(siempre_menor, "cada reaparición de la entidad es más rápida")
	for i in 20:
		director.silueta_visible = false
		director._aparece_silueta()
	comprobar(is_equal_approx(director.duracion_fase_entidad(), 1.25 * director.ENTIDAD_FACTOR_MIN), "la reducción tiene un tope")
	director.silueta_visible = false
	estado.modo = 1

	print("== Apagón")
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.tiene_detector = true
	estado.sala_actual = "vigilancia"
	director.silueta_visible = false
	director.eventos.clear()
	director._rellenar_bolsa()
	director._process(0.1)
	comprobar(director.rondas_apagon == 0 and director.apagon_objetivo == 0, "sin 60 % ni segunda vida no cuentan rondas ni hay apagón armado")
	# Modo 1 entre 60 y 80 %: cada 3 rondas
	estado.fijar_compatibilidad(60.0)
	director.advertencia_activa = false
	director._rellenar_bolsa()
	director._rellenar_bolsa()
	director._process(0.1)
	comprobar(director.rondas_apagon == 2 and director.apagon_objetivo == 0, "modo 1 con 60 %: tras 2 rondas todavía no hay apagón")
	director._rellenar_bolsa()
	director._process(0.1)
	comprobar(director.rondas_apagon == 3 and director.apagon_objetivo >= 1 and director.apagon_objetivo <= director.tam_ronda - 1, "modo 1 con 60 %: en la 3.ª ronda se arma el apagón dentro de la propia ronda")
	var objetivo: int = director.apagon_objetivo
	for i in objetivo - 1:
		director._anomalia_sacada()
	comprobar(not director._apagon_pendiente, "antes de la anomalía elegida no pasa nada")
	director._anomalia_sacada()
	comprobar(director._apagon_pendiente and director.rondas_apagon == 0 and director._hasta_apagon >= 1.0 and director._hasta_apagon <= 4.0, "al salir la anomalía elegida queda en marcha con un retraso aleatorio de 1-4 s")
	director.silueta_visible = true
	director._hasta_apagon = 0.0
	director._process(0.1)
	comprobar(director.apagon_aviso <= 0.0 and not director.apagon_activo(), "no se inicia mientras la entidad de la ventana está activa")
	director.silueta_visible = false
	director._process(0.1)
	comprobar(director.apagon_aviso > 0.0 and not director.apagon_activo(), "antes del apagón hay un breve parpadeo de aviso")
	comprobar(director.apagon_aviso <= 1.2 and director.APAGON_AVISO < director.DURACION_PARPADEO, "el parpadeo de aviso es más breve que el de la anomalía")
	var c_aviso: float = estado.compatibilidad
	director.bolsa = ["silueta", "cuadro"]
	comprobar(director._elegir_tipo() != "silueta", "la entidad de la ventana no aparece durante el aviso")
	director.bolsa = ["silueta", "cuadro"]
	for i in 14:
		director._process(0.1)
	comprobar(director.apagon_activo() and is_equal_approx(estado.compatibilidad, c_aviso), "tras el aviso llega el apagón, sin daño")
	comprobar(is_equal_approx(director.apagon_restante, 5.0 - 0.2) or director.apagon_restante > 4.0, "en el modo 1 dura 5 s")
	var interfaz2 = root.get_node("Interfaz")
	interfaz2.activa = true
	interfaz2._refrescar_senales()
	comprobar(interfaz2.nivel_leds() == 9 and interfaz2._senales.text.contains("ERROR"), "durante el apagón el detector muestra error y enciende todas las luces")
	director.bolsa = ["silueta", "cuadro"]
	comprobar(director._elegir_tipo() != "silueta", "la entidad de la ventana no puede aparecer durante el apagón")
	root.get_node("Transicion").ocupada = false
	var esc4 = load("res://escenas/escenario.tscn").instantiate()
	root.add_child(esc4)
	await process_frame
	esc4._mostrar_sala("pasillo")
	await process_frame
	comprobar(esc4._fondo_tr.texture == root.get_node("Recursos").fondo("pasillo_apagon"), "durante el apagón se usa el fondo oscurecido")
	esc4._abrir_panel("camaras")
	comprobar(esc4._panel_abierto == null, "los ordenadores no funcionan durante el apagón")
	esc4._al_pulsar({"accion": "ir", "valor": "recepcion"})
	await create_timer(1.2).timeout
	comprobar(esc4.sala_id == "recepcion" and director.apagon_activo(), "durante el apagón el jugador puede moverse y cambiar de sala no lo quita")
	esc4.queue_free()
	await process_frame
	for i in 55:
		director._process(0.1)
	comprobar(not director.apagon_activo(), "el apagón termina")
	interfaz2._refrescar_senales()
	comprobar(interfaz2.nivel_leds() == 6, "al volver la luz los LEDs vuelven a su nivel")
	# Modo 2 (cada 2 rondas) y modo 3 (cada ronda, 2,5 s)
	estado.modo = 2
	estado.fijar_compatibilidad(70.0)
	comprobar(director.rondas_para_apagon() == 2, "modo 2 entre 60 y 80 %: cada 2 rondas")
	estado.modo = 3
	comprobar(director.rondas_para_apagon() == 1 and is_equal_approx(float(estado.cfg("apagon_duracion")), 2.5), "modo 3: cada ronda y dura 2,5 s")
	estado.modo = 1
	comprobar(director.rondas_para_apagon() == 3, "modo 1 con 70 %: cada 3 rondas")
	estado.fijar_compatibilidad(80.0)
	comprobar(director.rondas_para_apagon() == 1, "con 80 % o más, un apagón por ronda (modo 1)")
	estado.modo = 2
	comprobar(director.rondas_para_apagon() == 1, "con 80 % o más, un apagón por ronda (modo 2)")
	estado.modo = 3
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.sala_actual = "vigilancia"
	director._process(0.1)
	comprobar(director.rondas_apagon == 1 and director.apagon_objetivo >= 1, "en el modo 3 hay apagón ya en la primera ronda, sea cual sea la compatibilidad")
	director.silueta_visible = false
	director._apagon_pendiente = false
	director.apagon_objetivo = 0
	director.iniciar_apagon()
	comprobar(is_equal_approx(director.apagon_restante, 2.5), "el apagón del modo 3 dura 2,5 s")
	director.apagon_restante = 0.0
	estado.modo = 1
	estado.nueva_partida(); estado.vigilancia_abierta = true; estado.tiene_tarjeta = true
	estado.fijar_compatibilidad(0.0)
	estado.muertes = 1
	estado.sala_actual = "habitacion_secreta"
	director.rondas_apagon = 0
	director._rellenar_bolsa()
	comprobar(director.rondas_apagon == 0, "en la habitación secreta no cuentan rondas")
	estado.sala_actual = "pasillo_alterado"
	director._rellenar_bolsa()
	comprobar(director.rondas_apagon == 1, "en la segunda vida cuentan rondas aunque la compatibilidad sea baja")
	estado.muertes = 0
	director._reiniciar_apagon()

	print("== Finales")
	for muertes in [0, 1]:
		estado.muertes = muertes
		var fin = load("res://escenas/final.tscn").instantiate()
		root.add_child(fin)
		await process_frame
		await process_frame
		fin._cerrar_hoja(Button.new())
		await create_timer(0.5).timeout
		comprobar(is_instance_valid(fin) and fin.get_child_count() > 0, "final con %d muertes se construye con contenido" % muertes)
		fin.queue_free()
		await process_frame

	print("== Partida guía (modo 1, la primera sin morir)")
	estado.modo_desbloqueado = 1
	estado.guia_hecha = false
	estado.modo = 1
	estado.nueva_partida()
	comprobar(estado.glifos[1] == "ofiuco" and estado.glifos[4] == "andromeda" and estado.guia_activa, "primera partida modo 1: Ofiuco en la 2.ª posición y Andrómeda 5.ª")
	comprobar(estado.guia_hecha, "la guía queda marcada como hecha")
	estado.muertes += 1
	estado.fin_guia_por_muerte()
	comprobar(not estado.guia_activa and estado.glifos[4] == "andromeda", "tras morir la guía termina y Andrómeda sigue 5.ª")
	estado.nueva_partida()
	comprobar(not estado.guia_activa and estado.glifos[1] != "" and estado.glifos[4] == "andromeda", "la segunda partida no es guía")
	var repetidos := false
	for g in estado.glifos:
		if estado.glifos.count(g) > 1:
			repetidos = true
	comprobar(not repetidos, "sin glifos repetidos en la partida sorteada")
	print("== Resultado: ", "TODO OK" if fallos == 0 else "%d FALLOS" % fallos)
	quit(fallos)
