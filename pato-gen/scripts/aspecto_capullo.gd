extends AnimatedSprite2D
## Animation only. Final remnants belong to the current map and own no gameplay.
const CUADROS = preload("res://resources/animations/capullo.tres")
const TINTE = preload("res://shaders/capullo.gdshader")
const Readability = preload("res://scripts/npc_readability.gd")
const Equipos = preload("res://scripts/equipos_infeccion.gd")
var mundo: Node
var inquieto := false
var terminal := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_frames = Readability.padded(CUADROS)
	var tinte := ShaderMaterial.new()
	tinte.shader = TINTE
	material = tinte
	animation_finished.connect(_al_terminar)
	play(&"reposo")

func configurar_equipo(equipo: int) -> void:
	material.set_shader_parameter("color_contorno", Equipos.color_equipo(equipo))
	material.set_shader_parameter("vena", Color("253d69") if equipo == 1 else Color("49334a"))
	material.set_shader_parameter("pulso", Color("3b60a0") if equipo == 1 else Color("69486b"))
	material.set_shader_parameter("brillo", Color("86abef") if equipo == 1 else Color("967095"))

func latir() -> void:
	if not terminal:
		play(&"inversion")
		set_frame_and_progress(0, 0.0)

func finalizar(gano: bool) -> void:
	terminal = true
	add_to_group("restos_capullo")
	play(&"eclosion" if gano else &"marchitar")

func _process(_delta: float) -> void:
	if not is_instance_valid(mundo):
		speed_scale = 0.0
		return
	if mundo.estado_actual == mundo.EstadoJuego.FIN:
		if terminal:
			queue_free()
		speed_scale = 0.0
		return
	speed_scale = 1.0 if mundo.simbionte_en_juego() or mundo.estado_actual == mundo.EstadoJuego.FASE_PATOS else 0.0
	if terminal:
		self_modulate.a = 0.45 if frame == 5 else (0.75 if frame == 4 else 1.0)
	elif animation != &"inversion":
		play(&"inquieto" if inquieto else &"reposo")

func _al_terminar() -> void:
	if terminal:
		queue_free()
	else:
		play(&"inquieto" if inquieto else &"reposo")
