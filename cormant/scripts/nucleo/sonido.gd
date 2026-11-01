extends Node
## Reproduce audio por nombre. Si el archivo todavía no existe, no hace nada (y avisa por señal,
## para que la interfaz pueda mostrar subtítulos de depuración).

signal sonido_pedido(nombre: String)

const BUS_DERECHA := "Derecha"
var _bucles := {}


func _asegurar_bus_derecha() -> void:
	## Bus extra con panorámica total a la derecha (para sonidos que señalan hacia ese lado, con auriculares).
	if AudioServer.get_bus_index(BUS_DERECHA) >= 0:
		return
	AudioServer.add_bus()
	var indice := AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, BUS_DERECHA)
	AudioServer.set_bus_send(indice, "Master")
	var panoramica := AudioEffectPanner.new()
	panoramica.pan = 1.0
	AudioServer.add_bus_effect(indice, panoramica)


func reproducir(nombre: String, volumen_db := 0.0) -> void:
	sonido_pedido.emit(nombre)
	var flujo := Recursos.audio(nombre)
	if flujo == null:
		return
	var reproductor := AudioStreamPlayer.new()
	reproductor.stream = flujo
	reproductor.volume_db = volumen_db
	add_child(reproductor)
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()


func bucle(nombre: String, volumen_db := 0.0, bus := "Master") -> void:
	if _bucles.has(nombre):
		if _bucles[nombre] != null:
			_bucles[nombre].volume_db = volumen_db
		return
	sonido_pedido.emit(nombre)
	var flujo := Recursos.audio(nombre)
	if flujo == null:
		_bucles[nombre] = null
		return
	if "loop" in flujo:
		flujo.loop = true
	var reproductor := AudioStreamPlayer.new()
	reproductor.stream = flujo
	reproductor.volume_db = volumen_db
	if bus == BUS_DERECHA:
		_asegurar_bus_derecha()
	reproductor.bus = bus
	add_child(reproductor)
	reproductor.play()
	_bucles[nombre] = reproductor


func detener_bucle(nombre: String) -> void:
	if not _bucles.has(nombre):
		return
	var reproductor = _bucles[nombre]
	if reproductor != null:
		reproductor.queue_free()
	_bucles.erase(nombre)


func detener_todo() -> void:
	for nombre in _bucles.keys():
		detener_bucle(nombre)
	for hijo in get_children():
		hijo.queue_free()
