extends Node2D
## Captura física; al llegar delega una sola tirada al sistema normal de infección.
enum Estado { LISTO, PREPARANDO, EXTENDIENDO, ARRASTRANDO, RECUPERANDO }

var anfitrion: CharacterBody2D
var parametros: Resource = preload("res://resources/garfio_config.tres")
var objetivo: Node2D
var estado := Estado.LISTO
var recarga_restante := 0.0
var tiempo_estado := 0.0
var punta_global := Vector2.ZERO
var direccion_disparo := Vector2.DOWN
var direccion_visual := "abajo"
var extension := 0.0
var bloqueo_restante := 0.0
var hasta_busqueda := 0.0
var punta: Texture2D
var tiempo_arrastre := 0.0
var intento_realizado := false
var impacto_restante := 0.0
var impacto_global := Vector2.ZERO
## El segundo tendón reutiliza esta misma captura, con reserva y colisiones propias.
## Sólo el principal decide cuándo atacar y administra contagios/enfriamiento.
var principal: Node2D = null
var segundo_tendon: Node2D = null
var ataque_doble := false
var recarga_iniciada := false
var reenganche_activado := false
var reenganche_restante := 0.0
var cadencia_restante := 0.0
var capturas: Array[Dictionary] = []
const PresaVulnerable = preload("res://scripts/presa_vulnerable.gd")

func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	punta = load("res://assets/garfio/punta_garfio.png")
	# Desfase por huésped: evita que toda una colonia ataque en el mismo fotograma.
	hasta_busqueda = float(anfitrion.get_index() % 7) * 0.04

func alcance() -> float:
	return parametros.alcance_base

func recarga() -> float:
	return parametros.enfriamiento

func velocidad_arrastre() -> float:
	return parametros.velocidad_arrastre / factor_doble()

func bono_virulento() -> float:
	# Compatibilidad de la API: la bonificación ahora exige una captura registrada.
	return 0.0

func nivel_vulnerable() -> int:
	return _nivel(["tendon_reforzado", "ligamentos_elasticos", "alcance_predador"])

func nivel_doble() -> int:
	return _nivel(["arrastre_brutal", "anclaje_tenaz", "traccion_brutal"])

func nivel_reenganche() -> int:
	return _nivel(["gancho_virulento", "inoculo_dirigido", "garra_patogena"])

func _valor_nivel(valores: PackedFloat32Array, nivel: int, defecto: float) -> float:
	return valores[mini(nivel - 1, valores.size() - 1)] if nivel > 0 and not valores.is_empty() else defecto

func _lider() -> Node2D:
	return principal if is_instance_valid(principal) else self

func factor_doble() -> float:
	if not _lider().ataque_doble: return 1.0
	return maxf(1.0, _valor_nivel(parametros.factores_duracion_doble, nivel_doble(), 1.25))

func duracion_arrastre() -> float:
	return parametros.duracion_max_arrastre * factor_doble()

func _segundo_activo() -> bool:
	return is_instance_valid(segundo_tendon) and segundo_tendon.estado != Estado.LISTO

func _nivel(rama: Array) -> int:
	for index in range(rama.size() - 1, -1, -1):
		if anfitrion.tiene_mutacion(rama[index]): return index + 1
	return 0

func _anfitrion_valido() -> bool:
	return is_instance_valid(anfitrion) and not anfitrion.is_queued_for_deletion() and anfitrion.is_inside_tree() and anfitrion.is_infected and anfitrion.cepa == "garfio"

func _partida_activa() -> bool:
	return _anfitrion_valido() and is_instance_valid(anfitrion.map_host) and anfitrion.map_host.simbionte_en_juego()

func _objetivo_valido(candidato) -> bool:
	if not is_instance_valid(candidato) or candidato == anfitrion or candidato.is_queued_for_deletion() or not candidato.is_inside_tree(): return false
	if not candidato.is_in_group("bots") or candidato.is_infected or candidato.controlado_por_jugador: return false
	if candidato.proteccion_coloso > 0.0 or candidato.proteccion_sano_ofensiva > 0.0: return false
	if candidato.map_host != anfitrion.map_host: return false
	if is_instance_valid(candidato.captor_garfio) and candidato.captor_garfio != self: return false
	return true

func _linea_libre(desde: Vector2, hasta: Vector2, candidato: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(desde, hasta, anfitrion.collision_mask)
	query.exclude = [anfitrion.get_rid(), candidato.get_rid()]
	query.collide_with_areas = false
	return anfitrion.get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func intentar_enganche(candidato) -> bool:
	if not _partida_activa() or estado != Estado.LISTO or recarga_restante > 0.0 or anfitrion.incubacion_contagio > 0.0: return false
	if principal == null and _segundo_activo(): return false
	if not _objetivo_valido(candidato): return false
	var distancia := anfitrion.global_position.distance_to(candidato.global_position)
	if distancia < parametros.distancia_minima or distancia > alcance(): return false
	# La marcha apunta; quieto conserva la orientación del último movimiento.
	if anfitrion.controlado_por_jugador:
		var apuntar: Vector2 = anfitrion.direccion_control_jugador
		if apuntar.length_squared() < 0.01:
			apuntar = {"abajo": Vector2.DOWN, "arriba": Vector2.UP, "izquierda": Vector2.LEFT, "derecha": Vector2.RIGHT}[direccion_visual]
		if apuntar.dot(anfitrion.global_position.direction_to(candidato.global_position)) < 0.5: return false
	if not _linea_libre(anfitrion.global_position, candidato.global_position, candidato): return false
	objetivo = candidato
	objetivo.captor_garfio = self
	estado = Estado.PREPARANDO
	tiempo_estado = 0.0
	tiempo_arrastre = 0.0
	intento_realizado = false
	punta_global = anfitrion.global_position
	direccion_disparo = anfitrion.global_position.direction_to(objetivo.global_position)
	if principal == null:
		recarga_iniciada = false
		reenganche_activado = false
		ataque_doble = false
		if nivel_doble() > 0: _enganchar_segundo(candidato)
	queue_redraw()
	return true

func _enganchar_segundo(primera_presa: Node2D) -> void:
	if not is_instance_valid(segundo_tendon):
		segundo_tendon = get_script().new()
		segundo_tendon.anfitrion = anfitrion
		segundo_tendon.principal = self
		segundo_tendon.parametros = parametros
		segundo_tendon.name = "SegundoTendon"
		add_child(segundo_tendon)
	segundo_tendon.parametros = parametros
	segundo_tendon.recarga_restante = 0.0
	segundo_tendon.direccion_visual = direccion_visual
	var candidatos: Array[Node2D] = []
	for candidato in get_tree().get_nodes_in_group("bots"):
		if candidato != primera_presa and _objetivo_valido(candidato) and anfitrion.global_position.distance_squared_to(candidato.global_position) <= alcance() * alcance():
			candidatos.append(candidato)
	candidatos.sort_custom(func(a: Node2D, b: Node2D) -> bool: return anfitrion.global_position.distance_squared_to(a.global_position) < anfitrion.global_position.distance_squared_to(b.global_position))
	for candidato in candidatos:
		if segundo_tendon.intentar_enganche(candidato):
			ataque_doble = true
			return

func activar_manual() -> bool:
	if not _anfitrion_valido() or not anfitrion.controlado_por_jugador:
		return false
	return _buscar_objetivo()

func _buscar_objetivo() -> bool:
	var candidatos: Array[Node2D] = []
	for candidato in get_tree().get_nodes_in_group("bots"):
		if _objetivo_valido(candidato) and anfitrion.global_position.distance_squared_to(candidato.global_position) <= alcance() * alcance():
			candidatos.append(candidato)
	candidatos.sort_custom(func(a: Node2D, b: Node2D) -> bool: return anfitrion.global_position.distance_squared_to(a.global_position) < anfitrion.global_position.distance_squared_to(b.global_position))
	for candidato in candidatos:
		if intentar_enganche(candidato): return true
	return false

func actualizar(delta: float) -> void:
	if not _anfitrion_valido():
		cancelar()
		return
	if is_instance_valid(anfitrion.map_host) and anfitrion.map_host.estado_actual == anfitrion.map_host.EstadoJuego.FIN:
		cancelar()
		return
	# Una pausa tutorial congela el ataque. FIN lo cancela antes del resultado.
	if not _partida_activa(): return
	if principal == null:
		cadencia_restante = maxf(0.0, cadencia_restante - delta)
		reenganche_restante = maxf(0.0, reenganche_restante - delta)
		_actualizar_capturas(delta)
		if is_instance_valid(segundo_tendon): segundo_tendon.actualizar(delta)
		_procesar_llegadas()
		if reenganche_restante > 0.0: queue_redraw()
	recarga_restante = maxf(0.0, recarga_restante - delta)
	if impacto_restante > 0.0:
		impacto_restante = maxf(0.0, impacto_restante - delta)
		queue_redraw()
	if anfitrion.controlado_por_jugador: queue_redraw()
	if estado == Estado.LISTO:
		hasta_busqueda -= delta
		if principal == null and not _segundo_activo() and not anfitrion.controlado_por_jugador and hasta_busqueda <= 0.0 and recarga_restante <= 0.0:
			hasta_busqueda = 0.22
			_buscar_objetivo()
		return
	if estado != Estado.ARRASTRANDO: tiempo_estado += delta
	if estado == Estado.RECUPERANDO:
		if tiempo_estado >= parametros.recuperacion:
			estado = Estado.LISTO
			queue_redraw()
		return
	if not is_instance_valid(objetivo) or not _objetivo_valido(objetivo):
		_recuperar()
		return
	var distancia := anfitrion.global_position.distance_to(objetivo.global_position)
	if distancia > alcance() + 20.0 or not _linea_libre(anfitrion.global_position, objetivo.global_position, objetivo):
		_recuperar()
		return
	match estado:
		Estado.PREPARANDO:
			direccion_disparo = anfitrion.global_position.direction_to(objetivo.global_position)
			if distancia <= parametros.distancia_contacto:
				_recuperar()
			elif tiempo_estado >= parametros.preparacion:
				estado = Estado.EXTENDIENDO
				tiempo_estado = 0.0
				extension = 0.0
				punta_global = anfitrion.global_position
		Estado.EXTENDIENDO:
			var anterior := punta_global
			extension = minf(extension + parametros.velocidad_extension * delta, alcance())
			punta_global = anfitrion.global_position + direccion_disparo * extension
			if not _linea_libre(anterior, punta_global, objetivo):
				_recuperar()
			elif Geometry2D.get_closest_point_to_segment(objetivo.global_position, anterior, punta_global).distance_to(objetivo.global_position) <= parametros.radio_impacto:
				estado = Estado.ARRASTRANDO
				tiempo_estado = 0.0
				bloqueo_restante = 0.0
				tiempo_arrastre = 0.0
				impacto_global = objetivo.global_position
				impacto_restante = 0.16
				objetivo.npc_brain.reset()
			elif extension >= alcance():
				_recuperar()
		Estado.ARRASTRANDO:
			punta_global = objetivo.global_position
			if distancia <= parametros.distancia_contacto:
				_completar_arrastre()
			elif tiempo_arrastre >= duracion_arrastre():
				_recuperar()
	queue_redraw()

func arrastrar_objetivo(presa: CharacterBody2D, delta: float) -> bool:
	if estado != Estado.ARRASTRANDO or presa != objetivo: return false
	if not _anfitrion_valido() or not _objetivo_valido(presa):
		cancelar_objetivo(presa)
		return false
	if not _partida_activa(): return true
	if anfitrion.global_position.distance_to(presa.global_position) > alcance() + 20.0 or not _linea_libre(anfitrion.global_position, presa.global_position, presa):
		_recuperar()
		return false
	var hacia: Vector2 = anfitrion.global_position - presa.global_position
	if hacia.length() <= parametros.distancia_contacto:
		_completar_arrastre()
		return true
	# El presupuesto se consume en el mismo lugar que mueve la presa, independiente
	# del orden de los nodos. Un delta grande nunca permite superar el máximo.
	var disponible := maxf(0.0, duracion_arrastre() - tiempo_arrastre)
	var usado := minf(maxf(delta, 0.0), disponible)
	if usado <= 0.0:
		_recuperar()
		return true
	tiempo_arrastre += usado
	tiempo_estado = tiempo_arrastre
	var paso := minf(velocidad_arrastre() * usado, hacia.length() - parametros.distancia_contacto)
	var anterior := presa.global_position
	presa.velocity = hacia.normalized() * velocidad_arrastre()
	presa.direccion_movimiento_real = hacia.normalized()
	# Un desplazamiento barrido de la cápsula real: no teletransporte ni atravesar muebles.
	presa.move_and_collide(hacia.normalized() * paso)
	punta_global = presa.global_position
	if presa.global_position.distance_to(anterior) < 0.1:
		bloqueo_restante += usado
		if bloqueo_restante >= 0.22: _recuperar()
	else:
		bloqueo_restante = 0.0
	if estado == Estado.ARRASTRANDO:
		if presa.global_position.distance_to(anfitrion.global_position) <= parametros.distancia_contacto + 0.1:
			_completar_arrastre()
		elif tiempo_arrastre >= duracion_arrastre():
			_recuperar()
	queue_redraw()
	return true

func bloquea_movimiento() -> bool:
	return estado != Estado.LISTO or _segundo_activo()

func _soltar_objetivo() -> void:
	if is_instance_valid(objetivo) and objetivo.captor_garfio == self:
		objetivo.captor_garfio = null
		objetivo.velocity = Vector2.ZERO
		objetivo.npc_brain.reset()
	objetivo = null

func _recuperar() -> void:
	_soltar_objetivo()
	estado = Estado.RECUPERANDO
	tiempo_estado = 0.0
	var lider := _lider()
	if not lider.recarga_iniciada:
		lider.recarga_iniciada = true
		lider.recarga_restante = recarga()
	queue_redraw()

func _completar_arrastre() -> void:
	if intento_realizado or not is_instance_valid(objetivo): return
	intento_realizado = true
	var presa := objetivo
	# Soltar antes de infectar evita reentrada: infectar() limpia capturas existentes.
	_recuperar()
	_lider()._registrar_captura(presa)
	_lider()._procesar_llegadas()

func cancelar_objetivo(presa: Node2D) -> void:
	if objetivo == presa: _recuperar()
	if principal == null and is_instance_valid(segundo_tendon): segundo_tendon.cancelar_objetivo(presa)
	# Sólo invalida la presa afectada; el otro apéndice conserva su captura.
	for captura in _lider().capturas:
		if captura.presa.get_ref() == presa and not captura.get("en_intento", false):
			captura.restante = 0.0
			_lider()._limpiar_referencia(presa)

func _limpiar_referencia(presa: Node2D) -> void:
	if not is_instance_valid(presa): return
	var referencia = presa.get_meta("garfio_captura") if presa.has_meta("garfio_captura") else null
	if referencia is WeakRef and referencia.get_ref() == self:
		presa.remove_meta("garfio_captura")

func reserva_objetivo(presa: Node2D) -> bool:
	if objetivo == presa: return true
	if is_instance_valid(segundo_tendon) and segundo_tendon.objetivo == presa: return true
	for captura in capturas:
		if captura.presa.get_ref() == presa and not captura.intentado and captura.restante > 0.0: return true
	return false

func puede_intentar_contagio(_presa: Node2D) -> bool:
	return cadencia_restante <= 0.0 and _partida_activa()

func _captura_para(presa: Node2D) -> Dictionary:
	for captura in capturas:
		if captura.presa.get_ref() == presa and captura.restante > 0.0 and not captura.intentado: return captura
	return {}

func preparar_intento(presa: Node2D, chance: float) -> float:
	var captura := _captura_para(presa)
	if captura.is_empty(): return chance
	captura.en_intento = true
	var efecto := presa.get_node_or_null("PresaVulnerable")
	return efecto.consumir(self, chance) if is_instance_valid(efecto) else chance

func registrar_intento(presa: Node2D, exito: bool) -> void:
	cadencia_restante = anfitrion.INTERVALO_CONTAGIO
	var captura := _captura_para(presa)
	if captura.is_empty(): return
	captura.intentado = true
	captura.en_intento = false
	_limpiar_referencia(presa)
	if not exito or reenganche_activado or nivel_reenganche() <= 0: return
	reenganche_activado = true
	var factor := clampf(_valor_nivel(parametros.factores_recarga_reenganche, nivel_reenganche(), 3.0 / 7.0), 0.05, 1.0)
	recarga_restante = minf(recarga_restante, maxf(0.1, recarga() * factor))
	reenganche_restante = 0.35
	queue_redraw()

func _registrar_captura(presa: Node2D) -> void:
	if not _objetivo_valido(presa): return
	var anterior_captura = presa.get_meta("garfio_captura") if presa.has_meta("garfio_captura") else null
	if anterior_captura is WeakRef:
		var captor_anterior: Node2D = anterior_captura.get_ref()
		if is_instance_valid(captor_anterior): captor_anterior.cancelar_objetivo(presa)
	presa.set_meta("garfio_captura", weakref(self))
	capturas.append({"presa": weakref(presa), "restante": parametros.ventana_captura, "intentado": false, "en_intento": false})
	if nivel_vulnerable() <= 0: return
	var anterior := presa.get_node_or_null("PresaVulnerable")
	if is_instance_valid(anterior):
		presa.remove_child(anterior)
		anterior.queue_free()
	var efecto := PresaVulnerable.new()
	efecto.name = "PresaVulnerable"
	efecto.captor = weakref(self)
	efecto.restante = parametros.duracion_vulnerable
	efecto.bono = parametros.bono_vulnerable
	efecto.limite = parametros.probabilidad_maxima_vulnerable
	efecto.factor = _valor_nivel(parametros.factores_movimiento_desorientado, nivel_vulnerable(), 0.5)
	efecto.equipo_color = anfitrion.color_infeccion
	presa.add_child(efecto)

func _actualizar_capturas(delta: float) -> void:
	for index in range(capturas.size() - 1, -1, -1):
		var captura: Dictionary = capturas[index]
		captura.restante -= delta
		var presa: Node2D = captura.presa.get_ref()
		if captura.restante <= 0.0 or not _objetivo_valido(presa):
			_limpiar_referencia(presa)
			capturas.remove_at(index)

func _procesar_llegadas() -> void:
	if cadencia_restante > 0.0: return
	for captura in capturas:
		if captura.intentado or captura.restante <= 0.0: continue
		var presa: Node2D = captura.presa.get_ref()
		if not _objetivo_valido(presa): continue
		if anfitrion.global_position.distance_to(presa.global_position) > parametros.distancia_contacto + 0.2: continue
		if not _linea_libre(anfitrion.global_position, presa.global_position, presa): continue
		anfitrion.intentar_contagio_garfio(presa)
		return

func cancelar() -> void:
	if principal == null:
		if is_instance_valid(segundo_tendon): segundo_tendon.cancelar()
		for captura in capturas:
			var presa: Node2D = captura.presa.get_ref()
			if is_instance_valid(presa):
				_limpiar_referencia(presa)
				var efecto := presa.get_node_or_null("PresaVulnerable")
				if is_instance_valid(efecto) and efecto.captor.get_ref() == self: efecto.cancelar()
		capturas.clear()
		reenganche_restante = 0.0
	_soltar_objetivo()
	estado = Estado.LISTO
	tiempo_estado = 0.0
	recarga_restante = recarga()
	impacto_restante = 0.0
	queue_redraw()

func _exit_tree() -> void:
	cancelar()

func animar(direccion: Vector2) -> void:
	var sprite: AnimatedSprite2D = anfitrion.animated_sprite
	var vista := direccion_disparo if bloquea_movimiento() else direccion
	if vista.length_squared() > 0.01:
		if absf(vista.x) > absf(vista.y): direccion_visual = "derecha" if vista.x > 0.0 else "izquierda"
		else: direccion_visual = "abajo" if vista.y > 0.0 else "arriba"
	var animacion := ("caminar_" if direccion.length_squared() > 0.01 else "idle_") + direccion_visual
	# Los gestos especiales frontales no sustituyen una vista lateral o de espalda.
	if direccion_visual == "abajo":
		match estado:
			Estado.PREPARANDO: animacion = "preparacion"
			Estado.EXTENDIENDO: animacion = "enganche"
			Estado.ARRASTRANDO: animacion = "tension"
			Estado.RECUPERANDO: animacion = "recuperacion"
	if sprite.sprite_frames.has_animation(animacion): sprite.play(animacion)

func _draw() -> void:
	if not _anfitrion_valido(): return
	var color: Color = anfitrion.color_infeccion
	if reenganche_restante > 0.0:
		draw_arc(Vector2.ZERO, 15.0 + (0.35 - reenganche_restante) * 24.0, -PI, 0.0, 16, Color(color, reenganche_restante / 0.35), 2.0, false)
	if impacto_restante > 0.0:
		draw_arc(to_local(impacto_global), 7.0, 0.0, TAU, 12, Color(color, impacto_restante / 0.16), 2.0, false)
	if principal == null and anfitrion.controlado_por_jugador:
		var fraccion := 1.0 - clampf(recarga_restante / recarga(), 0.0, 1.0)
		draw_arc(Vector2(0, 17), 8.0, -PI, -PI + maxf(0.01, PI * fraccion), 16, color, 2.0, false)
	if estado == Estado.PREPARANDO and is_instance_valid(objetivo):
		var fin := to_local(objetivo.global_position)
		# Anticipación discontinua; el jugador puede apartarse antes del lanzamiento.
		for i in range(0, int(fin.length()), 12):
			draw_line(fin.normalized() * i, fin.normalized() * minf(i + 5.0, fin.length()), Color(color, 0.55), 1.0, false)
		return
	if estado not in [Estado.EXTENDIENDO, Estado.ARRASTRANDO]: return
	var inicio := Vector2(9, -3) if direccion_visual != "izquierda" else Vector2(-9, -3)
	if principal != null: inicio = Vector2(-inicio.x, inicio.y - 4.0)
	var fin := to_local(punta_global)
	draw_line(inicio, fin, Color("2e2938"), 6.0, false)
	draw_line(inicio, fin, Color("814953"), 3.0, false)
	draw_line(inicio + Vector2(0, -1), fin + Vector2(0, -1), Color("9e6c7b"), 1.0, false)
	if punta != null:
		draw_set_transform(fin, direccion_disparo.angle())
		draw_texture_rect(punta, Rect2(-8, -8, 16, 16), false)
		draw_set_transform(Vector2.ZERO)
