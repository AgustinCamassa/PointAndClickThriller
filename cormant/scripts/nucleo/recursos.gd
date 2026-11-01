extends Node
## Carga de recursos por CONVENCIÓN de nombres, con respaldo si el archivo no existe.
## Cuando lleguen los assets bastará con soltarlos en estas carpetas, sin tocar código:
##   assets/fondos/<sala>.png        (1280x720)   p. ej. recepcion.png, pasillo.png
##   assets/fondos/cam_<id>.png      (vistas de cámara: cam_1 laboratorio, cam_2 pasillo; la cámara 3 no tiene imagen)
##   assets/sprites/<nombre>.png     p. ej. alicia_de_espaldas.png, anomalia_cuadro.png
##   assets/audio/<nombre>.ogg       p. ej. ambiente_tramo_1.ogg, susurro.ogg

const RUTA_FONDOS := "res://assets/fondos/"
const RUTA_SPRITES := "res://assets/sprites/"
const RUTA_AUDIO := "res://assets/audio/"
const EXTENSIONES_IMAGEN := ["png", "webp", "jpg"]
const EXTENSIONES_AUDIO := ["ogg", "wav", "mp3"]

var _cache := {}


func _buscar(base: String, extensiones: Array) -> String:
	for ext in extensiones:
		var ruta: String = base + "." + ext
		if ResourceLoader.exists(ruta):
			return ruta
	return ""


func _cargar(base: String, extensiones: Array) -> Resource:
	if _cache.has(base):
		return _cache[base]
	var ruta := _buscar(base, extensiones)
	var recurso: Resource = null
	if ruta != "":
		recurso = load(ruta)
	_cache[base] = recurso
	return recurso


func fondo(nombre: String) -> Texture2D:
	return _cargar(RUTA_FONDOS + nombre, EXTENSIONES_IMAGEN) as Texture2D


func sprite(nombre: String) -> Texture2D:
	return _cargar(RUTA_SPRITES + nombre, EXTENSIONES_IMAGEN) as Texture2D


func audio(nombre: String) -> AudioStream:
	return _cargar(RUTA_AUDIO + nombre, EXTENSIONES_AUDIO) as AudioStream
