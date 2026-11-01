class_name PanelTerminalLab
extends PanelBase
## Terminal CRT del laboratorio: EXPEDIENTES (decorado) y ARCHIVOS (protegido por el código de 5 dígitos, que se solicita y confirma de uno en uno).

signal codigo_aceptado

var _pantalla: Control
var _valores := [0, 0, 0, 0, 0]
var _etiquetas_digitos: Array[Label] = []
var _mensaje: Label


static func crear() -> PanelTerminalLab:
	var p := PanelTerminalLab.new()
	p.titulo = "Terminal · Laboratorio"
	return p


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.07, 0.04)
	fondo.position = Vector2(200, 100)
	fondo.size = Vector2(880, 540)
	contenido.add_child(fondo)
	_pantalla = Control.new()
	_pantalla.position = Vector2(200, 100)
	_pantalla.size = Vector2(880, 540)
	_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(_pantalla)
	_menu()


func _limpiar() -> void:
	for h in _pantalla.get_children():
		h.queue_free()
	_etiquetas_digitos.clear()


func _texto(t: String, pos: Vector2, tam := Vector2(800, 40), fuente := 22) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = tam
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fuente)
	l.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	_pantalla.add_child(l)
	return l


func _boton(t: String, pos: Vector2, tam: Vector2, accion: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = tam
	b.pressed.connect(accion)
	_pantalla.add_child(b)
	return b


func _menu() -> void:
	_limpiar()
	_texto("CORMANT MEDICAL SYSTEMS · TERMINAL L-04", Vector2(40, 30), Vector2(800, 40), 24)
	_texto("ACCESO: TECNICO_N01", Vector2(40, 70))
	_boton("EXPEDIENTES", Vector2(40, 160), Vector2(260, 60), _expedientes)
	_boton("ARCHIVOS", Vector2(40, 240), Vector2(260, 60), _archivos)


func _expedientes() -> void:
	_limpiar()
	_texto(Textos.EXPEDIENTES, Vector2(40, 40), Vector2(800, 400))
	_boton("Volver", Vector2(40, 460), Vector2(160, 50), _menu)


func _archivos() -> void:
	_limpiar()
	_texto("ARCHIVOS · CÓDIGO DE ACCESO", Vector2(40, 20), Vector2(800, 40), 24)
	_texto("Cada dígito se solicita, se busca por el edificio y se confirma, de izquierda a derecha.", Vector2(40, 58), Vector2(800, 30), 15)
	var x := 30.0
	for i in EstadoJuego.DIGITOS:
		var id: String = EstadoJuego.ORDEN_FRAGMENTOS[i]
		var hecho: bool = i < EstadoJuego.confirmados
		var activo: bool = i == EstadoJuego.confirmados and i < EstadoJuego.solicitados
		var en_espera: bool = i > EstadoJuego.confirmados and i < EstadoJuego.solicitados
		_texto("%d · %s" % [i + 1, String(Textos.NOMBRE_FRAGMENTO[id]).to_upper()], Vector2(x, 110), Vector2(170, 30), 16)
		var arriba := _boton("▲", Vector2(x + 35, 150), Vector2(80, 40), func(): _cambiar(i, 1))
		var d := _texto(str(EstadoJuego.codigo[i]) if hecho else str(_valores[i]), Vector2(x + 35, 196), Vector2(80, 80), 56)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_etiquetas_digitos.append(d)
		var abajo := _boton("▼", Vector2(x + 35, 282), Vector2(80, 40), func(): _cambiar(i, -1))
		arriba.disabled = not activo
		abajo.disabled = not activo
		var texto_boton := "BLOQUEADO"
		if hecho:
			texto_boton = "✓ CONFIRMADO"
		elif activo:
			texto_boton = "CONFIRMAR"
		elif en_espera:
			texto_boton = "EN ESPERA"
		elif i == EstadoJuego.solicitados and EstadoJuego.puede_solicitar():
			texto_boton = "SOLICITAR"
		var b := _boton(texto_boton, Vector2(x + 5, 335), Vector2(140, 46), func(): _pulsar(i))
		b.disabled = texto_boton in ["BLOQUEADO", "✓ CONFIRMADO", "EN ESPERA"]
		x += 170.0
	_mensaje = _texto("", Vector2(40, 400), Vector2(800, 40))
	_boton("Volver", Vector2(40, 460), Vector2(160, 50), _menu)
	_actualizar_mensaje()


func _actualizar_mensaje() -> void:
	if _mensaje == null:
		return
	if Director.terminal_lab_ocupado():
		_mensaje.text = "DATO INCORRECTO · CÓDIGO REINICIADO · BLOQUEADO (%d)" % int(ceil(Director.bloqueo_lab))
	elif _mensaje.text.begins_with("DATO INCORRECTO"):
		_mensaje.text = ""


func _process(_delta: float) -> void:
	if _mensaje != null and is_instance_valid(_mensaje) and Director.terminal_lab_ocupado():
		_actualizar_mensaje()
	elif _mensaje != null and is_instance_valid(_mensaje) and _mensaje.text.begins_with("DATO INCORRECTO"):
		_archivos()


func _cambiar(i: int, paso: int) -> void:
	_valores[i] = (_valores[i] + paso + 10) % 10
	_etiquetas_digitos[i].text = str(_valores[i])


func _pulsar(i: int) -> void:
	if Director.terminal_lab_ocupado():
		return
	if i >= EstadoJuego.solicitados:
		if EstadoJuego.solicitar():
			Sonido.reproducir("confirmacion")
			var id: String = EstadoJuego.ORDEN_FRAGMENTOS[i]
			Interfaz.mensaje(Textos.PISTA_SOLICITUD[id], 6.0)
			_archivos()
			_mensaje.text = "DATO SOLICITADO · " + Textos.PISTA_SOLICITUD[id]
		return
	if EstadoJuego.confirmar(i, _valores[i]):
		Sonido.reproducir("confirmacion")
		if EstadoJuego.codigo_completo():
			_archivos()
			_mensaje.text = "ACCESO CONCEDIDO"
			await get_tree().create_timer(0.8).timeout
			codigo_aceptado.emit()
			cerrar()
		else:
			_archivos()
			_mensaje.text = "DÍGITO CONFIRMADO"
	else:
		Director.codigo_erroneo()
		_archivos()
		_mensaje.text = "DATO INCORRECTO · CÓDIGO REINICIADO · BLOQUEADO (%d)" % int(ceil(Director.bloqueo_lab))
