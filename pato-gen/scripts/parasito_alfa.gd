extends Node2D
## Organismo fijo y no bloqueante. Sus huéspedes pertenecen al mapa.
const Equipos = preload("res://scripts/equipos_infeccion.gd")
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
const Preferencias = preload("res://scripts/visual_preferences.gd")
const REPOSO = preload("res://shaders/alfa_reposo.gdshader")
const ANTICIPACION := 0.34
# Fotogramas 2–7 de Aseprite; el primero y el último son la misma pose de reposo.
const DURACIONES_LIBERACION: Array[float] = [0.16, 0.18, 0.14, 0.13, 0.17, 0.24]
@onready var aspecto: Sprite2D = $Aspecto
var mundo: Node
var pulso := 0.0
var tiempo_animacion := -1.0
var tiempo_reposo := 0.0
var material_reposo: ShaderMaterial

func _ready() -> void:
	add_to_group("parasitos_alfa")
	z_index = 5
	material_reposo = ShaderMaterial.new()
	material_reposo.shader = REPOSO
	material_reposo.set_shader_parameter("color_latido", Equipos.COLOR_ALFA)
	aspecto.material = material_reposo
	_actualizar_reposo()

func preparar_nacimiento(adelanto: float = 0.0) -> void:
	if tiempo_animacion < 0.0:
		tiempo_animacion = clampf(adelanto, 0.0, ANTICIPACION)
		_actualizar_fotograma()

func avanzar(delta: float) -> void:
	# El controlador usa el reloj de juego: también se congela con el tutorial.
	if is_instance_valid(mundo) and not mundo.simbionte_en_juego():
		return
	var paso := maxf(0.0, delta)
	if not Preferencias.reduced_motion(self):
		tiempo_reposo += paso
	if tiempo_animacion >= 0.0:
		tiempo_animacion += paso
		_actualizar_fotograma()
	pulso = maxf(0.0, pulso - paso)
	_actualizar_reposo()
	queue_redraw()

func _actualizar_reposo() -> void:
	if material_reposo == null:
		return
	material_reposo.set_shader_parameter("tiempo_reposo", tiempo_reposo)
	material_reposo.set_shader_parameter("fotograma", float(aspecto.frame))
	# La apertura dibujada conserva sus poses. El reposo no simula nacimientos.
	var animar := tiempo_animacion < 0.0 and not Preferencias.reduced_motion(self)
	material_reposo.set_shader_parameter("intensidad_reposo", 1.0 if animar else 0.0)

func _actualizar_fotograma() -> void:
	var restante := tiempo_animacion
	for i in DURACIONES_LIBERACION.size():
		if restante + 0.00001 < DURACIONES_LIBERACION[i]:
			aspecto.frame = i + 1
			_actualizar_reposo()
			return
		restante -= DURACIONES_LIBERACION[i]
	tiempo_animacion = -1.0
	aspecto.frame = 0
	_actualizar_reposo()

func nacimiento() -> void:
	# El torso se abre en el mismo tick que se crea el bot real.
	tiempo_animacion = ANTICIPACION
	_actualizar_fotograma()
	pulso = 0.8
	queue_redraw()

func _draw() -> void:
	var verde := Equipos.COLOR_ALFA
	draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 29.0, Color(0.02, 0.08, 0.03, 0.35))
	draw_set_transform(Vector2.ZERO)
	# La criatura conserva sus raíces en la misma posición en todos los fotogramas.
	if pulso > 0.0 and not Preferencias.reduced_motion(self):
		draw_arc(Vector2.ZERO, 30.0 + (1.0 - pulso / 0.8) * 35.0, 0, TAU, 40, Color(verde, pulso), 2.0, true)
	draw_rect(Rect2(-76, -58, 152, 19), Color("12251c"))
	draw_string(FUENTE, Vector2(-71, -44), "PARASITO ALFA", HORIZONTAL_ALIGNMENT_CENTER, 142, 10, verde)
