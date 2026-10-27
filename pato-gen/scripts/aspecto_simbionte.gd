extends AnimatedSprite2D
## Presentación compartida por el viajero y el anfitrión, en píxeles de 32x32.
const CUADROS = preload("res://resources/animations/simbionte.tres")
const TINTE = preload("res://shaders/simbionte.gdshader")
var direccion: StringName = &"Abajo"
var en_transicion := false
var ultima_velocidad := Vector2.ZERO
var animacion_activa := true

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_frames = CUADROS
	material = ShaderMaterial.new()
	material.shader = TINTE
	animation_finished.connect(_fin_transicion)
	play("reposo_Abajo")

func configurar_equipo(equipo: int) -> void:
	material.set_shader_parameter("color_vena", Color("42c7c8") if equipo == 1 else Color("e489ce"))
	material.set_shader_parameter("color_brillo", Color("a2efe0") if equipo == 1 else Color("ffd1ef"))

func transicionar(nombre: StringName, invertir := false) -> void:
	en_transicion = true
	if invertir:
		play_backwards(nombre)
	else:
		play(nombre)

func actualizar(velocidad: Vector2, en_juego := true) -> void:
	ultima_velocidad = velocidad
	animacion_activa = en_juego
	# Also freeze during the tutorial's held match clock.
	speed_scale = 1.0 if en_juego else 0.0
	if not en_juego:
		return
	if velocidad.length_squared() >= 0.01:
		if absf(velocidad.x) > absf(velocidad.y):
			direccion = &"Derecha" if velocidad.x > 0.0 else &"Izquierda"
		else:
			direccion = &"Abajo" if velocidad.y > 0.0 else &"Arriba"
	if en_transicion:
		return
	var prefijo := "caminar_" if velocidad.length_squared() >= 0.01 else "reposo_"
	play(StringName(prefijo + String(direccion)))
	if prefijo == "caminar_":
		speed_scale = clampf(velocidad.length() / 150.0, 0.75, 1.6)

func _fin_transicion() -> void:
	en_transicion = false
	actualizar(ultima_velocidad, animacion_activa)
