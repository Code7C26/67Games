extends Node2D
## Una tirada por partida; sin cuotas de réplica ni dependencia de los huéspedes.
signal intento_realizado(exito: bool)
signal aparecido
signal generado(bot: Node2D)
signal retirado

const ESCENA = preload("res://scenes/parasito_alfa.tscn")
enum Estado { ESPERA, COLOCACION, ACTIVO, FINALIZADO }
@export var habilitado := true
@export_range(0.0, 1.0) var probabilidad := 0.5
@export_range(0.0, 600.0) var segundo_aparicion := 35.0
@export_range(0.1, 600.0) var duracion := 60.0
@export_range(0.1, 120.0) var intervalo_generacion := 10.0
@export_range(1, 20) var cantidad_inicial := 3
@export var radio_aparicion := 34.0

var mundo: Node
var navegacion: Node2D
var posiciones := PackedVector2Array()
var estado := Estado.ESPERA
var alfa: Node2D
var tiempo_partida := 0.0
var tiempo_activo := 0.0
var siguiente_generacion := 10.0
var reintento := 0.0
var generados := 0
var azar_evento := RandomNumberGenerator.new()
var azar_espacial := RandomNumberGenerator.new()

func _ready() -> void:
	set_physics_process(false)
	azar_evento.randomize()
	azar_espacial.randomize()

func configurar(host: Node) -> void:
	# No reinicializar un controlador ya configurado: evita duplicados accidentales.
	if mundo != null:
		return
	mundo = host
	navegacion = mundo.navegacion_simbionte
	if not habilitado or not is_instance_valid(navegacion):
		finalizar()
		return
	if navegacion.lista:
		_preparar_posiciones()
	else:
		navegacion.preparada.connect(_preparar_posiciones, CONNECT_ONE_SHOT)
	set_physics_process(true)

func _preparar_posiciones() -> void:
	if estado == Estado.FINALIZADO:
		return
	# El Simbionte ya calculó este componente interior con radio de 32 píxeles.
	var candidatas: Array[Vector2] = []
	candidatas.assign(navegacion.posiciones_capullos)
	var centro: Vector2 = navegacion.limites.get_center()
	candidatas.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var da := a.distance_squared_to(centro)
		var db := b.distance_squared_to(centro)
		if not is_equal_approx(da, db):
			return da < db
		return a.y < b.y if a.y != b.y else a.x < b.x)
	posiciones = PackedVector2Array(candidatas)
	# El centro exacto sólo es candidato si está unido al suelo interior conocido.
	# Piscinas, fuentes y muebles conservan sus colisiones: se usa el suelo más cercano.
	if not posiciones.is_empty() and posiciones[0].distance_to(centro) <= 32.0:
		navegacion.actualizar_exclusiones()
		if navegacion.segmento_libre(posiciones[0], centro):
			posiciones.insert(0, centro)

func _physics_process(delta: float) -> void:
	avanzar(delta)

func avanzar(delta: float) -> void:
	if estado == Estado.FINALIZADO:
		return
	if not is_instance_valid(mundo) or mundo.estado_actual == mundo.EstadoJuego.FIN:
		finalizar()
		return
	if not mundo.simbionte_en_juego() or delta < 0.0:
		return
	tiempo_partida += delta
	reintento = maxf(0.0, reintento - delta)
	if estado == Estado.ESPERA:
		if tiempo_partida + 0.00001 < segundo_aparicion:
			return
		var exito := azar_evento.randf() < probabilidad
		estado = Estado.COLOCACION if exito else Estado.FINALIZADO
		intento_realizado.emit(exito)
		if not exito:
			set_physics_process(false)
			return
	if estado == Estado.COLOCACION:
		if reintento <= 0.0:
			reintento = 1.0
			_intentar_aparicion()
		return
	if not is_instance_valid(alfa) or alfa.is_queued_for_deletion():
		finalizar()
		return
	tiempo_activo = minf(duracion, tiempo_activo + delta)
	alfa.avanzar(delta)
	var hasta_nacimiento := siguiente_generacion - tiempo_activo
	if hasta_nacimiento > 0.00001 and hasta_nacimiento <= alfa.ANTICIPACION + 0.00001:
		alfa.preparar_nacimiento(alfa.ANTICIPACION - hasta_nacimiento)
	# Como máximo un nacimiento por actualización. No se acumulan deudas por falta de sitio.
	if tiempo_activo + 0.00001 >= siguiente_generacion and reintento <= 0.0:
		var puntos := _buscar_huespedes(alfa.global_position, 1)
		if not puntos.is_empty():
			_generar(puntos[0])
			var intervalo := maxf(0.1, intervalo_generacion)
			siguiente_generacion = (floorf((tiempo_activo + 0.00001) / intervalo) + 1.0) * intervalo
		else:
			reintento = 1.0
	# El nacimiento del segundo 60 se procesa antes de la retirada.
	if tiempo_activo + 0.00001 >= duracion:
		finalizar()

func posicion_segura(punto: Vector2, radio: float, reservadas: PackedVector2Array = PackedVector2Array()) -> bool:
	if not is_instance_valid(navegacion) or not navegacion.limites.grow(-radio).has_point(punto):
		return false
	var consulta := PhysicsShapeQueryParameters2D.new()
	var huella := CircleShape2D.new()
	huella.radius = radio
	consulta.shape = huella
	consulta.transform = Transform2D(0.0, punto)
	consulta.collision_mask = 1
	consulta.collide_with_areas = false
	if not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty():
		return false
	# Reservas también cubren entidades añadidas durante este mismo tick de física.
	for otro in reservadas:
		if punto.distance_to(otro) < radio + 18.0:
			return false
	for bot in get_tree().get_nodes_in_group("bots"):
		if is_instance_valid(bot) and not bot.is_queued_for_deletion() and mundo.is_ancestor_of(bot) and punto.distance_to(bot.global_position) < radio + 18.0:
			return false
	for capullo in mundo.capullos:
		if is_instance_valid(capullo) and not capullo.is_queued_for_deletion() and punto.distance_to(capullo.global_position) < 90.0:
			return false
	var pasos := mundo.get_node_or_null("PasosEntreExtremos")
	if pasos != null:
		for paso in pasos.get_children():
			if (paso is Area2D or paso is Marker2D) and punto.distance_to(paso.global_position) < 80.0:
				return false
	for grupo in ["simbiontes", "colosos_antivirales", "parasitos_alfa"]:
		for actor in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(actor) and not actor.is_queued_for_deletion() and punto.distance_to(actor.global_position) < radio + 30.0:
				return false
	return true

func _buscar_huespedes(centro: Vector2, cantidad: int) -> PackedVector2Array:
	var resultado := PackedVector2Array()
	navegacion.actualizar_exclusiones()
	var giro := azar_espacial.randf() * TAU
	for radio in [64.0, 88.0, 112.0]:
		for i in 12:
			var punto: Vector2 = centro + Vector2.RIGHT.rotated(giro + TAU * float(i) / 12.0) * radio
			if posicion_segura(punto, 18.0, resultado) and navegacion.segmento_libre(centro, punto):
				resultado.append(punto)
				if resultado.size() == cantidad:
					return resultado
	return PackedVector2Array()

func _intentar_aparicion() -> void:
	if estado != Estado.COLOCACION or posiciones.is_empty() or is_instance_valid(alfa):
		return
	for i in range(mini(64, posiciones.size())):
		var centro := posiciones[i]
		if not posicion_segura(centro, radio_aparicion):
			continue
		var puntos := _buscar_huespedes(centro, cantidad_inicial)
		if puntos.size() != cantidad_inicial:
			continue
		alfa = ESCENA.instantiate()
		alfa.mundo = mundo
		alfa.position = mundo.to_local(centro)
		mundo.add_child(alfa)
		estado = Estado.ACTIVO
		tiempo_activo = 0.0
		siguiente_generacion = maxf(0.1, intervalo_generacion)
		reintento = 0.0
		for punto in puntos:
			_generar(punto)
		aparecido.emit()
		return

func _generar(punto: Vector2) -> void:
	var bot: Node2D = mundo.crear_infectado_alfa(punto)
	if bot != null:
		generados += 1
		alfa.nacimiento()
		generado.emit(bot)

func finalizar() -> void:
	if estado == Estado.FINALIZADO:
		return
	if is_instance_valid(alfa):
		alfa.hide()
		alfa.queue_free()
	alfa = null
	estado = Estado.FINALIZADO
	set_physics_process(false)
	retirado.emit()

func _exit_tree() -> void:
	if is_instance_valid(alfa) and not alfa.is_queued_for_deletion():
		alfa.queue_free()
