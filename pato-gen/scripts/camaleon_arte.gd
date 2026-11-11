extends RefCounted
## Original idle poses and matching 32px walk cycles for both skins.
const Readability = preload("res://scripts/npc_readability.gd")
const FRENTE_CAMUFLADO = preload("res://assets/camaleon/camaleon_camuflado.png")
const MARCHA = preload("res://assets/camaleon/camaleon_marcha.png")
const MARCHA_CAMUFLADA = preload("res://assets/camaleon/camaleon_marcha_camuflada.png")
const DIRECCIONES := ["Abajo", "Arriba", "Derecha", "Izquierda"]
const CUADROS_MARCHA := 4
const FPS_MARCHA := 8.0
const TEXTURAS: Dictionary = {
	"Abajo": preload("res://assets/camaleon/camaleon_abajo.png"),
	"Arriba": preload("res://assets/camaleon/camaleon_arriba.png"),
	"Derecha": preload("res://assets/camaleon/camaleon_derecha.png"),
	"Izquierda": preload("res://assets/camaleon/camaleon_izquierda.png")
}
# Exact palette -> camouflage_palette pairs from approved poses_fuente.json v02.
# Explicit texture dependencies and embedded pairs also work in an exported PCK.
const REMAPEO: Dictionary = {
	0x2E2938FF: Color("#536970"),
	0x3D4B49FF: Color("#71878E"),
	0x526354FF: Color("#7F969C"),
	0x76846AFF: Color("#93A8AC"),
	0x9FA78AFF: Color("#A9BABB"),
	0xC0C3A4FF: Color("#BAC7C4"),
	0x56525FFF: Color("#B0BFBA"),
	0x7C7580FF: Color("#A1B2B0"),
	0x656954FF: Color("#82999F"),
	0x909779FF: Color("#93A8AC"),
	0xBCC09BFF: Color("#A1B2B0"),
	0xD5BD78FF: Color("#AABAB7"),
	0xD4CDB5FF: Color("#93A8AC")
}

static var _normales: SpriteFrames
static var _camuflados: SpriteFrames
static var _pieles: Dictionary = {}
static var _claves_padding: Array[String] = []

static func frames() -> SpriteFrames:
	if _normales != null: return _normales
	_normales = SpriteFrames.new()
	_normales.remove_animation(&"default")
	for indice in DIRECCIONES.size():
		var direccion: String = DIRECCIONES[indice]
		_normales.add_animation(direccion)
		_normales.set_animation_speed(direccion, FPS_MARCHA)
		_normales.set_animation_loop(direccion, true)
		for cuadro in CUADROS_MARCHA:
			var textura := _cuadro(MARCHA, indice * CUADROS_MARCHA + cuadro)
			_normales.add_frame(direccion, textura)
			_registrar_padding(textura)
		var reposo := "idle_" + direccion.to_lower()
		_normales.add_animation(reposo)
		_normales.add_frame(reposo, TEXTURAS[direccion])
		_registrar_padding(TEXTURAS[direccion])
	return _normales

static func _cuadro(hoja: Texture2D, indice: int) -> AtlasTexture:
	var textura := AtlasTexture.new()
	textura.atlas = hoja
	textura.region = Rect2(indice * 32, 0, 32, 32)
	return textura

static func _registrar_padding(textura: Texture2D) -> void:
	var clave := textura.resource_path
	if textura is AtlasTexture:
		clave = textura.atlas.resource_path + str(textura.region) + str(textura.margin)
	if clave.is_empty(): clave = str(textura.get_instance_id())
	_claves_padding.append(clave)

static func piel_camuflada(direccion: String, cuadro: int = -1) -> Texture2D:
	if _pieles.is_empty(): _preparar_pieles()
	var nombre := direccion.capitalize()
	if not TEXTURAS.has(nombre): nombre = "Abajo"
	if cuadro < 0: return _pieles["idle_" + nombre.to_lower()][0]
	return _pieles[nombre][clampi(cuadro, 0, CUADROS_MARCHA - 1)]

static func _preparar_pieles() -> void:
	_camuflados = SpriteFrames.new()
	_camuflados.remove_animation(&"default")
	for indice in DIRECCIONES.size():
		var direccion: String = DIRECCIONES[indice]
		var textura: Texture2D
		if direccion == "Abajo":
			# The approved front includes its original large pigment patches.
			textura = FRENTE_CAMUFLADO
		else:
			var original: Texture2D = TEXTURAS[direccion]
			# Imported textures may return a shared Image; recolour only a copy.
			var imagen: Image = original.get_image().duplicate()
			imagen.convert(Image.FORMAT_RGBA8)
			# Only exact palette substitution; no new pixels, shape or opacity.
			for y in imagen.get_height():
				for x in imagen.get_width():
					var color := imagen.get_pixel(x, y)
					if color.a == 0.0: continue
					var reemplazo: Color = REMAPEO.get(color.to_rgba32(), color)
					imagen.set_pixel(x, y, reemplazo)
			textura = ImageTexture.create_from_image(imagen)
		var reposo := "idle_" + direccion.to_lower()
		_camuflados.add_animation(reposo)
		_camuflados.add_frame(reposo, textura)
		_registrar_padding(textura)
		_camuflados.add_animation(direccion)
		for cuadro in CUADROS_MARCHA:
			var paso := _cuadro(MARCHA_CAMUFLADA, indice * CUADROS_MARCHA + cuadro)
			_camuflados.add_frame(direccion, paso)
			_registrar_padding(paso)
	# Same 2px padding as the normal body, preserving shader UV alignment.
	var padded: SpriteFrames = Readability.padded(_camuflados)
	for animacion in padded.get_animation_names():
		var texturas: Array[Texture2D] = []
		for cuadro in padded.get_frame_count(animacion):
			texturas.append(padded.get_frame_texture(animacion, cuadro))
		_pieles[animacion] = texturas

static func limpiar_cache() -> void:
	# Call after releasing bots in tests; preserve other strains' shared caches.
	for clave in _claves_padding:
		Readability.textures.erase(clave)
	for textura: Texture2D in TEXTURAS.values():
		Readability.textures.erase(textura.resource_path)
	_claves_padding.clear()
	_pieles.clear()
	_normales = null
	_camuflados = null
