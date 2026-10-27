extends CharacterBody2D
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
var mundo: Node
var navegacion: Node2D
var equipo: int = 1
var velocidad: float = 100.0
var objetivo: Node2D
var camino := PackedVector2Array()
var recalculo := 0.0
var fusionado := false
@onready var contacto: Area2D = $Contacto
@onready var aspecto: AnimatedSprite2D = $Aspecto

func _ready() -> void:
	add_to_group("simbiontes")
	z_index = 4
	aspecto.configurar_equipo(equipo)
	aspecto.transicionar(&"eclosion")
	_actualizar_colisiones()

func _actualizar_colisiones() -> void:
	# Same physical walls, but actor bodies cannot pin the traveller in a crowd.
	for grupo in ["bots", "patos", "robots_curadores"]:
		for cuerpo in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(cuerpo) and cuerpo is PhysicsBody2D:
				add_collision_exception_with(cuerpo)

func objetivo_valido(bot: Node2D) -> bool:
	return is_instance_valid(bot) and not bot.is_queued_for_deletion() and bot.is_inside_tree() and is_instance_valid(mundo) and mundo.is_ancestor_of(bot) and bot.is_in_group("bots") and bot.is_infected and bot.player_duenio == equipo

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

func _physics_process(delta: float) -> void:
	_avanzar_viaje(delta)
	if not fusionado:
		aspecto.actualizar(velocity, is_instance_valid(mundo) and mundo.simbionte_en_juego())
		queue_redraw()

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
	if not objetivo.aplicar_simbionte(mundo, equipo):
		return false
	fusionado = true
	velocity = Vector2.ZERO
	hide()
	queue_free()
	return true

func _draw() -> void:
	var color := Color("58d8d8") if equipo == 1 else Color("e489ce")
	draw_rect(Rect2(-7, 11, 14, 3), Color(0.03, 0.06, 0.09, 0.25))
	if objetivo == null:
		draw_string(FUENTE, Vector2(-80, -23), "BUSCANDO ALIADO", HORIZONTAL_ALIGNMENT_CENTER, 160, 11, color)
