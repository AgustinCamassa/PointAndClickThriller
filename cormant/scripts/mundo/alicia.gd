class_name Alicia
extends Control
## Alicia: sprite estático con 2 poses (de espaldas y sentada en la silla). Aparece con un fundido de 0,2 s
## y respira con un vaivén de 1 px hecho por código. Misma clase para la silueta de la entidad (negra, estirada).
## Asset por convención: assets/sprites/alicia_<pose>.png (la habitación secreta usa fondos completos).

const POSES := ["de_espaldas", "sentada", "silueta", "perfil"]
## Proporción ancho/alto de los sprites de la entidad (entidad_a.png / entidad_b.png, mismo lienzo).
const ASPECTO_ENTIDAD := 0.3979
## Opacidad de la entidad: no del todo opaca, para que el fondo asome y no parezca recortada encima.
const ALFA_ENTIDAD := 0.9
## Oscurecimiento de la zona mientras la entidad está presente.
const VELO_ENTIDAD := 0.42
## Tamaño en pantalla de cada pose (el sprite se dibuja a esa medida). El ancla es el punto de los pies.
const TAMANOS := {
	"de_espaldas": Vector2(87, 300),  # 1,68 m
	"sentada": Vector2(168, 337),  # cabeza a 1,30 m del suelo, con la silla
	"silueta": Vector2(120, 300),  # entidad (entidad_a/b.png)
	"perfil": Vector2(63, 360),  # de perfil, mirando a la derecha (alicia_perfil.png, ya volteada; 124x708 → ancho según proporción)
}

var pose := "de_espaldas"
var es_silueta := false
var _base_y := 0.0
var _pies := Vector2.ZERO
var _t := 0.0
var _textura: Texture2D
var _escala := 1.0
var _tween_mov: Tween = null


## escala: factor sobre el tamaño base de la pose (en las salas en perspectiva depende de la distancia a cámara).
func configurar(nueva_pose: String, pies: Vector2, tam := Vector2.ZERO, silueta := false, escala := 1.0) -> void:
	pose = nueva_pose
	_escala = escala
	es_silueta = silueta
	_pies = pies
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aplicar_pose(tam)
	if es_silueta:
		modulate = Color(1, 1, 1, ALFA_ENTIDAD)
	queue_redraw()


func _aplicar_pose(tam := Vector2.ZERO) -> void:
	var t: Vector2 = tam if tam != Vector2.ZERO else TAMANOS.get(pose, Vector2(120, 250)) * _escala
	if pose == "perfil" and tam == Vector2.ZERO:
		# El perfil conserva su proporción original (estirarlo lo deforma).
		var tp := Recursos.sprite("alicia_perfil")
		if tp != null:
			t.x = t.y * tp.get_width() / float(tp.get_height())
	size = t
	position = _pies - Vector2(t.x / 2.0, t.y)
	_base_y = position.y
	pivot_offset = Vector2(t.x / 2.0, t.y)
	if pose == "silueta":
		_textura = Recursos.sprite("entidad_b" if EstadoJuego.modo == 3 else "entidad_a")
	else:
		_textura = Recursos.sprite("alicia_" + pose)


func aparecer(duracion := 0.2) -> void:
	var destino := modulate.a if not es_silueta else ALFA_ENTIDAD
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", destino, duracion)


func cambiar_pose(nueva_pose: String, pies := Vector2.ZERO, escala := -1.0) -> void:
	pose = nueva_pose
	if escala > 0.0:
		_escala = escala
	if pies != Vector2.ZERO:
		_pies = pies
	_aplicar_pose()
	queue_redraw()


## Se acerca / se aleja: mueve y escala la figura hasta `pies` y `tam` en `dur` segundos (la entidad de la ventana).
func mover_a(pies: Vector2, tam: Vector2, dur: float) -> void:
	if _tween_mov != null:
		_tween_mov.kill()
	_pies = pies
	pivot_offset = Vector2(tam.x / 2.0, tam.y)
	_tween_mov = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween_mov.tween_property(self, "size", tam, dur)
	_tween_mov.tween_property(self, "position", pies - Vector2(tam.x / 2.0, tam.y), dur)
	_tween_mov.chain().tween_callback(func():
		_base_y = position.y
		_tween_mov = null)


func _process(delta: float) -> void:
	_t += delta
	if _tween_mov != null:
		return
	position.y = _base_y + (1.0 if sin(_t * 1.8) > 0.0 else 0.0)  # respiración: 1 px


func _draw() -> void:
	if _textura != null:
		draw_texture_rect(_textura, Rect2(Vector2.ZERO, size), false)
		return
	# Marcador provisional: figura oscura simple.
	var color := Color(0.08, 0.08, 0.1)
	draw_rect(Rect2(size.x * 0.15, size.y * 0.25, size.x * 0.7, size.y * 0.75), color)
	draw_circle(Vector2(size.x * 0.5, size.y * 0.14), minf(size.x, size.y) * 0.22, color)


## Velo oscuro que se funde sobre la zona donde aparece la entidad (se añade al recorte antes que la figura).
static func crear_velo(tam: Vector2) -> ColorRect:
	var v := ColorRect.new()
	v.color = Color(0, 0, 0, VELO_ENTIDAD)
	v.size = tam
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v
