class_name PanelBase
extends Control
## Panel modal a pantalla completa con título. Se cierra con el botón «Cerrar» de la barra inferior (Interfaz).

signal cerrado

var titulo := ""
var es_ordenador := false     # true: se apaga con el apagón (se cierra solo)
var contenido: Control


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.88)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.position = Vector2(60, 30)
	etiqueta.add_theme_font_size_override("font_size", 26)
	add_child(etiqueta)
	contenido = Control.new()
	contenido.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenido)
	_construir()


func _construir() -> void:
	pass


func cerrar() -> void:
	cerrado.emit()
	queue_free()
