extends CharacterBody2D
## Sanador neutral: sin vida, daño, dueño, infección, ADN ni posesión.
const CuracionRadial = preload("res://scripts/curacion_radial.gd")
const Preferencias = preload("res://scripts/visual_preferences.gd")
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
const DURACION_PULSO := 0.9
const VERDE := Color("b6ef75")
const OSCURO := Color("172b36")
var evento: Node2D
var tratados: Dictionary = {}
var curaciones := 0
var sin_objetivos := 0.0
var hasta_pulso := 1.0
var hasta_ruta := 0.0
var camino := PackedVector2Array()
var pulso_visual := 0.0
var hay_objetivos := true
var tiempo_visual := 0.0
var paso := 0.0
var intensidad_marcha := 0.0
var objetivo_visual: Node2D
@onready var aspecto: Node2D = $Aspecto
@onready var cuerpo: Sprite2D = $Aspecto/Cuerpo
@onready var pie_izquierdo: Sprite2D = $Aspecto/PieIzquierdo
@onready var pie_derecho: Sprite2D = $Aspecto/PieDerecho

func _ready() -> void:
	add_to_group("colosos_antivirales")
	z_index = 5
	hasta_pulso = evento.intervalo_curacion
	_actualizar_colisiones()

func _actualizar_colisiones() -> void:
	for grupo in ["bots", "patos", "robots_curadores", "simbiontes"]:
		for cuerpo in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(cuerpo) and cuerpo is PhysicsBody2D:
				add_collision_exception_with(cuerpo)

func avanzar(delta: float) -> void:
	if not is_instance_valid(evento) or not evento.en_juego():
		return
	pulso_visual = maxf(0.0, pulso_visual - delta)
	hasta_ruta -= delta
	if hasta_ruta <= 0.0:
		_actualizar_colisiones()
		_buscar_ruta()
		hasta_ruta = 1.0
	while not camino.is_empty() and global_position.distance_to(camino[0]) < 2.0:
		camino.remove_at(0)
	# Saltar celdas sólo con barrido de toda la huella, nunca con un rayo central.
	for i in range(mini(camino.size() - 1, 12), 0, -1):
		if evento.navegacion.segmento_libre(global_position, camino[i]):
			for _j in range(i):
				camino.remove_at(0)
			break
	var deseada := Vector2.ZERO
	if not camino.is_empty():
		var desplazamiento := camino[0] - global_position
		deseada = desplazamiento.normalized() * minf(evento.velocidad, desplazamiento.length() / maxf(delta, 0.001))
	# Acelerar y frenar conserva el peso sin giros secos en cada celda de la ruta.
	velocity = velocity.move_toward(deseada, 300.0 * delta)
	if not camino.is_empty():
		velocity = velocity.limit_length(global_position.distance_to(camino[0]) / maxf(delta, 0.001))
	move_and_slide()
	_animar(delta)
	# Sin ráfagas compensatorias tras cuadros lentos: máximo un intento por tick.
	hasta_pulso -= delta
	if hasta_pulso <= 0.0 or is_zero_approx(hasta_pulso):
		hasta_pulso = evento.intervalo_curacion
		var sanado := CuracionRadial.aplicar_coloso(self, evento.radio_curacion, evento.chance_curacion, tratados, evento.azar_curacion, evento.proteccion_sano)
		if sanado != null:
			curaciones += 1
			pulso_visual = DURACION_PULSO
			objetivo_visual = sanado
	# No terminar sólo porque los infectados están lejos: el viaje puede alcanzarlos.
	sin_objetivos = 0.0 if hay_objetivos else sin_objetivos + delta
	queue_redraw()

func _animar(delta: float) -> void:
	tiempo_visual += delta
	intensidad_marcha = move_toward(intensidad_marcha, minf(1.0, velocity.length() / 60.0), delta * 7.0)
	paso += velocity.length() * delta * 0.16
	var zancada := sin(paso) * intensidad_marcha
	var respiracion := sin(tiempo_visual * 2.6)
	if Preferencias.reduced_motion(self):
		zancada *= 0.3
		respiracion = 0.0
	# Las piernas usan regiones de la textura original; no se estira todo el cuerpo.
	pie_izquierdo.position = Vector2(-8.0, 13.5 - maxf(0.0, zancada) * 2.2)
	pie_derecho.position = Vector2(8.0, 13.5 - maxf(0.0, -zancada) * 2.2)
	pie_izquierdo.rotation = zancada * 0.10
	pie_derecho.rotation = -zancada * 0.10
	cuerpo.position.y = -2.5 - absf(zancada) * 0.8 - respiracion * 0.25
	cuerpo.rotation = zancada * 0.022
	cuerpo.scale.y = 1.0 + respiracion * 0.012
	var carga: float = clampf(1.0 - hasta_pulso / maxf(evento.intervalo_curacion, 0.01), 0.0, 1.0)
	cuerpo.self_modulate = Color.WHITE.lerp(Color("d9ffd0"), carga * 0.30)

func _buscar_ruta() -> void:
	var destino_anterior: Vector2 = camino[camino.size() - 1] if not camino.is_empty() else global_position
	camino.clear()
	var objetivos := CuracionRadial.candidatos_coloso(self, INF, tratados)
	hay_objetivos = not objetivos.is_empty()
	if objetivos.is_empty() or evento.posiciones.is_empty():
		return
	var opciones: Array[Dictionary] = []
	# Mantener el destino útil evita que el muestreo haga zigzaguear al sanador.
	var puntos := PackedVector2Array([global_position, destino_anterior])
	# Muestras del interior con la huella del Coloso; no persigue centros dentro de paredes.
	for _i in range(64):
		puntos.append(evento.posiciones[evento.azar_espacial.randi_range(0, evento.posiciones.size() - 1)])
	for punto in puntos:
		var densidad := 0
		for bot in objetivos:
			if punto.distance_squared_to(bot.global_position) <= evento.radio_curacion * evento.radio_curacion:
				densidad += 1
		if densidad > 0:
			opciones.append({"punto": punto, "peso": float(densidad) * 10000.0 - global_position.distance_to(punto)})
	opciones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.peso > b.peso)
	for i in range(mini(8, opciones.size())):
		var visible_desde_destino := false
		for bot in objetivos:
			if opciones[i].punto.distance_to(bot.global_position) <= evento.radio_curacion and CuracionRadial.linea_libre(self, bot.global_position, opciones[i].punto):
				visible_desde_destino = true
				break
		if not visible_desde_destino:
			continue
		var ruta: PackedVector2Array = evento.navegacion.ruta(global_position, opciones[i].punto)
		if not ruta.is_empty():
			camino = ruta
			return

func _draw() -> void:
	if not is_instance_valid(evento):
		return
	var radio: float = evento.radio_curacion
	draw_circle(Vector2.ZERO, radio, Color(VERDE, 0.025))
	draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(VERDE, 0.36), 1.5, true)
	var carga: float = clampf(1.0 - hasta_pulso / maxf(evento.intervalo_curacion, 0.01), 0.0, 1.0)
	draw_arc(Vector2(0, 13), 25.0, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.001, carga), 40, Color(VERDE, 0.8), 2.5, true)
	if pulso_visual > 0.0:
		var fuerza := pulso_visual / DURACION_PULSO
		if not Preferencias.reduced_motion(self):
			draw_arc(Vector2.ZERO, radio * (1.0 - fuerza), 0, TAU, 64, Color(VERDE, fuerza * 0.7), 3.0, true)
		if is_instance_valid(objetivo_visual):
			var destino := to_local(objetivo_visual.global_position)
			draw_line(Vector2(0, -12), destino, Color(VERDE, fuerza * 0.75), 3.0, true)
			draw_arc(destino, 16.0 + (1.0 - fuerza) * 12.0, 0, TAU, 32, Color(VERDE, fuerza), 2.5, true)
			draw_string(FUENTE, destino + Vector2(-28, -30 - (1.0 - fuerza) * 10), "SANO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(VERDE, fuerza))
	draw_ellipse_shadow()
	draw_line(Vector2(0, -37), Vector2(0, -43), VERDE, 2.0, true)
	draw_rect(Rect2(-110, -80, 220, 36), OSCURO)
	draw_rect(Rect2(-110, -80, 220, 36), Color(VERDE, 0.6), false, 1.5)
	draw_string(FUENTE, Vector2(-105, -64), "COLOSO ANTIVIRAL", HORIZONTAL_ALIGNMENT_CENTER, 210, 12, VERDE)
	draw_string(FUENTE, Vector2(-105, -49), "%ds | %d/%d CURADOS" % [ceili(evento.activo_restante), curaciones, evento.max_curaciones], HORIZONTAL_ALIGNMENT_CENTER, 210, 10, Color.WHITE)

func draw_ellipse_shadow() -> void:
	var puntos := PackedVector2Array()
	for i in range(24):
		var angulo := TAU * float(i) / 24.0
		puntos.append(Vector2(cos(angulo) * 24.0, 17.0 + sin(angulo) * 5.0))
	draw_colored_polygon(puntos, Color(0.02, 0.05, 0.06, 0.35))
