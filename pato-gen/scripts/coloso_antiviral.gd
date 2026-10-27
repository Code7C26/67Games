extends CharacterBody2D
## Sanador neutral: sin vida, daño, dueño, infección, ADN ni posesión.
const CuracionRadial = preload("res://scripts/curacion_radial.gd")
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
var evento: Node2D
var tratados: Dictionary = {}
var curaciones := 0
var sin_objetivos := 0.0
var hasta_pulso := 1.0
var hasta_ruta := 0.0
var camino := PackedVector2Array()
var pulso_visual := 0.0
var paso := 0.0
var hay_objetivos := true

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
	paso += delta
	pulso_visual = maxf(0.0, pulso_visual - delta)
	hasta_ruta -= delta
	if hasta_ruta <= 0.0:
		_actualizar_colisiones()
		_buscar_ruta()
		hasta_ruta = 2.0
	while not camino.is_empty() and global_position.distance_to(camino[0]) < 2.0:
		camino.remove_at(0)
	velocity = Vector2.ZERO
	if not camino.is_empty():
		var desplazamiento := camino[0] - global_position
		velocity = desplazamiento.normalized() * minf(evento.velocidad, desplazamiento.length() / maxf(delta, 0.001))
		move_and_slide()
	# Sin ráfagas compensatorias tras cuadros lentos: máximo un intento por tick.
	hasta_pulso -= delta
	if hasta_pulso <= 0.0 or is_zero_approx(hasta_pulso):
		hasta_pulso = evento.intervalo_curacion
		var sanado := CuracionRadial.aplicar_coloso(self, evento.radio_curacion, evento.chance_curacion, tratados, evento.azar_curacion, evento.proteccion_sano)
		if sanado != null:
			curaciones += 1
			pulso_visual = 0.6
	# No terminar sólo porque los infectados están lejos: el viaje puede alcanzarlos.
	sin_objetivos = 0.0 if hay_objetivos else sin_objetivos + delta
	queue_redraw()

func _buscar_ruta() -> void:
	camino.clear()
	var objetivos := CuracionRadial.candidatos_coloso(self, INF, tratados)
	hay_objetivos = not objetivos.is_empty()
	if objetivos.is_empty() or evento.posiciones.is_empty():
		return
	var opciones: Array[Dictionary] = []
	var puntos := PackedVector2Array([global_position])
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
	var verde := Color("b6ef75")
	var oscuro := Color("172b36")
	var radio: float = evento.radio_curacion
	draw_circle(Vector2.ZERO, radio, Color(verde, 0.045))
	draw_arc(Vector2.ZERO, radio, 0, TAU, 64, Color(verde, 0.32), 1.0, true)
	if pulso_visual > 0.0:
		draw_arc(Vector2.ZERO, radio * (1.0 - pulso_visual / 0.6), 0, TAU, 48, Color(verde, pulso_visual), 3.0, true)
	# Silueta provisional legible en el mapa: caparazón neutro y cruz antiviral.
	draw_ellipse_shadow()
	var balanceo := sin(paso * 6.0) * 2.0 if velocity.length_squared() > 1.0 else 0.0
	for lado in [-1, 1]:
		draw_rect(Rect2(Vector2(lado * 18 - 9, 9 + balanceo * lado), Vector2(18, 17)), oscuro)
		draw_rect(Rect2(Vector2(lado * 27 - 6, -18 - balanceo * lado), Vector2(12, 27)), Color("6f8987"))
	draw_circle(Vector2(0, -7), 27, oscuro)
	draw_circle(Vector2(0, -9), 23, Color("d0d8bc"))
	draw_arc(Vector2(0, -9), 20, -PI, 0, 24, verde, 4.0, true)
	draw_rect(Rect2(-18, -27, 36, 12), oscuro)
	draw_rect(Rect2(-12, -24, 24, 5), verde)
	draw_rect(Rect2(-4, -12, 8, 23), verde)
	draw_rect(Rect2(-11, -5, 22, 8), verde)
	draw_rect(Rect2(-92, -72, 184, 29), oscuro)
	draw_string(FUENTE, Vector2(-88, -59), "COLOSO ANTIVIRAL", HORIZONTAL_ALIGNMENT_CENTER, 176, 10, verde)
	draw_string(FUENTE, Vector2(-88, -47), "%ds  |  %d SANOS" % [ceili(evento.activo_restante), int(evento.poblacion.get("sanos", 0))], HORIZONTAL_ALIGNMENT_CENTER, 176, 8, Color.WHITE)

func draw_ellipse_shadow() -> void:
	var puntos := PackedVector2Array()
	for i in range(24):
		var angulo := TAU * float(i) / 24.0
		puntos.append(Vector2(cos(angulo) * 35.0, 20.0 + sin(angulo) * 10.0))
	draw_colored_polygon(puntos, Color(0.02, 0.05, 0.06, 0.35))
