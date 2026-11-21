class_name Digitos
## Dígitos 0-9 dibujados con una sola tira de sprites (assets/sprites/digitos.png, 10 casillas de 64x96). Cada dígito es una
## región de esa textura (AtlasTexture, cacheada), así que cualquier PIN se compone sin imágenes por combinación.

const ANCHO := 64
const ALTO := 96

static var _regiones: Array[AtlasTexture] = []


static func textura(n: int) -> Texture2D:
	if _regiones.is_empty():
		var tira := Recursos.sprite("digitos")
		if tira == null:
			return null
		for i in 10:
			var r := AtlasTexture.new()
			r.atlas = tira
			r.region = Rect2(i * ANCHO, 0, ANCHO, ALTO)
			_regiones.append(r)
	return _regiones[clampi(n, 0, 9)]


## Casilla con un dígito (TextureRect del tamaño dado, manteniendo la proporción 2:3).
static func casilla(n: int, tam: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = textura(n)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = tam
	tr.size = tam
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr
