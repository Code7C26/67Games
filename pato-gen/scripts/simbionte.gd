extends CharacterBody2D
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
const Equipos = preload("res://scripts/equipos_infeccion.gd")
const Readability = preload("res://scripts/npc_readability.gd")
const TINTE_VIAJERO = preload("res://shaders/simbionte_viajero.gdshader")
const Preferencias = preload("res://scripts/visual_preferences.gd")
var mundo: Node
var navegacion: Node2D
var equipo: int = 1
var velocidad: float = 100.0
var objetivo: Node2D
var camino := PackedVector2Array()
var recalculo := 0.0
var fusionado := false
var tiempo_fusion: float = 20.0
var huesped_anterior_id: int = 0
var hilo_objetivo: Line2D
var fase_hilo := 0.0
@onready var contacto: Area2D = $Contacto
@onready var aspecto: AnimatedSprite2D = $Aspecto

func _ready() -> void:
	add_to_group("simbiontes")
	z_index = 4
	# Only this traveller scene gains the outline and enlarged presentation.
	aspecto.sprite_frames = Readability.padded(aspecto.sprite_frames)
	var tinte := ShaderMaterial.new()
	tinte.shader = TINTE_VIAJERO
	tinte.set_shader_parameter("color_contorno", Equipos.color_equipo(equipo))
	aspecto.material = tinte
	aspecto.configurar_equipo(equipo)
	aspecto.transicionar(&"eclosion")
	hilo_objetivo = Line2D.new()
	hilo_objetivo.name = "HiloObjetivo"
	hilo_objetivo.width = 2.5
	hilo_objetivo.default_color = Color(Equipos.color_equipo(equipo), 0.8)
	hilo_objetivo.antialiased = true
	hilo_objetivo.z_index = -1
	add_child(hilo_objetivo)
	hilo_objetivo.hide()
	_actualizar_colisiones()

func _actualizar_colisiones() -> void:
	# Same physical walls, but actor bodies cannot pin the traveller in a crowd.
	for grupo in ["bots", "patos", "robots_curadores"]:
		for cuerpo in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(cuerpo) and cuerpo is PhysicsBody2D:
				add_collision_exception_with(cuerpo)

func objetivo_valido(bot: Variant) -> bool:
	# Variant lets a just-freed target reach the validity guard instead of failing a cast.
	return is_instance_valid(bot) and bot is Node2D and not bot.is_queued_for_deletion() and bot.get_instance_id() != huesped_anterior_id and bot.is_inside_tree() and is_instance_valid(mundo) and mundo.is_ancestor_of(bot) and bot.is_in_group("bots") and bot.is_infected and bot.player_duenio == equipo

func buscar_objetivo() -> void:
	objetivo = null
	var distancia := INF
	for bot in get_tree().get_nodes_in_group("bots"):
		if not objetivo_valido(bot):
			continue
		var d: float = global_position.distance_squared_to(bot.global_position)
		if d < distancia:
			distancia = d
			objetivo = bot
	camino.clear()
	recalculo = 0.0
	_actualizar_hilo()

func _physics_process(delta: float) -> void:
	_avanzar_viaje(delta)
	if not fusionado:
		aspecto.actualizar(velocity, is_instance_valid(mundo) and mundo.simbionte_en_juego())
		if is_instance_valid(mundo) and mundo.simbionte_en_juego():
			fase_hilo = fmod(fase_hilo + delta * 4.0, TAU)
		_actualizar_hilo()
		queue_redraw()

func _actualizar_hilo() -> void:
	if not is_instance_valid(hilo_objetivo):
		return
	if fusionado or not objetivo_valido(objetivo):
		hilo_objetivo.clear_points()
		hilo_objetivo.hide()
		return
	var inicio := Vector2(0, -10)
	var fin := to_local(objetivo.global_position) + Vector2(0, -10)
	var direccion := fin - inicio
	var normal := direccion.orthogonal().normalized()
	var amplitud := minf(5.0, direccion.length() * 0.025)
	var reducida := Preferencias.reduced_motion(self)
	var puntos := PackedVector2Array()
	for i in range(25):
		var t := float(i) / 24.0
		var onda := 0.0 if reducida else sin(t * TAU * 2.0 - fase_hilo) * sin(t * PI) * amplitud
		puntos.append(inicio.lerp(fin, t) + normal * onda)
	hilo_objetivo.points = puntos
	hilo_objetivo.show()

func _avanzar_viaje(delta: float) -> void:
	if fusionado or not is_instance_valid(mundo) or not is_instance_valid(navegacion):
		return
	if not mundo.simbionte_en_juego():
		velocity = Vector2.ZERO
		return
	if not objetivo_valido(objetivo):
		buscar_objetivo()
	if objetivo == null:
		velocity = Vector2.ZERO
		return
	if intentar_fusion():
		return
	recalculo -= delta
	if recalculo <= 0.0:
		_actualizar_colisiones()
		camino = navegacion.ruta(global_position, objetivo.global_position)
		recalculo = 0.35
	while not camino.is_empty() and global_position.distance_to(camino[0]) < 2.0:
		camino.remove_at(0)
	if camino.is_empty():
		velocity = Vector2.ZERO
		return
	# Smooth corners only when the entire body fits, not just a ray to the centre.
	for i in range(mini(camino.size() - 1, 12), 0, -1):
		if navegacion.segmento_libre(global_position, camino[i]):
			for _j in range(i):
				camino.remove_at(0)
			break
	var desplazamiento := camino[0] - global_position
	velocity = desplazamiento.normalized() * minf(velocidad, desplazamiento.length() / maxf(delta, 0.001))
	move_and_slide()

func intentar_fusion() -> bool:
	if fusionado or not objetivo_valido(objetivo) or not mundo.simbionte_en_juego():
		return false
	if not contacto.overlaps_body(objetivo):
		return false
	# Even a thin wall between overlapping shapes prevents a remote fusion.
	navegacion.actualizar_exclusiones()
	if not navegacion.segmento_libre(global_position, objetivo.global_position):
		return false
	if not objetivo.aplicar_simbionte(mundo, equipo, tiempo_fusion):
		return false
	# One free entry belongs only to the actual second fusion, never to the search.
	objetivo.efecto_simbionte.entrada_inmediata_disponible = huesped_anterior_id != 0
	fusionado = true
	_actualizar_hilo()
	velocity = Vector2.ZERO
	hide()
	queue_free()
	return true

func _draw() -> void:
	var color := Equipos.color_equipo(equipo)
	draw_rect(Rect2(-16, 14, 32, 4), Color(0.03, 0.06, 0.09, 0.32))
	var titulo := Rect2(-96, -76, 192, 34)
	if is_instance_valid(mundo) and mundo.has_meta("bounds"):
		var limites: Rect2 = mundo.get_meta("bounds")
		var punto: Vector2 = mundo.to_local(global_position)
		titulo.position.x = clampf(punto.x - 96, limites.position.x + 4, limites.end.x - 196) - punto.x
		if punto.y - 76 < limites.position.y + 4:
			titulo.position.y = 34
	draw_rect(titulo, Color("172b36"))
	draw_rect(titulo, Color(color, 0.7), false, 1.0)
	var inicio := titulo.position + Vector2(96, 34 if titulo.position.y < 0 else 0)
	draw_line(inicio, Vector2(0, -35 if titulo.position.y < 0 else 18), color, 2.0, true)
	draw_string(FUENTE, titulo.position + Vector2(4, 15), "SIMBIONTE LIBRE", HORIZONTAL_ALIGNMENT_CENTER, 184, 11, color)
	var estado := "EN CAMINO A FUSIÓN" if is_instance_valid(objetivo) else "BUSCANDO ALIADO"
	draw_string(FUENTE, titulo.position + Vector2(4, 29), estado, HORIZONTAL_ALIGNMENT_CENTER, 184, 9, Color.WHITE)
