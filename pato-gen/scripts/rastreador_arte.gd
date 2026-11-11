extends RefCounted
## Animaciones de32px derivadas del diseño aprobado v02. SpriteFrames y atlas
## se comparten; la orientación y el flanco de detección pertenecen a cada bot.
const Preferencias = preload("res://scripts/visual_preferences.gd")
const ATLAS = preload("res://assets/rastreador/rastreador_animaciones.png")
const DIRECCIONES := ["abajo", "arriba", "derecha", "izquierda"]
const TIPOS := ["idle", "caminar", "detectar"]
const VELOCIDADES := [4.0, 8.0, 10.0]
const ALIASES := {"Abajo": "abajo", "Arriba": "arriba", "Derecha": "derecha", "Izquierda": "izquierda"}
const TAMANO := 32
const COLUMNAS := 8
const CUADROS_POR_CLIP := 4
const TEXTURAS := {
	"Abajo": preload("res://assets/rastreador/rastreador_abajo.png"),
	"Arriba": preload("res://assets/rastreador/rastreador_arriba.png"),
	"Derecha": preload("res://assets/rastreador/rastreador_derecha.png"),
	"Izquierda": preload("res://assets/rastreador/rastreador_izquierda.png"),
	"Detectar": preload("res://assets/rastreador/rastreador_detectar.png")
}
static var cache: SpriteFrames

static func frames() -> SpriteFrames:
	if cache != null: return cache
	cache = SpriteFrames.new()
	cache.remove_animation("default")
	for vista in DIRECCIONES.size():
		for tipo in TIPOS.size():
			var nombre := "%s_%s" % [TIPOS[tipo], DIRECCIONES[vista]]
			cache.add_animation(nombre)
			cache.set_animation_loop(nombre, TIPOS[tipo] != "detectar")
			cache.set_animation_speed(nombre, VELOCIDADES[tipo])
			for cuadro in CUADROS_POR_CLIP:
				var indice: int = vista * 12 + tipo * CUADROS_POR_CLIP + cuadro
				var textura := AtlasTexture.new()
				textura.atlas = ATLAS
				textura.region = Rect2((indice % COLUMNAS) * TAMANO, floori(float(indice) / COLUMNAS) * TAMANO, TAMANO, TAMANO)
				cache.add_frame(nombre, textura)
	# Poses originales para compatibilidad de infección, retratos y herramientas.
	# El controlador pasa a idle/caminar/detectar en la siguiente actualización.
	for nombre in TEXTURAS:
		cache.add_animation(nombre)
		cache.set_animation_loop(nombre, false)
		cache.add_frame(nombre, TEXTURAS[nombre])
	return cache

static func animar(sprite: AnimatedSprite2D, direccion: Vector2, detectando: bool = false) -> void:
	var actual := String(sprite.animation)
	var orientacion := String(sprite.get_meta("rastreador_orientacion", "abajo"))
	if ALIASES.has(actual):
		orientacion = ALIASES[actual]
	else:
		for vista in DIRECCIONES:
			if actual.ends_with("_" + vista): orientacion = vista; break
	var caminando := direccion.length_squared() > 0.01
	if caminando:
		if absf(direccion.x) > absf(direccion.y):
			orientacion = "derecha" if direccion.x > 0.0 else "izquierda"
		else:
			orientacion = "abajo" if direccion.y > 0.0 else "arriba"
	if orientacion not in DIRECCIONES: orientacion = "abajo"
	sprite.set_meta("rastreador_orientacion", orientacion)
	var detectaba := bool(sprite.get_meta("rastreador_detectaba", false))
	# Una pose original indica una entrada nueva desde humano/otra cepa.
	if ALIASES.has(actual) or actual == "Detectar": detectaba = false
	sprite.set_meta("rastreador_detectaba", detectando)
	var reducido := Preferencias.reduced_motion(sprite)
	var gesto := "detectar_" + orientacion
	if not reducido and detectando and not detectaba:
		sprite.play(gesto)
		return
	if not reducido and detectando and actual.begins_with("detectar_") and sprite.is_playing():
		if actual != gesto:
			# Girar durante el gesto conserva su fase; no repite la detección.
			var cuadro := sprite.frame
			var progreso := sprite.frame_progress
			sprite.play(gesto)
			sprite.set_frame_and_progress(cuadro, progreso)
		return
	var deseada := ("caminar_" if caminando else "idle_") + orientacion
	if reducido and not caminando:
		if actual != deseada: sprite.animation = deseada
		sprite.frame = 0
		if sprite.is_playing(): sprite.stop()
		return
	# Repetir animar cada tick no vuelve al primer cuadro de la misma marcha.
	if actual != deseada or not sprite.is_playing(): sprite.play(deseada)

static func limpiar_cache() -> void:
	cache = null
