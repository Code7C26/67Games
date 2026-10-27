extends Node2D
## Estado local de la partida. El HUD y la geometría del mapa no participan.
signal intento_realizado(probabilidad: float, exito: bool)
signal aparecido(numero: int)
signal retirado(motivo: String)

const Navegacion = preload("res://scripts/navegacion_simbionte.gd")
const ESCENA = preload("res://scenes/coloso_antiviral.tscn")
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
enum Estado { ESPERA, AVISO, ACTIVO, FINALIZADO }

@export_range(0.0, 1.0) var umbral_critico := 0.12
@export_range(0.0, 1.0) var umbral_recuperacion := 0.25
@export var segundos_crisis := 5.0
@export var intervalo_intentos := 20.0
@export_range(0.0, 1.0) var chance_primera := 0.60
@export_range(0.0, 1.0) var chance_siguientes := 0.40
@export var max_apariciones := 2
@export var gracia_inicial := 30.0
@export var minimo_tiempo_restante := 25.0
@export var duracion_aviso := 3.0
@export var duracion_maxima := 20.0
@export var recuperacion_sostenida := 3.0
@export var max_curaciones := 12
@export var radio_curacion := 140.0
@export_range(0.0, 1.0) var chance_curacion := 0.80
@export var intervalo_curacion := 1.0
@export var proteccion_sano := 3.0
@export var velocidad := 65.0

var mundo: Node
var poblacion: Dictionary = {}
var poblacion_inicial := 0
var estado := Estado.ESPERA
var apariciones := 0
var tiempo_partida := 0.0
var tiempo_crisis := 0.0
var espera_restante := 0.0
var descanso_restante := 0.0
var aviso_restante := 0.0
var activo_restante := 0.0
var tiempo_recuperado := 0.0
var posicion_aviso := Vector2.ZERO
var coloso: CharacterBody2D
var navegacion: Node2D
var posiciones := PackedVector2Array()
var ancla_interior := Vector2.ZERO
# Flujos separados: rutas y curaciones no cambian la próxima tirada de aparición.
var azar_aparicion := RandomNumberGenerator.new()
var azar_espacial := RandomNumberGenerator.new()
var azar_curacion := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 6
	set_physics_process(false)
	azar_aparicion.randomize()
	azar_espacial.randomize()
	azar_curacion.randomize()

func configurar(host: Node, stats: Dictionary) -> void:
	mundo = host
	poblacion = stats
	poblacion_inicial = int(stats.get("total", 0))
	var ancla := mundo.get_node_or_null("Simbiontes/CapulloCian") as Node2D
	if poblacion_inicial <= 0 or ancla == null:
		estado = Estado.FINALIZADO
		return
	ancla_interior = ancla.global_position
	navegacion = Navegacion.new()
	navegacion.name = "NavegacionColoso"
	navegacion.radio_cuerpo = 20.0
	navegacion.limites = mundo.get_meta("bounds")
	navegacion.preparada.connect(_preparar_posiciones, CONNECT_ONE_SHOT)
	add_child(navegacion)
	set_physics_process(true)

func _preparar_posiciones() -> void:
	if estado != Estado.FINALIZADO:
		posiciones = navegacion.posiciones_transitables(ancla_interior, 28.0)

func en_juego() -> bool:
	return is_instance_valid(mundo) and mundo.simbionte_en_juego()

func en_crisis(stats: Dictionary) -> bool:
	return poblacion_inicial > 0 and int(stats.get("total", 0)) > 0 and int(stats.get("sanos", 0)) <= floori(poblacion_inicial * umbral_critico)

func probabilidad_actual() -> float:
	return chance_primera if apariciones == 0 else chance_siguientes

func _physics_process(delta: float) -> void:
	avanzar(delta, poblacion)

func avanzar(delta: float, stats: Dictionary) -> void:
	if estado == Estado.FINALIZADO:
		return
	if not is_instance_valid(mundo) or mundo.estado_actual == mundo.EstadoJuego.FIN:
		finalizar()
		return
	if not en_juego():
		return
	poblacion = stats
	tiempo_partida += delta
	espera_restante = maxf(0.0, espera_restante - delta)
	descanso_restante = maxf(0.0, descanso_restante - delta)
	if estado == Estado.ACTIVO:
		activo_restante = maxf(0.0, activo_restante - delta)
		var recuperado := int(stats.get("sanos", 0)) >= ceili(poblacion_inicial * umbral_recuperacion)
		tiempo_recuperado = tiempo_recuperado + delta if recuperado else 0.0
		if activo_restante <= 0.0 or is_zero_approx(activo_restante):
			_retirar("duracion")
		elif tiempo_recuperado >= recuperacion_sostenida:
			_retirar("recuperacion")
		elif not is_instance_valid(coloso) or coloso.is_queued_for_deletion():
			_retirar("entidad_retirada")
		elif coloso.curaciones >= max_curaciones:
			_retirar("presupuesto")
		else:
			coloso.avanzar(delta)
			if coloso.curaciones >= max_curaciones:
				_retirar("presupuesto")
			elif coloso.sin_objetivos >= 3.0:
				_retirar("sin_objetivos")
		queue_redraw()
		return
	if estado == Estado.AVISO:
		if not en_crisis(stats) or mundo.timer_juego.time_left <= duracion_maxima:
			_cancelar_aviso()
		else:
			aviso_restante = maxf(0.0, aviso_restante - delta)
			if aviso_restante <= 0.0 or is_zero_approx(aviso_restante):
				_materializar()
		queue_redraw()
		return
	if apariciones >= max_apariciones or mundo.timer_juego.time_left <= minimo_tiempo_restante:
		return
	if tiempo_partida < gracia_inicial or not en_crisis(stats):
		tiempo_crisis = 0.0
		espera_restante = 0.0
		return
	# Un cuadro que cruza la gracia sólo aporta su porción posterior al límite.
	tiempo_crisis += minf(delta, maxf(0.0, tiempo_partida - gracia_inicial))
	if tiempo_crisis + 0.00001 < segundos_crisis or espera_restante > 0.00001 or descanso_restante > 0.00001:
		return
	if not is_instance_valid(navegacion) or not navegacion.lista:
		return
	espera_restante = intervalo_intentos
	var chance := probabilidad_actual()
	var exito := azar_aparicion.randf() < chance
	intento_realizado.emit(chance, exito)
	if not exito:
		return
	var punto: Variant = buscar_aparicion()
	if punto == null:
		return
	posicion_aviso = punto
	aviso_restante = duracion_aviso
	estado = Estado.AVISO
	queue_redraw()

func posicion_segura(punto: Vector2) -> bool:
	if not is_instance_valid(navegacion) or not navegacion.limites.grow(-28.0).has_point(punto):
		return false
	var consulta := PhysicsShapeQueryParameters2D.new()
	var huella := CircleShape2D.new()
	huella.radius = 28.0
	consulta.shape = huella
	consulta.transform = Transform2D(0.0, punto)
	consulta.collision_mask = 1
	consulta.collide_with_areas = false
	if not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty():
		return false
	for capullo in mundo.capullos:
		if is_instance_valid(capullo) and not capullo.is_queued_for_deletion() and punto.distance_to(capullo.global_position) < 90.0:
			return false
	var pasos := mundo.get_node_or_null("PasosEntreExtremos")
	if pasos != null:
		for nodo in pasos.get_children():
			if (nodo is Area2D or nodo is Marker2D) and punto.distance_to(nodo.global_position) < 80.0:
				return false
	return true

func buscar_aparicion() -> Variant:
	if posiciones.is_empty():
		return null
	# Candidatos conectados al interior; búsqueda acotada, sin teletransporte de bots.
	var inicio := azar_espacial.randi_range(0, posiciones.size() - 1)
	for i in range(mini(256, posiciones.size())):
		var punto := posiciones[(inicio + i) % posiciones.size()]
		if posicion_segura(punto):
			return punto
	return null

func _materializar() -> void:
	# La advertencia no reserva físicamente el suelo: validar otra vez antes de crear.
	if estado != Estado.AVISO or apariciones >= max_apariciones or is_instance_valid(coloso):
		return
	if not en_juego() or not en_crisis(mundo.contar_infecciones()) or not posicion_segura(posicion_aviso):
		_cancelar_aviso()
		return
	coloso = ESCENA.instantiate()
	coloso.evento = self
	coloso.position = mundo.to_local(posicion_aviso)
	mundo.add_child(coloso)
	apariciones += 1
	estado = Estado.ACTIVO
	activo_restante = duracion_maxima
	tiempo_recuperado = 0.0
	tiempo_crisis = 0.0
	aparecido.emit(apariciones)

func _cancelar_aviso() -> void:
	estado = Estado.ESPERA
	tiempo_crisis = 0.0
	descanso_restante = intervalo_intentos
	queue_redraw()

func _retirar(motivo: String) -> void:
	if is_instance_valid(coloso):
		coloso.hide()
		coloso.queue_free()
	coloso = null
	estado = Estado.ESPERA if apariciones < max_apariciones else Estado.FINALIZADO
	tiempo_crisis = 0.0
	espera_restante = 0.0
	descanso_restante = intervalo_intentos
	retirado.emit(motivo)
	queue_redraw()

func finalizar() -> void:
	if is_instance_valid(coloso):
		coloso.hide()
		coloso.queue_free()
	coloso = null
	estado = Estado.FINALIZADO
	set_physics_process(false)
	queue_redraw()

func _exit_tree() -> void:
	if is_instance_valid(coloso) and not coloso.is_queued_for_deletion():
		coloso.queue_free()

func _draw() -> void:
	if estado != Estado.AVISO:
		return
	var centro := to_local(posicion_aviso)
	var color := Color("b6ef75")
	draw_circle(centro, 34.0, Color(color, 0.12))
	draw_arc(centro, 34.0, 0, TAU, 48, color, 2.0, true)
	draw_line(centro + Vector2(-12, 0), centro + Vector2(12, 0), color, 3)
	draw_line(centro + Vector2(0, -12), centro + Vector2(0, 12), color, 3)
	draw_rect(Rect2(centro + Vector2(-120, -65), Vector2(240, 24)), Color("172b36"))
	draw_string(FUENTE, centro + Vector2(-116, -48), "COLOSO EN %ds" % ceili(aviso_restante), HORIZONTAL_ALIGNMENT_CENTER, 232, 12, color)
