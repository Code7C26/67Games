extends Node2D
## Percepción acotada + memoria de un punto observado. El movimiento usa la
## navegación existente; jamás lee la posición oculta para actualizar un destino.
const Navegacion = preload("res://scripts/navegacion_simbionte.gd")
const Efecto = preload("res://scripts/efecto_rastreador.gd")
var anfitrion: CharacterBody2D
var parametros: Resource = preload("res://resources/rastreador_config.tres")
var referencia_presa: WeakRef
var ultima_posicion_conocida := Vector2.INF
var memoria_restante := 0.0
var presa_visible := false
var informe_recibido := false
var reevaluaciones := 0
var consultas_candidatos := 0
var observaciones := 0
var informes_emitidos := 0
var revision_restante := 0.0
var observacion_restante := 0.0
var manada_restante := 0.0
var pose_restante := 0.0
var ruta_restante := 0.0
var ruta_local := PackedVector2Array()
var destino_ruta := Vector2.INF
var navegacion: Node2D
var efecto: Node2D
const META_MANADA := &"rastreador_manada"
const META_OBSERVADORES := &"rastreador_observadores"
var miembros: Array[Dictionary] = []
var coordinacion_restante := 0.0
var marca_restante := 0.0
var marca_aplicada := false
var revision_manada := 0.0
var revision_cerco := 0.0
var eje_cerco := Vector2.RIGHT
var cerco_activo := false
var convocatorias := 0
var revisiones_manada := 0
var rutas_cerco := 0

func _ready() -> void:
	efecto = Efecto.new()
	efecto.name = "SenalesRastreador"
	add_child(efecto)
	efecto.configurar(anfitrion.player_duenio)
	# Escalonar adquisiciones iniciales; los demás ticks conservan exactamente1s.
	revision_restante = float(anfitrion.get_index() % 10) * 0.025
	_asegurar_navegacion()

func _nivel(rama: Array) -> int:
	for i in range(rama.size() - 1, -1, -1):
		if anfitrion.tiene_mutacion(rama[i]): return i + 1
	return 0

func factor_deteccion() -> float:
	return maxf(1.0, parametros.multiplicador_deteccion)

func rango_deteccion() -> float:
	var base: float = anfitrion.rango_vision_local()
	if is_instance_valid(anfitrion.map_host) and anfitrion.map_host.has_signal("map_ready"):
		base = parametros.rango_base_navegado
	return base * factor_deteccion()

func memoria() -> float:
	return maxf(0.5, parametros.memoria_persecucion)

func nivel_manada() -> int:
	return _nivel(["olfato_reforzado", "olfato_agudo", "olfato_superior"])

func nivel_cerco() -> int:
	return _nivel(["fijacion_presa", "memoria_persistente", "rastro_tenaz"])

func nivel_marca() -> int:
	return _nivel(["instinto_manada", "rastro_compartido", "caza_coordinada"])

func _valor_nivel(valores: PackedFloat32Array, nivel: int, defecto: float) -> float:
	return valores[mini(nivel - 1, valores.size() - 1)] if nivel > 0 and not valores.is_empty() else defecto

func _valido() -> bool:
	return is_instance_valid(anfitrion) and anfitrion.is_inside_tree() and not anfitrion.is_queued_for_deletion() and anfitrion.is_infected and anfitrion.cepa == "rastreador"

func _activo() -> bool:
	return _valido() and is_instance_valid(anfitrion.map_host) and anfitrion.map_host.has_method("simbionte_en_juego") and anfitrion.map_host.simbionte_en_juego()

func _asegurar_navegacion() -> void:
	if not _valido(): return
	var host: Node2D = anfitrion.map_host
	if not is_instance_valid(host): return
	if host.has_signal("map_ready"):
		navegacion = host.get("npc_navigation")
	else:
		# Una única cuadrícula conservadora por Shopping. Reutiliza el servicio
		# del Simbionte con radio19, sin cambiar la cuadrícula ni IA de otras cepas.
		navegacion = host.get_node_or_null("NavegacionRastreador")
		if navegacion == null:
			navegacion = Navegacion.new()
			navegacion.name = "NavegacionRastreador"
			navegacion.radio_cuerpo = 19.0
			navegacion.limites = host.get_meta("bounds", Rect2(0, 80, 2128, 960))
			host.add_child(navegacion)

func _preparar_consulta() -> bool:
	if not is_instance_valid(navegacion): _asegurar_navegacion()
	if not is_instance_valid(navegacion) or not navegacion.lista: return false
	# Las exclusiones compartidas se actualizan como máximo una vez por tick
	# para todos los rastreadores, no una búsqueda de grupos por candidato.
	var frame := Engine.get_physics_frames()
	if navegacion.get_meta("rastreador_frame", -1) != frame:
		navegacion.actualizar_exclusiones()
		navegacion.set_meta("rastreador_frame", frame)
	return true

func _presa_valida(presa: Node2D) -> bool:
	return is_instance_valid(presa) and presa != anfitrion and presa.is_inside_tree() and not presa.is_queued_for_deletion() and presa.is_in_group("bots") and not presa.is_infected and presa.map_host == anfitrion.map_host and presa.proteccion_coloso <= 0.0 and presa.proteccion_sano_ofensiva <= 0.0 and not is_instance_valid(presa.captor_garfio)

func objetivo_actual() -> Node2D:
	var presa: Node2D = referencia_presa.get_ref() if referencia_presa != null else null
	return presa if _presa_valida(presa) else null

func posicion_persecucion() -> Vector2:
	if maxf(memoria_restante, marca_restante) <= 0.0 or objetivo_actual() == null: return Vector2.INF
	return ultima_posicion_conocida

func en_pose_deteccion() -> bool:
	return pose_restante > 0.0

func _observar(presa: Node2D) -> bool:
	observaciones += 1
	if not _presa_valida(presa) or not _preparar_consulta(): return false
	var punto := presa.global_position
	if anfitrion.global_position.distance_squared_to(punto) > pow(rango_deteccion(), 2.0): return false
	if not navegacion.segmento_libre(anfitrion.global_position, punto): return false
	ultima_posicion_conocida = punto
	memoria_restante = memoria()
	presa_visible = true
	informe_recibido = false
	return true

func _elegir_presa() -> void:
	if not _preparar_consulta(): return
	var contenedor: Node = anfitrion.map_host.get_node_or_null("Bots")
	if contenedor == null: return
	consultas_candidatos += 1
	var vistos: Array[Dictionary] = []
	var alcance2 := pow(rango_deteccion(), 2.0)
	var minimo := INF
	for otro in contenedor.get_children():
		if not _presa_valida(otro): continue
		var punto: Vector2 = otro.global_position
		var distancia: float = anfitrion.global_position.distance_to(punto)
		if distancia * distancia > alcance2: continue
		# Línea despejada para el cuerpo completo implica alcance físico directo;
		# no se elige gente tras una pared ni al otro lado de una piscina.
		if not navegacion.segmento_libre(anfitrion.global_position, punto): continue
		vistos.append({"nodo": otro, "punto": punto, "distancia": distancia})
		minimo = minf(minimo, distancia)
	var elegida: Node2D
	var mejor := INF
	for candidato in vistos:
		# Aislamiento solo desempata distancias similares y solo considera
		# humanos realmente observados, nunca gente oculta fuera del sensor.
		if candidato.distancia > minimo * (1.0 + parametros.preferencia_aislamiento): continue
		var vecinos := 0
		for otro in vistos:
			if otro.nodo != candidato.nodo and candidato.punto.distance_squared_to(otro.punto) < pow(parametros.radio_aislamiento, 2.0): vecinos += 1
		var puntuacion: float = candidato.distancia * (1.0 + parametros.preferencia_aislamiento * float(mini(vecinos, 3)) / 3.0)
		if puntuacion < mejor:
			mejor = puntuacion
			elegida = candidato.nodo
	if elegida != null:
		referencia_presa = weakref(elegida)
		var observadores: Array = elegida.get_meta(META_OBSERVADORES, [])
		observadores.append(weakref(self))
		elegida.set_meta(META_OBSERVADORES, observadores)
		_observar(elegida)
		pose_restante = 0.4
		efecto.fijar()

func actualizar(delta: float) -> void:
	if not _valido():
		cancelar()
		return
	var host: Node = anfitrion.map_host
	if is_instance_valid(host) and host.estado_actual == host.EstadoJuego.FIN:
		cancelar()
		return
	if not _activo(): return
	var dt := maxf(0.0, delta)
	pose_restante = maxf(0.0, pose_restante - dt)
	manada_restante = maxf(0.0, manada_restante - dt)
	marca_restante = maxf(0.0, marca_restante - dt)
	ruta_restante = maxf(0.0, ruta_restante - dt)
	revision_restante -= dt
	observacion_restante -= dt
	memoria_restante = maxf(0.0, memoria_restante - dt)
	var presa := objetivo_actual()
	if referencia_presa != null and presa == null:
		_soltar(true)
		revision_restante = 0.0
	elif presa != null and observacion_restante <= 0.0:
		observacion_restante = maxf(0.05, parametros.intervalo_observacion)
		var contacto_anterior := presa_visible
		presa_visible = false
		_observar(presa)
		if contacto_anterior and not presa_visible: ruta_restante = 0.0
	if referencia_presa != null and maxf(memoria_restante, marca_restante) <= 0.0:
		_soltar(true)
		revision_restante = 0.0
	if revision_restante <= 0.0:
		revision_restante = maxf(0.2, parametros.intervalo_reevaluacion)
		reevaluaciones += 1
		# Fijación estable: no cambia de presa mientras su recuerdo sea válido.
		if objetivo_actual() == null: _elegir_presa()
	# Una marca dura una ventana fija por fijación: observar nunca la renueva.
	if presa_visible and not marca_aplicada and nivel_marca() > 0:
		marca_aplicada = true
		marca_restante = maxf(0.5, _valor_nivel(parametros.duraciones_marca, nivel_marca(), 8.0))
	if presa_visible and manada_restante <= 0.0: _compartir_rastro()
	_actualizar_manada(dt)
	efecto.actualizar_marca(objetivo_actual(), marca_restante, anfitrion.map_host, presa_visible)
	efecto.actualizar(dt, referencia_presa != null and not presa_visible)

func _soltar(indicar: bool) -> void:
	var habia_rastro := referencia_presa != null
	var anterior: Node2D = referencia_presa.get_ref() if referencia_presa != null else null
	if is_instance_valid(anterior):
		var observadores: Array = anterior.get_meta(META_OBSERVADORES, [])
		for referencia in observadores.duplicate():
			if not referencia is WeakRef or referencia.get_ref() == null or referencia.get_ref() == self: observadores.erase(referencia)
		anterior.set_meta(META_OBSERVADORES, observadores)
	_terminar_manada()
	marca_restante = 0.0
	marca_aplicada = false
	referencia_presa = null
	ultima_posicion_conocida = Vector2.INF
	memoria_restante = 0.0
	presa_visible = false
	informe_recibido = false
	ruta_local.clear()
	destino_ruta = Vector2.INF
	if indicar and habia_rastro and is_instance_valid(efecto): efecto.perder()
	if habia_rastro and _valido() and not anfitrion.controlado_por_jugador: anfitrion.cambiar_direccion_aleatoria()

func cancelar() -> void:
	_soltar(false)
	pose_restante = 0.0
	if is_instance_valid(efecto): efecto.limpiar()

func _exit_tree() -> void:
	cancelar()

func _compartir_rastro() -> void:
	var nivel := nivel_manada()
	if nivel <= 0 or informe_recibido or not presa_visible or objetivo_actual() == null or coordinacion_restante > 0.0: return
	# Un Rastreador convocado tampoco puede convertirse en líder de otra manada.
	if coordinador_de(anfitrion) != null: return
	manada_restante = maxf(0.5, parametros.intervalo_manada)
	var limite: int = clampi(parametros.maximo_aliados, 0, 3)
	var radio := _valor_nivel(parametros.radios_manada, nivel, 180.0)
	var aliados: Array[Dictionary] = []
	for aliado in anfitrion.map_host.get_node("Bots").get_children():
		if aliado == anfitrion or not _miembro_disponible(aliado) or coordinador_de(aliado) != null: continue
		var distancia: float = anfitrion.global_position.distance_squared_to(aliado.global_position)
		if distancia <= radio * radio and navegacion.segmento_libre(anfitrion.global_position, aliado.global_position): aliados.append({"nodo": aliado, "distancia": distancia})
	aliados.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distancia < b.distancia)
	for aliado in aliados:
		if miembros.size() >= limite: break
		var bot: Node2D = aliado.nodo
		miembros.append({"bot": weakref(bot), "punto": ultima_posicion_conocida, "destino": ultima_posicion_conocida, "ruta": PackedVector2Array(), "visible": false, "lateral": false})
		bot.set_meta(META_MANADA, weakref(self))
		bot.npc_brain.reset()
		informes_emitidos += 1
	if miembros.is_empty(): return
	anfitrion.set_meta(META_MANADA, weakref(self))
	coordinacion_restante = maxf(0.5, parametros.duracion_manada)
	eje_cerco = anfitrion.global_position.direction_to(ultima_posicion_conocida)
	if eje_cerco.is_zero_approx(): eje_cerco = Vector2.RIGHT
	revision_manada = 0.0
	revision_cerco = 0.0
	convocatorias += 1
	efecto.convocar()

func recibir_rastro(presa: Node2D, posicion: Vector2, edad: float, emisor: Node2D) -> bool:
	# Compatibilidad con herramientas antiguas: sólo un miembro YA asignado puede
	# recibir un punto observado por su líder; este método nunca recluta en cadena.
	var fuente := coordinador_de(anfitrion)
	if fuente == null or fuente == self or fuente.anfitrion != emisor or fuente.objetivo_actual() != presa: return false
	if not fuente.presa_visible or edad < 0.0 or not posicion.is_finite() or fuente.ultima_posicion_conocida != posicion: return false
	var datos: Dictionary = fuente._datos_miembro(anfitrion)
	if datos.is_empty(): return false
	datos.punto = posicion
	return true

func _miembro_disponible(bot: Node2D) -> bool:
	if not is_instance_valid(bot) or not bot.is_inside_tree() or bot.is_queued_for_deletion() or not bot.is_in_group("bots"): return false
	if not bot.is_infected or bot.player_duenio != anfitrion.player_duenio or bot.map_host != anfitrion.map_host: return false
	if bot.controlado_por_jugador or bot.incubacion_contagio > 0.0 or bot._passage_egress_left > 0.0: return false
	if is_instance_valid(bot.captor_garfio) or (is_instance_valid(bot.garfio) and bot.garfio.bloquea_movimiento()): return false
	if is_instance_valid(bot.camaleon) and bot.camaleon.camuflado: return false
	return true

func _datos_miembro(bot: Node2D) -> Dictionary:
	for datos in miembros:
		if datos.bot.get_ref() == bot: return datos
	return {}

func _retirar_miembro(bot: Node2D) -> void:
	for datos in miembros.duplicate():
		var miembro: Node2D = datos.bot.get_ref()
		if miembro != null and miembro != bot: continue
		miembros.erase(datos)
		if is_instance_valid(miembro):
			var referencia: WeakRef = miembro.get_meta(META_MANADA) if miembro.has_meta(META_MANADA) else null
			if referencia != null and referencia.get_ref() == self: miembro.remove_meta(META_MANADA)
			miembro.npc_brain.reset()
			miembro.map_route.clear()
	cerco_activo = false
	revision_cerco = 0.0

func _terminar_manada() -> void:
	for datos in miembros.duplicate(): _retirar_miembro(datos.bot.get_ref())
	miembros.clear()
	coordinacion_restante = 0.0
	cerco_activo = false
	if is_instance_valid(anfitrion):
		var referencia: WeakRef = anfitrion.get_meta(META_MANADA) if anfitrion.has_meta(META_MANADA) else null
		if referencia != null and referencia.get_ref() == self: anfitrion.remove_meta(META_MANADA)
		anfitrion.npc_brain.reset()

static func coordinador_de(bot: Node2D) -> Node2D:
	if not is_instance_valid(bot) or bot.is_queued_for_deletion(): return null
	var referencia: WeakRef = bot.get_meta(META_MANADA) if bot.has_meta(META_MANADA) else null
	var lider: Node2D = referencia.get_ref() if referencia != null else null
	if not is_instance_valid(lider) or lider.is_queued_for_deletion() or not lider._activo() or lider.coordinacion_restante <= 0.0 or lider.objetivo_actual() == null: return null
	if bot != lider.anfitrion and (not lider._miembro_disponible(bot) or lider._datos_miembro(bot).is_empty()): return null
	return lider

static func posicion_manada(bot: Node2D) -> Vector2:
	var lider := coordinador_de(bot)
	if lider == null or bot.controlado_por_jugador: return Vector2.INF
	if bot == lider.anfitrion: return lider.posicion_persecucion()
	var datos: Dictionary = lider._datos_miembro(bot)
	return datos.destino if not datos.is_empty() else Vector2.INF

static func liberar_miembro(bot: Node2D) -> void:
	if not is_instance_valid(bot): return
	var referencia: WeakRef = bot.get_meta(META_MANADA) if bot.has_meta(META_MANADA) else null
	var lider: Node2D = referencia.get_ref() if referencia != null else null
	# La posesión del líder conserva las órdenes; la de un aliado toma prioridad.
	if is_instance_valid(lider) and lider.anfitrion != bot: lider._retirar_miembro(bot)

static func invalidar_bot(bot: Node2D) -> void:
	if not is_instance_valid(bot): return
	liberar_miembro(bot)
	if is_instance_valid(bot.rastreador): bot.rastreador.cancelar()
	var observadores: Array = bot.get_meta(META_OBSERVADORES, [])
	for referencia in observadores.duplicate():
		var observador: Node2D = referencia.get_ref() if referencia is WeakRef else null
		if is_instance_valid(observador): observador.cancelar()
	if bot.has_meta(META_OBSERVADORES): bot.remove_meta(META_OBSERVADORES)

func _actualizar_manada(delta: float) -> void:
	if coordinacion_restante <= 0.0: return
	coordinacion_restante = maxf(0.0, coordinacion_restante - delta)
	if coordinacion_restante <= 0.0 or objetivo_actual() == null or nivel_manada() <= 0:
		_terminar_manada()
		return
	for datos in miembros.duplicate():
		var bot: Node2D = datos.bot.get_ref()
		if not _miembro_disponible(bot): _retirar_miembro(bot)
	if miembros.is_empty():
		_terminar_manada()
		return
	revision_manada -= delta
	revision_cerco -= delta
	if revision_manada <= 0.0 and _preparar_consulta():
		revision_manada = maxf(0.05, parametros.intervalo_observacion)
		revisiones_manada += 1
		var presa := objetivo_actual()
		var compartido := ultima_posicion_conocida
		var nueva_observacion := presa_visible
		for datos in miembros:
			var bot: Node2D = datos.bot.get_ref()
			var radio: float = bot.rastreador.rango_deteccion() if is_instance_valid(bot.rastreador) else (240.0 if anfitrion.map_host.has_signal("map_ready") else bot.rango_vision_local())
			datos.visible = bot.global_position.distance_squared_to(presa.global_position) <= radio * radio and navegacion.segmento_libre(bot.global_position, presa.global_position)
			if datos.visible:
				datos.punto = presa.global_position
				compartido = datos.punto
				nueva_observacion = true
		# Únicamente la marca comparte las observaciones posteriores. Sin ella,
		# cada aliado conserva la convocatoria inicial y lo que percibe por sí mismo.
		if marca_restante > 0.0 and nueva_observacion:
			ultima_posicion_conocida = compartido
			for datos in miembros: datos.punto = compartido
	if revision_cerco <= 0.0:
		revision_cerco = maxf(0.2, parametros.intervalo_ruta)
		_actualizar_destinos()

func _actualizar_destinos() -> void:
	cerco_activo = nivel_cerco() > 0 and miembros.size() >= 2
	var separacion := _valor_nivel(parametros.distancias_cerco, nivel_cerco(), 48.0)
	for indice in miembros.size():
		var datos: Dictionary = miembros[indice]
		var bot: Node2D = datos.bot.get_ref()
		var punto: Vector2 = datos.punto
		var destino := punto
		var lateral := false
		var ruta := PackedVector2Array()
		# El flanco es una aproximación: al entrar en distancia corta se cierra
		# sobre el rastro, en lugar de quedarse estacionado junto a la víctima.
		if cerco_activo and bot.global_position.distance_to(punto) > separacion + 16.0 and _preparar_consulta():
			var offset := eje_cerco.orthogonal() * separacion * (1.0 if indice % 2 == 0 else -1.0)
			if indice == 2: offset = eje_cerco * separacion
			var flanco := punto + offset
			# Validar el último tramo y la ruta completa con la cuadrícula actual.
			if navegacion.segmento_libre(punto, flanco):
				ruta = navegacion.ruta(bot.global_position, flanco)
				rutas_cerco += 1
				if not ruta.is_empty():
					destino = flanco
					lateral = true
		if ruta.is_empty() and _preparar_consulta(): ruta = navegacion.ruta(bot.global_position, punto)
		datos.destino = destino
		datos.ruta = ruta
		datos.lateral = lateral

static func direccion_manada(bot: CharacterBody2D, fallback: Vector2) -> Vector2:
	var lider := coordinador_de(bot)
	if lider == null or bot.controlado_por_jugador or bot._passage_egress_left > 0.0: return fallback
	if bot == lider.anfitrion: return lider.direccion_local(fallback)
	var datos: Dictionary = lider._datos_miembro(bot)
	if datos.is_empty(): return fallback
	var ruta: PackedVector2Array = datos.ruta
	while not ruta.is_empty() and bot.global_position.distance_squared_to(ruta[0]) < 49.0: ruta.remove_at(0)
	while ruta.size() > 1 and lider.navegacion.segmento_libre(bot.global_position, ruta[1]): ruta.remove_at(0)
	datos.ruta = ruta
	bot.map_route = ruta
	return bot.global_position.direction_to(ruta[0]) if not ruta.is_empty() else Vector2.ZERO

func direccion_local(fallback: Vector2) -> Vector2:
	# Shopping conserva sus rutinas de paseo y evasión; únicamente el trayecto
	# hacia el rastro usa la misma ruta/casts conservadores que los otros mapas.
	if not _activo() or anfitrion.controlado_por_jugador or anfitrion._passage_egress_left > 0.0: return fallback
	var punto := posicion_persecucion()
	if not punto.is_finite(): return fallback
	# The latest observation already proved this full-body segment clear. Reuse
	# that direct leg until the next sensor tick rather than recasting/rebuilding
	# identical routes for every visible target. move_and_slide still owns motion.
	if presa_visible:
		ruta_local = PackedVector2Array([punto])
		destino_ruta = punto
		return anfitrion.global_position.direction_to(punto)
	if not _preparar_consulta(): return Vector2.ZERO
	if not presa_visible and anfitrion.global_position.distance_squared_to(punto) < 12.0 * 12.0: return Vector2.ZERO
	if ruta_restante <= 0.0 or not destino_ruta.is_finite() or destino_ruta.distance_squared_to(punto) > 24.0 * 24.0:
		ruta_local = navegacion.ruta(anfitrion.global_position, punto)
		destino_ruta = punto
		ruta_restante = maxf(0.2, parametros.intervalo_ruta)
	while not ruta_local.is_empty() and anfitrion.global_position.distance_squared_to(ruta_local[0]) < 49.0: ruta_local.remove_at(0)
	while ruta_local.size() > 1 and navegacion.segmento_libre(anfitrion.global_position, ruta_local[1]): ruta_local.remove_at(0)
	return anfitrion.global_position.direction_to(ruta_local[0]) if not ruta_local.is_empty() else Vector2.ZERO
