class_name PanelPin
extends PanelBase
## Teclado de la puerta de Vigilancia: PIN de 4 dígitos (aleatorio en cada partida, está en el correo de la recepción).
## Un PIN erróneo no tiene consecuencias: se borra lo escrito. Al acertar, la puerta se abre para toda la partida.

signal pin_aceptado

const TAM_BOTON := Vector2(96, 64)
const TAM_DIGITO := Vector2(40, 60)

var _escrito: Array[int] = []
var _casillas: Array[TextureRect] = []
var _marco_visor: ColorRect
var _bloqueado := false


static func crear() -> PanelPin:
	var p := PanelPin.new()
	p.es_ordenador = true
	p.titulo = "Puerta de Vigilancia"
	return p


func _construir() -> void:
	var caja := ColorRect.new()
	caja.color = Color(0.12, 0.13, 0.15)
	caja.position = Vector2(480, 90)
	caja.size = Vector2(320, 470)
	contenido.add_child(caja)
	_marco_visor = ColorRect.new()
	_marco_visor.color = Color(0.03, 0.08, 0.07)
	_marco_visor.position = Vector2(504, 112)
	_marco_visor.size = Vector2(272, 84)
	contenido.add_child(_marco_visor)
	for i in 4:
		var c := Digitos.casilla(0, TAM_DIGITO)
		c.position = _marco_visor.position + Vector2(18 + i * 64, 12)
		c.visible = false
		contenido.add_child(c)
		_casillas.append(c)
	var disposicion := [[1, 2, 3], [4, 5, 6], [7, 8, 9], [-1, 0, -2]]
	for f in 4:
		for k in 3:
			var v: int = disposicion[f][k]
			if v == -2:
				continue
			var b := Button.new()
			b.text = "Borrar" if v == -1 else str(v)
			b.position = Vector2(504 + k * 88, 220 + f * 76)
			b.size = Vector2(80, 64)
			b.add_theme_font_size_override("font_size", 24 if v >= 0 else 17)
			b.pressed.connect(_borrar if v == -1 else _pulsar.bind(v))
			contenido.add_child(b)


func _pulsar(n: int) -> void:
	if _bloqueado or _escrito.size() >= 4:
		return
	_escrito.append(n)
	_refrescar()
	if _escrito.size() == 4:
		_comprobar()


func _borrar() -> void:
	if _bloqueado or _escrito.is_empty():
		return
	_escrito.pop_back()
	_refrescar()


func _refrescar() -> void:
	for i in 4:
		var hay := i < _escrito.size()
		_casillas[i].visible = hay
		if hay:
			_casillas[i].texture = Digitos.textura(_escrito[i])
	Sonido.reproducir("tecla", -10.0)


func _comprobar() -> void:
	_bloqueado = true
	if EstadoJuego.comprobar_pin(_escrito):
		_marco_visor.color = Color(0.05, 0.25, 0.12)
		Sonido.reproducir("confirmacion")
		Interfaz.mensaje(Textos.PIN_CORRECTO, 3.0)
		await get_tree().create_timer(0.5).timeout
		EstadoJuego.abrir_vigilancia()
		pin_aceptado.emit()
		cerrar()
	else:
		_marco_visor.color = Color(0.3, 0.05, 0.05)
		Sonido.reproducir("error_terminal", -4.0)
		Interfaz.mensaje(Textos.PIN_ERRONEO, 3.0)
		await get_tree().create_timer(0.6).timeout
		if not is_inside_tree():
			return
		_escrito.clear()
		_marco_visor.color = Color(0.03, 0.08, 0.07)
		_bloqueado = false
		_refrescar()
