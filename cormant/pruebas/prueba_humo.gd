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
	print("== Bolsa y orden de eventos")
	estado.nueva_partida()
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
		if tipos[i] == tipos[i - 1]: repetido = true
	comprobar(not repetido, "nunca el mismo tipo dos veces seguidas")
	estado.nueva_partida()
	var ordenada: Array = director.bolsa.duplicate()
	ordenada.sort()
	var esperada: Array = ["cuadro", "mancha", "parpadeo", "pitidos", "silueta", "voz"]
	comprobar(ordenada == esperada, "la bolsa inicial contiene las 6 anomalías")
	comprobar(director.bolsa[0] == "cuadro", "la primera de la bolsa es el cuadro")

	print("== Penalizaciones")
	estado.nueva_partida()
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
	comprobar(director.cuadro_girado(), "el cuadro se queda girado")
	director.sala_marcada = "recepcion"
	director.marca_restante = 20.0
	director.entrar_sala("recepcion")
	comprobar(is_equal_approx(estado.compatibilidad, c0 + 25.0), "entrar en sala marcada +10 %")

	print("== Cámaras y verificación")
	estado.nueva_partida()
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
	estado.nueva_partida()
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
	estado.nueva_partida()
	estado.fijar_compatibilidad(95.0)
	estado.sumar_compatibilidad(10.0)
	avanzar(0.2)
	comprobar(estado.muertes == 1 and not estado.jugando, "100 % mata aunque no haya sombra")

	print("== Modo 2: sombra mortal, ventana a la mitad, 5 activas")
	estado.modo = 2
	estado.nueva_partida()
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
	estado.nueva_partida()
	estado.muertes = 1
	director.reanudar_tras_morir()
	comprobar(is_equal_approx(estado.compatibilidad, 60.0), "modo 1: reaparece con 60 %")

	print("== Herramientas del desarrollador (G invulnerable, F +20 %)")
	estado.modo = 1
	estado.nueva_partida()
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
	estado.nueva_partida()
	estado.invulnerable = true
	estado.desactivar_trucos()
	comprobar(not estado.invulnerable, "al volver al título se apaga la invulnerabilidad")
	estado.nueva_partida()

	print("== Modo 3: el parpadeo no suma, pero dura el doble")
	estado.modo = 3
	estado.nueva_partida()
	estado.fijar_compatibilidad(50.0)
	estado.sala_actual = "vigilancia"
	director.forzar("parpadeo")
	avanzar(0.3)
	comprobar(is_equal_approx(estado.compatibilidad, 50.0), "modo 3: el parpadeo no suma compatibilidad")
	comprobar(director.parpadeo_restante > 6.0, "modo 3: el parpadeo dura el doble (7 s)")
	estado.modo = 1
	estado.nueva_partida()

	print("== Modo 3: empieza al máximo, pasos de la entidad cada 4 anomalías en cualquier sala")
	estado.modo = 3
	estado.nueva_partida()
	comprobar(is_equal_approx(estado.compatibilidad, 99.0) and estado.filtro_rojo() and estado.tramo == 3, "modo 3: 99 %, modo rojo y último tramo")
	comprobar(director.maximo_activos() == 5 and is_equal_approx(director.duracion_evento(), 35.0), "modo 3: 35 s y 5 activas")
	comprobar(is_equal_approx(director.ventana_aviso(), 2.0) and is_equal_approx(director.ocultarse_necesario(), 1.0), "modo 3: ventana de 2 s y 1 s mantenido")
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
	avanzar(0.3)
	comprobar(director.advertencia_activa and director.aviso_restante > 1.0 and director.aviso_restante <= 2.0, "modo 3: la 4.ª anomalía, en el pasillo, trae a la entidad con 2 s")
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
	avanzar(0.3)
	comprobar(director.advertencia_activa, "modo 3: otras 4 anomalías, otra entidad")
	director.mantener(true)
	avanzar(0.5)
	director.mantener(false)    # suelta antes del segundo: se reinicia la cuenta de ocultación
	avanzar(2.0)
	comprobar(estado.muertes == 2 and not estado.jugando, "modo 3: no mantener 1 s seguido en 2 s es game over")
	estado.nueva_partida()
	director.anomalias_desde_sombra = 0
	director.eventos.clear()
	estado.sala_actual = "vigilancia"
	for i in 4:
		director.eventos.clear()
		director.silueta_visible = false
		director._crear("silueta")
	avanzar(0.3)
	comprobar(director.advertencia_activa, "modo 3: también aparece estando en Vigilancia")
	director.mantener(true)
	avanzar(1.2)
	comprobar(not director.advertencia_activa and estado.jugando, "modo 3: en Vigilancia se esquiva igual")
	director.mantener(false)
	estado.nueva_partida()
	estado.sumar_compatibilidad(1.0)
	avanzar(0.2)
	comprobar(estado.muertes == 2 and not estado.jugando, "modo 3: llegar a 100 % es game over")

	print("== Desbloqueo de modos")
	DirAccess.remove_absolute("user://prueba_progreso.cfg")
	estado.modo_desbloqueado = 1
	estado.modo = 1
	estado.nueva_partida()
	comprobar(estado.superar_modo() == 2 and estado.modo_desbloqueado == 2, "superar el modo 1 desbloquea el 2")
	comprobar(estado.superar_modo() == 0, "volver a superar el 1 no desbloquea nada más")
	estado.modo = 3
	estado.nueva_partida()
	comprobar(estado.modo == 2, "no se puede jugar un modo bloqueado")
	estado.superar_modo()
	comprobar(estado.modo_desbloqueado == 3, "superar el modo 2 desbloquea el 3")
	estado.modo_desbloqueado = 1
	estado.cargar_progreso()
	comprobar(estado.modo_desbloqueado == 3, "el desbloqueo se guarda en disco")
	estado.modo_desbloqueado = 2
	estado.modo = 2
	estado.nueva_partida()
	estado.muertes = 1   # final malo (una muerte)
	comprobar(estado.superar_modo() == 3, "el final malo del modo 2 también desbloquea el 3")
	estado.modo_desbloqueado = 2
	estado.nueva_partida()
	estado.muertes = 0   # final bueno
	comprobar(estado.superar_modo() == 3, "el final bueno del modo 2 desbloquea el 3")
	estado.modo = 3
	estado.nueva_partida()
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
		estado.nueva_partida()
		estado.muertes = clave[1]
		comprobar(estado.id_final() == esperado[clave], "id del final: " + esperado[clave])
		estado.superar_modo()
		comprobar(estado.estrellas.has(esperado[clave]) and estado.estrella_reciente == esperado[clave], "estrella ganada: " + esperado[clave])
	comprobar(estado.estrellas.size() == 4, "4 estrellas tras los finales de los modos 1 y 2")
	estado.modo = 1
	estado.nueva_partida()
	estado.superar_modo()
	comprobar(estado.estrellas.size() == 4, "repetir un final no duplica la estrella")
	estado.modo = 3
	estado.nueva_partida()
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

	print("== Código por orden")
	estado.nueva_partida()
	comprobar(estado.codigo.size() == 5 and estado.codigo[4] >= 1, "5 dígitos; el último de 1 a 9")
	comprobar(estado.puede_solicitar() and not estado.armado("sombra"), "al inicio solo se puede solicitar el primero")
	comprobar(not estado.confirmar(0, estado.codigo[0]), "no se confirma un dígito sin solicitarlo")
	comprobar(estado.solicitar() and estado.armado("sombra") and not estado.armado("mancha"), "solicitar el 1º arma solo la recepción")
	comprobar(not estado.solicitar(), "no se solicita el siguiente sin confirmar el actual")
	comprobar(not estado.confirmar(0, (estado.codigo[0] + 1) % 10), "dígito equivocado rechazado")
	comprobar(estado.confirmar(0, estado.codigo[0]) and estado.confirmados == 1, "dígito correcto confirmado")
	comprobar(not estado.confirmar(2, estado.codigo[2]), "no se salta el orden")
	var c_cod: float = estado.compatibilidad
	director.codigo_erroneo()
	comprobar(is_equal_approx(estado.compatibilidad, c_cod + 5.0) and director.terminal_lab_ocupado(), "error de código: +5 % y bloqueo")
	comprobar(is_equal_approx(director.bloqueo_lab, 30.0), "modo 1: bloqueo de 30 s")
	comprobar(estado.confirmados == 0 and estado.solicitados == 1, "error de código: lo confirmado vuelve a 0 y lo desbloqueado sigue desbloqueado")
	avanzar(29.0)
	comprobar(director.terminal_lab_ocupado(), "a los 29 s sigue bloqueado")
	avanzar(2.0)
	comprobar(not director.terminal_lab_ocupado(), "el bloqueo del código termina a los 30 s")
	comprobar(estado.confirmar(0, estado.codigo[0]) and estado.confirmados == 1, "tras el bloqueo se vuelve a introducir el dígito")
	print("== Error de código por modo y reinicio total")
	estado.modo_desbloqueado = 3
	for par in [[1, 30.0, 5.0], [2, 45.0, 5.0], [3, 60.0, 0.0]]:
		estado.modo = par[0]
		estado.nueva_partida()
		estado.fijar_compatibilidad(50.0 if par[0] < 3 else 90.0)
		for i in 3:
			estado.solicitar()
			estado.confirmar(i, estado.codigo[i])
		estado.solicitar()
		var antes: float = estado.compatibilidad
		director.codigo_erroneo()
		comprobar(is_equal_approx(director.bloqueo_lab, par[1]), "modo %d: bloqueo de %d s" % [par[0], int(par[1])])
		comprobar(is_equal_approx(estado.compatibilidad, antes + par[2]), "modo %d: +%d %% al equivocarse" % [par[0], int(par[2])])
		comprobar(estado.confirmados == 0 and estado.solicitados == 4, "modo %d: los 3 confirmados vuelven a 0 y los 4 desbloqueados siguen" % par[0])
		director.bloqueo_lab = 0.0
	estado.modo = 1
	estado.modo_desbloqueado = 1
	estado.nueva_partida()

	print("== Habitación secreta: sin anomalías (salvo parpadeo y entidad)")
	estado.modo = 1
	estado.nueva_partida()
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
	estado.nueva_partida()
	estado.sala_actual = "habitacion_secreta"
	estado.fijar_compatibilidad(60.0)
	director.proximo_aviso = 0.05
	director._process(0.1)
	comprobar(director.advertencia_activa, "la entidad sí puede aparecer en la habitación secreta")
	director.mantener(true)
	avanzar(6.0)
	comprobar(not director.advertencia_activa and estado.jugando, "en la habitación hay que esconderse y se puede")
	director.mantener(false)
	estado.nueva_partida()

	print("== Botón Volver: sala anterior")
	var salas = load("res://scripts/nucleo/datos_salas.gd")
	comprobar(salas.volver_a("pasillo") == "recepcion" and salas.volver_a("vigilancia") == "pasillo", "volver desde pasillo y vigilancia")
	comprobar(salas.volver_a("laboratorio") == "pasillo" and salas.volver_a("oficina") == "laboratorio", "volver desde laboratorio y oficina")
	comprobar(salas.volver_a("recepcion") == "" and salas.volver_a("habitacion_secreta") == "" and salas.volver_a("pasillo_alterado") == "", "sin vuelta atrás en el inicio, la habitación y el 14-B")

	print("== Libreta de objetivos y detector de señales")
	var interfaz = root.get_node("Interfaz")
	estado.nueva_partida()
	comprobar(interfaz._objetivo_actual().contains("solicitar el dígito 1"), "libreta: primer objetivo = solicitar el dígito 1")
	estado.solicitar()
	comprobar(interfaz._objetivo_actual().contains("buscar el dígito 1") and interfaz._objetivo_actual().contains("recepción"), "libreta: con el dígito pedido indica dónde buscar")
	estado.visibles["sombra"] = 20.0
	comprobar(interfaz._objetivo_actual().contains("introducir"), "libreta: con el dígito a la vista, introducirlo")
	estado.visibles.clear()
	interfaz._refrescar_notas()
	comprobar(not interfaz._texto_notas.text.contains(str(estado.codigo[0]) + "\n") and interfaz._texto_notas.text.contains("OBJETIVOS"), "la libreta tiene objetivos y ningún número")
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
	comprobar(interfaz._leds.size() == 9 and not interfaz._leds[0].visible and not interfaz._leds[8].visible, "detector: sin anomalías los LEDs están apagados")
	director.forzar("cuadro")
	interfaz._refrescar_senales()
	comprobar(interfaz._animando_leds, "detector: una señal nueva dispara el parpadeo")
	await create_timer(0.9).timeout
	interfaz._refrescar_senales()
	comprobar(not interfaz._animando_leds and interfaz._leds[0].visible and interfaz._leds[8].visible, "detector: tras parpadear 2 veces los LEDs quedan encendidos")
	interfaz._refrescar_senales()
	comprobar(not interfaz._animando_leds, "detector: la misma señal no vuelve a avisar")
	director.eventos.clear()
	interfaz._refrescar_senales()
	comprobar(not interfaz._leds[4].visible, "detector: al irse la anomalía los LEDs se apagan")
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
	estado.nueva_partida()
	comprobar(not estado.tiene_detector and not interfaz._detector.visible, "detector: se pierde al empezar otra partida")

	print("== Anomalías con dígito")
	for tipo in ["cuadro", "mancha"]:
		var id: String = director.FRAGMENTO_DE[tipo]
		estado.nueva_partida()
		director.forzar(tipo)
		ev = director.evento_de(tipo)
		ev.real = false
		director.reportar(ev)
		comprobar(not estado.digito_visible(id), "%s: reporte falso no da dígito" % tipo)
		director.bloqueo = 0.0
		director.forzar(tipo)
		ev = director.evento_de(tipo)
		ev.real = true
		director.reportar(ev)
		comprobar(not estado.digito_visible(id), "%s: real pero sin solicitar no da dígito" % tipo)
		# Se pide el dígito de esa anomalía (hay que confirmar los anteriores)
		estado.nueva_partida()
		for i in estado.ORDEN_FRAGMENTOS.find(id):
			estado.solicitar()
			estado.confirmar(i, estado.codigo[i])
		estado.solicitar()
		director.eventos.clear()
		director.forzar(tipo)
		ev = director.evento_de(tipo)
		ev.real = true
		director.reportar(ev)
		comprobar(estado.digito_visible(id), "%s: real y solicitado da dígito" % tipo)
		avanzar(29.0)
		comprobar(estado.digito_visible(id), "%s: el dígito sigue a los 29 s" % tipo)
		avanzar(2.0)
		comprobar(not estado.digito_visible(id), "%s: el dígito se desvanece a los 30 s" % tipo)
	estado.nueva_partida()
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

	print("== Prioridad de la anomalía del dígito solicitado")
	var nunca_primera := true
	var siempre_2_o_3 := true
	for intento in 60:
		estado.nueva_partida()
		director.bolsa = ["cuadro", "silueta", "voz", "parpadeo", "pitidos", "mancha"]
		estado.solicitar()
		estado.confirmar(0, estado.codigo[0])
		estado.solicitar()          # toca el pasillo → mancha
		var pos: int = director.bolsa.find("mancha")
		if pos == 0: nunca_primera = false
		if pos < 1 or pos > 2: siempre_2_o_3 = false
	comprobar(nunca_primera, "la anomalía del dígito pedido nunca es la primera")
	comprobar(siempre_2_o_3, "la anomalía del dígito pedido sale segunda o tercera")
	estado.nueva_partida()
	director.bolsa = ["mancha", "cuadro", "voz", "silueta", "pitidos", "parpadeo"]
	estado.solicitar()                 # recepción → silueta, no afecta a la mancha
	comprobar(director.bolsa[0] == "mancha", "pedir otro dígito no toca el resto de la bolsa")
	director.bolsa = ["cuadro", "voz", "pitidos"]
	director.fijas.clear()
	director._rellenar_bolsa()
	comprobar(director.bolsa.find("silueta") != 0, "al rellenar la bolsa tampoco sale primera")

	print("== Nota de ayuda del modo 1 (dígito de la cámara 3)")
	estado.modo_desbloqueado = 3
	for caso in [[1, true, true], [1, false, false], [2, true, false]]:
		estado.modo = caso[0]
		estado.nueva_partida()
		if caso[1]:
			for i in 3:
				estado.solicitar()
				estado.confirmar(i, estado.codigo[i])
			estado.solicitar()          # 4.º (pitidos) pedido y sin resolver
		else:
			estado.solicitar()          # solo el 1.º
		director.morir()
		comprobar(estado.ayuda_pitidos == caso[2], "ayuda con modo %d, atascado en pitidos=%s → %s" % [caso[0], str(caso[1]), str(caso[2])])
	estado.modo = 1
	estado.nueva_partida()
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.codigo[i])
	estado.solicitar()                  # 5.º pedido: ya resolvió la cámara 3
	director.morir()
	comprobar(not estado.ayuda_pitidos, "sin ayuda si ya resolvió el dígito de la cámara 3")
	estado.nueva_partida()
	comprobar(not estado.ayuda_pitidos, "la ayuda se borra al empezar otra partida")

	print("== Muerte: el terminal vuelve a 0 pero lo desbloqueado sigue")
	estado.nueva_partida()
	for i in 3:
		estado.solicitar()
		estado.confirmar(i, estado.codigo[i])
	estado.solicitar()                 # 4º pedido, sin confirmar
	estado.reiniciar_terminal()
	comprobar(estado.confirmados == 0 and estado.solicitados == 4, "tras morir: 0 introducidos, 4 siguen desbloqueados")
	comprobar(estado.armado("sombra") and not estado.puede_solicitar(), "hay que reintroducir antes de pedir más")
	comprobar(not estado.confirmar(0, (estado.codigo[0] + 1) % 10), "reintroducir mal se rechaza")
	for i in 4:
		comprobar(estado.confirmar(i, estado.codigo[i]), "reintroducir el dígito %d" % (i + 1))
	comprobar(estado.confirmados == 4 and estado.puede_solicitar(), "reintroducidos los 4, se puede solicitar el siguiente")
	estado.nueva_partida()
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.codigo[i])
	comprobar(estado.quinto_disponible(), "con 4 confirmados, el 5º está disponible (susurro a la derecha)")
	estado.solicitar()
	estado.confirmar(4, estado.codigo[4])
	comprobar(not estado.quinto_disponible() and estado.codigo_completo(), "completo: ya no susurra")
	estado.nueva_partida()
	estado.solicitar()
	director.forzar("silueta")
	estado.reiniciar_terminal()
	comprobar(estado.visibles.is_empty(), "al morir, los datos a la vista desaparecen")

	print("== Pitidos")
	estado.nueva_partida()
	director.forzar("pitidos")
	comprobar(director.pitidos_activos() and director.pitidos_restante > 25.0, "pitidos activos ~30 s")
	comprobar(director.pitidos_digito() != estado.digito_de("pitidos"), "sin solicitar suena una cuenta falsa")
	for i in 3:
		estado.solicitar()
		estado.confirmar(i, estado.codigo[i])
	estado.solicitar()
	comprobar(director.pitidos_digito() == estado.digito_de("pitidos"), "solicitado, suena la cuenta real")
	director.pitidos_oidos()
	comprobar(director.pitidos_escuchados, "oír los pitidos queda registrado")
	comprobar(director.segundos_pitidos(3) > 3 * 0.46 and director.segundos_pitidos(0) > 0.9, "tiempo de escucha por dígito")
	for d in 10:
		comprobar(root.get_node("Recursos").audio("pitidos_%d" % d) != null, "audio pitidos_%d" % d)
	avanzar(31.0)
	comprobar(not director.pitidos_activos(), "los pitidos caducan")

	print("== Silueta y número de recepción")
	estado.nueva_partida()
	director.forzar("silueta")
	comprobar(director.silueta_visible and director.marca_restante > 20.0, "silueta marca la recepción")
	avanzar(26.0)
	comprobar(not director.numero_recepcion_visible(), "sin solicitar, el mostrador está limpio")
	estado.nueva_partida()
	estado.solicitar()
	director.forzar("silueta")
	comprobar(not director.numero_recepcion_visible(), "el número no se ve durante la marca")
	avanzar(26.0)
	comprobar(director.numero_recepcion_visible(), "el número se ve al apagarse la marca")
	avanzar(31.0)
	comprobar(not director.numero_recepcion_visible(), "el número se desvanece a los 30 s")

	print("== Viento y manchas de la sala 5")
	estado.nueva_partida()
	for i in 4:
		estado.solicitar()
		estado.confirmar(i, estado.codigo[i])
	comprobar(not director.viento_activo(), "sin solicitar el 5º no hay viento")
	estado.solicitar()
	comprobar(director.viento_activo(), "al solicitar el 5º suena el viento")
	comprobar(director.ver_manchas_viento() and director.manchas_viento_visibles() and not director.viento_activo(), "mirar por la ventana muestra las manchas")
	avanzar(31.0)
	comprobar(not director.manchas_viento_visibles() and not director.viento_activo(), "las manchas se desvanecen y el viento calla un rato")
	avanzar(41.0)
	comprobar(director.viento_activo(), "el viento vuelve para poder repetirlo")

	print("== Parpadeo inevitable")
	estado.nueva_partida()
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

	print("== Partida simulada con jugador perfecto (código completo por orden)")
	for m in [1, 2, 3]:
		estado.modo = m
		estado.nueva_partida()
		estado.sala_actual = "vigilancia"
		var seg := 0.0
		var visto := ""
		while seg < 1800.0 and not estado.codigo_completo():
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
			# Con el dato a la vista, lo confirma al instante
			var n: int = estado.confirmados
			if n < estado.DIGITOS:
				var id: String = estado.ORDEN_FRAGMENTOS[n]
				var disponible: bool = estado.digito_visible(id)
				if id == "sombra": disponible = director.numero_recepcion_visible()
				if id == "pitidos": disponible = director.pitidos_activos() and director.pitidos_escuchados
				if id == "viento":
					director.ver_manchas_viento()
					disponible = director.manchas_viento_visibles()
				if disponible:
					estado.confirmar(n, estado.codigo[n])
		print("  modo %d: código completo en %.0f s de juego" % [m, seg])
		comprobar(estado.codigo_completo(), "con jugador perfecto se completa el código")
		comprobar(seg < 1500.0, "se completa en menos de 25 min")

	print("== Escena de juego y paneles")
	estado.nueva_partida()
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
	# Número de recepción: limpio al principio; legible una vez apagada la marca.
	escena._mostrar_sala("recepcion")
	await process_frame
	escena._funcion("numero_recepcion")
	comprobar(escena._panel_abierto == null, "frente del mostrador limpio: sin dígito")
	estado.solicitar()
	director.numero_recepcion = true
	director.marca_restante = 0.0
	director.numero_restante = 30.0
	escena._mostrar_sala("recepcion")
	await process_frame
	comprobar(escena._capa_anomalias.get_child_count() == 1, "el número aparece escrito en la recepción")
	escena._funcion("numero_recepcion")
	await process_frame
	comprobar(escena._panel_abierto != null, "leer el número abre su texto")
	escena._panel_abierto.cerrar()
	await process_frame
	# Silueta en la ventana de Vigilancia y mancha en el pasillo
	director.silueta_visible = true
	director._silueta_restante = 30.0
	estado.ayuda_pitidos = false
	escena._mostrar_sala("habitacion_secreta")
	await process_frame
	escena._funcion("mesita")
	comprobar(escena._panel_abierto == null, "mesita normal: solo un mensaje")
	estado.ayuda_pitidos = true
	escena._funcion("mesita")
	await process_frame
	comprobar(escena._panel_abierto != null, "con ayuda, la mesita muestra la nota del ex trabajador")
	escena._panel_abierto.cerrar()
	estado.ayuda_pitidos = false
	await process_frame
	escena._mostrar_sala("vigilancia")
	await process_frame
	comprobar(escena._capa_anomalias.get_child_count() == 1, "silueta pequeña visible en el fondo de Vigilancia")
	director.silueta_visible = false
	director.fijas["mancha"] = true
	escena._mostrar_sala("pasillo")
	await process_frame
	comprobar(escena._capa_anomalias.get_child_count() == 1, "mancha visible en el pasillo")
	director.fijas.erase("mancha")
	director.fijas["cuadro"] = true
	escena._mostrar_sala("laboratorio")
	await process_frame
	comprobar(is_equal_approx(escena._cuadro_visual.rotation, PI), "cuadro girado 180° en el laboratorio")
	director.fijas.erase("cuadro")
	escena.queue_free()
	await process_frame

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

	print("== Resultado: ", "TODO OK" if fallos == 0 else "%d FALLOS" % fallos)
	quit(fallos)
