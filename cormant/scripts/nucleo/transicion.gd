extends CanvasLayer
## Fundidos a negro para cambiar de sala o de escena.

var ocupada := false
var _negro: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.modulate.a = 0.0
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_negro)


func a_negro(duracion := 0.4) -> void:
	_negro.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_negro, "modulate:a", 1.0, duracion)
	await tween.finished


func desde_negro(duracion := 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_negro, "modulate:a", 0.0, duracion)
	await tween.finished
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Funde a negro, ejecuta la acción y vuelve a mostrar la imagen.
func cambiar(accion: Callable, duracion := 0.4) -> void:
	if ocupada:
		return
	ocupada = true
	await a_negro(duracion)
	await accion.call()
	await desde_negro(duracion)
	ocupada = false


func ir_a_escena(ruta: String, duracion := 0.4) -> void:
	var accion := func() -> void:
		get_tree().change_scene_to_file(ruta)
		await get_tree().process_frame
		await get_tree().process_frame
	await cambiar(accion, duracion)
