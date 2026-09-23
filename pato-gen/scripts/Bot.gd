extends CharacterBody2D


# ============================================================
# CONFIGURACIÓN BASE
# ============================================================

@export var speed: float = 100.0
@export var skins: Array[SpriteFrames] = []

var velocidad_base: float = 100.0


# ============================================================
# ESTADO DE INFECCIÓN
# ============================================================

var is_infected: bool = false

var color_infeccion: Color = Color.WHITE

var player_duenio: int = 0

var move_direction: Vector2 = Vector2.ZERO


# ============================================================
# CONTAGIO
# ============================================================

var probabilidad_contagio: float = 0.35


# ============================================================
# TEMPERATURA
# ============================================================

var multiplicador_velocidad_temp: float = 1.0

var multiplicador_contagio_temp: float = 1.0

var probabilidad_curacion: float = 0.01


# ============================================================
# ESCUDO
# ============================================================

var tiempo_escudo: float = 0.0


# ============================================================
# MUTACIONES
# ============================================================

var mutaciones: Array[String] = []


# ============================================================
# ESTADOS INTERNOS DE MUTACIONES
# ============================================================

# FIEBRE
var tiempo_persiguiendo: float = 0.0


# CONTAGIO EN CADENA
var bonus_contagio_temporal: float = 0.0
var tiempo_bonus_contagio: float = 0.0


# PORTADOR ASINTOMÁTICO
var tiempo_asintomatico: float = 0.0


# INFECCIÓN RETARDADA
var infeccion_pendiente: bool = false
var tiempo_infeccion_pendiente: float = 0.0

var color_infeccion_pendiente: Color = Color.WHITE

var jugador_infeccion_pendiente: int = 0


# RESISTENCIA
var intentos_curacion: int = 0


# RABIA
var tiempo_sin_infectar: float = 0.0

var en_rabia: bool = false


# NIDO
var bonus_nido: float = 1.0


# ============================================================
# NODOS
# ============================================================

@onready var timer_direccion: Timer = $TimerCambioRumbo

@onready var area_infeccion: Area2D = $AreaInfeccion

@onready var area_vision: Area2D = $AreaVision

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


# ============================================================
# TIMERS
# ============================================================

var timer_contagio: Timer

var timer_curacion: Timer


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	randomize()


	# --------------------------------------------------------
	# SKIN ALEATORIA
	# --------------------------------------------------------

	if skins.size() > 0 and animated_sprite:

		animated_sprite.sprite_frames = skins.pick_random()


	# --------------------------------------------------------
	# GRUPO
	# --------------------------------------------------------

	add_to_group("bots")


	# --------------------------------------------------------
	# VELOCIDAD BASE
	# --------------------------------------------------------

	velocidad_base = speed


	# --------------------------------------------------------
	# DIRECCIÓN INICIAL
	# --------------------------------------------------------

	cambiar_direccion_aleatoria()


	# --------------------------------------------------------
	# TIMER DE DIRECCIÓN
	# --------------------------------------------------------

	if timer_direccion:

		timer_direccion.timeout.connect(
			_on_timer_timeout
		)

		timer_direccion.wait_time = randf_range(
			1.5,
			3.0
		)

		timer_direccion.start()


	# ========================================================
	# TIMER DE CONTAGIO
	# ========================================================

	timer_contagio = Timer.new()

	timer_contagio.wait_time = 0.5

	timer_contagio.one_shot = false

	timer_contagio.timeout.connect(
		_intentar_contagio_area
	)

	add_child(timer_contagio)


	# ========================================================
	# TIMER DE CURACIÓN
	# ========================================================

	timer_curacion = Timer.new()

	timer_curacion.wait_time = 1.0

	timer_curacion.one_shot = false

	timer_curacion.timeout.connect(
		_intentar_curacion
	)

	add_child(timer_curacion)


# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:


	# --------------------------------------------------------
	# ESCUDO
	# --------------------------------------------------------

	if tiempo_escudo > 0:

		tiempo_escudo -= delta


	# --------------------------------------------------------
	# INFECCIÓN RETARDADA
	# --------------------------------------------------------

	if infeccion_pendiente:

		tiempo_infeccion_pendiente -= delta

		if tiempo_infeccion_pendiente <= 0:

			activar_infeccion_pendiente()


	# --------------------------------------------------------
	# PORTADOR ASINTOMÁTICO
	# --------------------------------------------------------

	if tiempo_asintomatico > 0:

		tiempo_asintomatico -= delta

		if tiempo_asintomatico <= 0:

			modulate = color_infeccion


	# --------------------------------------------------------
	# BONUS CONTAGIO EN CADENA
	# --------------------------------------------------------

	if tiempo_bonus_contagio > 0:

		tiempo_bonus_contagio -= delta

		if tiempo_bonus_contagio <= 0:

			bonus_contagio_temporal = 0.0


	# ========================================================
	# IA
	# ========================================================

	if area_vision:


		# ====================================================
		# BOT SANO
		# ====================================================

		if not is_infected:

			var amenaza = obtener_amenaza_cercana()

			if amenaza:

				huir_de(
					amenaza.global_position
				)


		# ====================================================
		# BOT INFECTADO
		# ====================================================

		else:

			var presa = obtener_humano_cercano()

			if presa:

				# --------------------------------------------
				# CAZADOR
				# --------------------------------------------

				if tiene_mutacion("cazador"):

					var objetivo = obtener_humano_aislado()

					if objetivo:

						perseguir_a(
							objetivo.global_position
						)

					else:

						perseguir_a(
							presa.global_position
						)

				else:

					perseguir_a(
						presa.global_position
					)


				# --------------------------------------------
				# FIEBRE
				# --------------------------------------------

				tiempo_persiguiendo += delta

				# --------------------------------------------
				# RABIA
				# --------------------------------------------

				tiempo_sin_infectar += delta

			else:

				tiempo_persiguiendo = 0.0

				tiempo_sin_infectar += delta


	# ========================================================
	# RABIA
	# ========================================================

	if tiene_mutacion("rabia") and is_infected:

		if tiempo_sin_infectar >= 8.0:

			en_rabia = true

		else:

			en_rabia = false


	# ========================================================
	# NIDO
	# ========================================================

	if tiene_mutacion("nido") and is_infected:

		actualizar_bonus_nido()


	# ========================================================
	# MOVIMIENTO
	# ========================================================

	var multiplicador_mutaciones := (
		obtener_multiplicador_velocidad()
	)

	velocity = move_direction * (
		speed
		* multiplicador_velocidad_temp
		* multiplicador_mutaciones
	)

	move_and_slide()


	# ========================================================
	# ANIMACIÓN
	# ========================================================

	actualizar_animacion(
		move_direction
	)


# ============================================================
# DIRECCIÓN ALEATORIA
# ============================================================

func cambiar_direccion_aleatoria() -> void:

	move_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()


func _on_timer_timeout() -> void:

	cambiar_direccion_aleatoria()

	if timer_direccion:

		timer_direccion.wait_time = randf_range(
			1.5,
			3.5
		)

		timer_direccion.start()


# ============================================================
# AMENAZA CERCANA
# ============================================================

func obtener_amenaza_cercana() -> Node2D:

	for body in area_vision.get_overlapping_bodies():

		if body == self:
			continue

		if not body.is_in_group("bots"):
			continue

		if not body.is_infected:
			continue

		return body


	return null


# ============================================================
# HUMANO CERCANO
# ============================================================

func obtener_humano_cercano() -> Node2D:

	for body in area_vision.get_overlapping_bodies():

		if body == self:
			continue

		if not body.is_in_group("bots"):
			continue

		if body.is_infected:
			continue

		return body


	return null


# ============================================================
# HUMANO AISLADO
# ============================================================

func obtener_humano_aislado() -> Node2D:

	var mejor_objetivo: Node2D = null

	var mejor_puntaje: float = -INF


	for body in area_vision.get_overlapping_bodies():

		if body == self:
			continue

		if not body.is_in_group("bots"):
			continue

		if body.is_infected:
			continue


		var distancia := global_position.distance_to(
			body.global_position
		)


		var humanos_cercanos := 0


		if body.has_node("AreaVision"):

			var vision_objetivo = body.get_node(
				"AreaVision"
			)

			for otro in vision_objetivo.get_overlapping_bodies():

				if otro == body:
					continue

				if not otro.is_in_group("bots"):
					continue

				if otro.is_infected:
					continue

				humanos_cercanos += 1


		# Cuanto más aislado, mejor.
		var puntaje_aislamiento := (
			-float(humanos_cercanos) * 150.0
		)


		# No queremos elegir un objetivo
		# extremadamente lejano.
		var puntaje_distancia := -distancia


		var puntaje_total := (
			puntaje_aislamiento
			+ puntaje_distancia
		)


		if puntaje_total > mejor_puntaje:

			mejor_puntaje = puntaje_total

			mejor_objetivo = body


	return mejor_objetivo


# ============================================================
# HUIR
# ============================================================

func huir_de(
	posicion_amenaza: Vector2
) -> void:

	if not is_infected:

		move_direction = (
			global_position
			- posicion_amenaza
		).normalized()


# ============================================================
# PERSEGUIR
# ============================================================

func perseguir_a(
	posicion_objetivo: Vector2
) -> void:

	if is_infected:

		move_direction = (
			posicion_objetivo
			- global_position
		).normalized()


# ============================================================
# INFECTAR
# ============================================================

func infectar(
	color_jugador: Color,
	id_jugador: int
) -> void:

	if is_infected:
		return

	if infeccion_pendiente:
		return


	# ========================================================
	# INFECCIÓN RETARDADA
	# ========================================================

	if tiene_mutacion("infeccion_retardada"):

		infeccion_pendiente = true

		tiempo_infeccion_pendiente = 3.0

		color_infeccion_pendiente = color_jugador

		jugador_infeccion_pendiente = id_jugador

		return


	activar_infeccion(
		color_jugador,
		id_jugador
	)


# ============================================================
# ACTIVAR INFECCIÓN
# ============================================================

func activar_infeccion(
	color_jugador: Color,
	id_jugador: int
) -> void:

	if is_infected:
		return


	is_infected = true

	color_infeccion = color_jugador

	player_duenio = id_jugador


	# --------------------------------------------------------
	# ESCUDO
	# --------------------------------------------------------

	tiempo_escudo = 3.0


	# --------------------------------------------------------
	# REINICIAR ESTADOS
	# --------------------------------------------------------

	tiempo_persiguiendo = 0.0

	tiempo_sin_infectar = 0.0

	bonus_contagio_temporal = 0.0

	tiempo_bonus_contagio = 0.0

	intentos_curacion = 0

	en_rabia = false


	# ========================================================
	# ASINTOMÁTICO
	# ========================================================

	if tiene_mutacion("portador_asintomatico"):

		tiempo_asintomatico = 5.0

		modulate = Color.WHITE

	else:

		modulate = color_jugador


	# ========================================================
	# AVISAR AL MAPA
	# ========================================================

	var mapa = get_tree().current_scene


	if mapa.has_method("sumar_adn"):

		mapa.sumar_adn(
			player_duenio
		)


	if mapa.has_method("aplicar_mutaciones_a_bot"):

		mapa.aplicar_mutaciones_a_bot(
			self
		)


	# ========================================================
	# TIMERS
	# ========================================================

	timer_contagio.start()

	timer_curacion.start()


# ============================================================
# ACTIVAR INFECCIÓN RETARDADA
# ============================================================

func activar_infeccion_pendiente() -> void:

	infeccion_pendiente = false


	var color := color_infeccion_pendiente

	var jugador := jugador_infeccion_pendiente


	color_infeccion_pendiente = Color.WHITE

	jugador_infeccion_pendiente = 0


	activar_infeccion(
		color,
		jugador
	)


# ============================================================
# CURAR
# ============================================================

func curar() -> void:


	# ========================================================
	# ÚLTIMO ALIENTO
	# ========================================================

	if tiene_mutacion("ultimo_aliento"):

		liberar_ultimo_aliento()


	# ========================================================
	# ESTADO NORMAL
	# ========================================================

	is_infected = false

	color_infeccion = Color.WHITE

	player_duenio = 0

	modulate = Color.WHITE


	# ========================================================
	# REINICIAR ESTADOS
	# ========================================================

	tiempo_persiguiendo = 0.0

	tiempo_sin_infectar = 0.0

	en_rabia = false

	bonus_contagio_temporal = 0.0

	tiempo_bonus_contagio = 0.0

	bonus_nido = 1.0

	intentos_curacion = 0


	# ========================================================
	# DETENER TIMERS
	# ========================================================

	timer_contagio.stop()

	timer_curacion.stop()


# ============================================================
# CONTAGIO
# ============================================================

func _intentar_contagio_area() -> void:

	if not is_infected:
		return

	if not area_infeccion:
		return


	var infecto_a_alguien := false


	for body in area_infeccion.get_overlapping_bodies():

		if body == self:
			continue

		if not body.is_in_group("bots"):
			continue

		if body.is_infected:
			continue


		# ====================================================
		# PROBABILIDAD BASE
		# ====================================================

		var chance_efectiva := (
			probabilidad_contagio
		)


		chance_efectiva *= (
			multiplicador_contagio_temp
		)


		# ====================================================
		# NIDO
		# ====================================================

		chance_efectiva *= bonus_nido


		# ====================================================
		# CADENA
		# ====================================================

		chance_efectiva += (
			bonus_contagio_temporal
		)


		# ====================================================
		# RABIA
		# ====================================================

		if en_rabia:

			chance_efectiva += 0.20


		chance_efectiva = clamp(
			chance_efectiva,
			0.0,
			1.0
		)


		# ====================================================
		# INTENTO
		# ====================================================

		if randf() <= chance_efectiva:

			body.infectar(
				color_infeccion,
				player_duenio
			)


			infecto_a_alguien = true


			# =================================================
			# CONTAGIO EN CADENA
			# =================================================

			if tiene_mutacion("contagio_cadena"):

				bonus_contagio_temporal += 0.08

				bonus_contagio_temporal = min(
					bonus_contagio_temporal,
					0.40
				)

				tiempo_bonus_contagio = 5.0


			# =================================================
			# EXPLOSIÓN INFECCIOSA
			# =================================================

			if tiene_mutacion("explosion_infecciosa"):

				if randf() <= 0.25:

					infectar_cercanos_explosion(
						body
					)


	# ========================================================
	# REINICIAR RABIA
	# ========================================================

	if infecto_a_alguien:

		tiempo_sin_infectar = 0.0

		en_rabia = false


# ============================================================
# EXPLOSIÓN INFECCIOSA
# ============================================================

func infectar_cercanos_explosion(
	origen: Node2D
) -> void:

	if not is_instance_valid(origen):
		return


	var radio := 80.0


	for body in get_tree().get_nodes_in_group("bots"):

		if body == self:
			continue

		if body == origen:
			continue

		if body.is_infected:
			continue


		var distancia := (
			origen.global_position.distance_to(
				body.global_position
			)
		)


		if distancia <= radio:

			if randf() <= 0.35:

				body.infectar(
					color_infeccion,
					player_duenio
				)


# ============================================================
# CURACIÓN
# ============================================================

func _intentar_curacion() -> void:

	if not is_infected:
		return


	if tiempo_escudo > 0:
		return


	# ========================================================
	# RESISTENCIA
	# ========================================================

	if tiene_mutacion("resistencia"):

		if randf() <= probabilidad_curacion:

			intentos_curacion += 1


			# Necesita 3 intentos.
			if intentos_curacion < 3:
				return


			curar()

		return


	# ========================================================
	# CURACIÓN NORMAL
	# ========================================================

	if randf() <= probabilidad_curacion:

		curar()


# ============================================================
# ÚLTIMO ALIENTO
# ============================================================

func liberar_ultimo_aliento() -> void:

	var radio := 100.0


	for body in get_tree().get_nodes_in_group("bots"):

		if body == self:
			continue

		if body.is_infected:
			continue


		var distancia := (
			global_position.distance_to(
				body.global_position
			)
		)


		if distancia <= radio:

			if randf() <= 0.30:

				body.infectar(
					color_infeccion,
					player_duenio
				)


# ============================================================
# NIDO
# ============================================================

func actualizar_bonus_nido() -> void:

	bonus_nido = 1.0


	if not tiene_mutacion("nido"):
		return


	var cantidad_infectados := 0


	for body in area_vision.get_overlapping_bodies():

		if body == self:
			continue

		if not body.is_in_group("bots"):
			continue

		if not body.is_infected:
			continue


		cantidad_infectados += 1


	# +10% por infectado cercano.
	# Máximo +30%.
	bonus_nido += min(
		float(cantidad_infectados) * 0.10,
		0.30
	)


# ============================================================
# MULTIPLICADOR DE VELOCIDAD
# ============================================================

func obtener_multiplicador_velocidad() -> float:

	var multiplicador := 1.0


	# ========================================================
	# FIEBRE
	# ========================================================

	if tiene_mutacion("fiebre") and is_infected:

		var bonus_fiebre: float = floor(
	tiempo_persiguiendo / 2.0
) * 0.05


		# Máximo +50%.
		bonus_fiebre = min(
			bonus_fiebre,
			0.50
		)


		multiplicador += bonus_fiebre


	# ========================================================
	# RABIA
	# ========================================================

	if en_rabia:

		multiplicador += 0.35


	# ========================================================
	# NIDO
	# ========================================================

	if tiene_mutacion("nido"):

		multiplicador += (
			(bonus_nido - 1.0) * 0.5
		)


	return multiplicador


# ============================================================
# APLICAR MUTACIONES
# ============================================================

func aplicar_mutaciones(
	nuevas_mutaciones: Array[String]
) -> void:


	# Copiamos las mutaciones del jugador.
	mutaciones = nuevas_mutaciones.duplicate()


	# ========================================================
	# RESTAURAR VALORES BASE
	# ========================================================

	speed = velocidad_base

	probabilidad_contagio = 0.35


	# ========================================================
	# RADIO VISUAL BASE
	# ========================================================

	if area_infeccion:

		area_infeccion.scale = Vector2.ONE


	# ========================================================
	# ESCALA VISUAL
	# ========================================================

	scale = Vector2.ONE


	# ========================================================
	# MUTACIONES ADICIONALES
	# ========================================================

	# CADENA:
	# +5% de probabilidad base.

	if tiene_mutacion("contagio_cadena"):

		probabilidad_contagio += 0.05


	# EXPLOSIÓN:
	# +3% de probabilidad base.

	if tiene_mutacion("explosion_infecciosa"):

		probabilidad_contagio += 0.03


	# NIDO:
	# No necesita modificar estadísticas aquí.
	# Su efecto se calcula dinámicamente.


	probabilidad_contagio = clamp(
		probabilidad_contagio,
		0.0,
		1.0
	)


# ============================================================
# COMPROBAR MUTACIÓN
# ============================================================

func tiene_mutacion(
	nombre: String
) -> bool:

	return nombre in mutaciones


# ============================================================
# ANIMACIONES
# ============================================================

func actualizar_animacion(
	direccion: Vector2
) -> void:

	if not animated_sprite:
		return


	if direccion.length_squared() < 0.01:

		animated_sprite.stop()

		return


	animated_sprite.play()


	# --------------------------------------------------------
	# HORIZONTAL
	# --------------------------------------------------------

	if abs(direccion.x) > abs(direccion.y):

		if direccion.x > 0:

			animated_sprite.play(
				"Derecha"
			)

		else:

			animated_sprite.play(
				"Izquierda"
			)


	# --------------------------------------------------------
	# VERTICAL
	# --------------------------------------------------------

	else:

		if direccion.y > 0:

			animated_sprite.play(
				"Abajo"
			)

		else:

			animated_sprite.play(
				"Arriba"
			)


# ============================================================
# SEÑAL
# ============================================================

func _on_area_infeccion_body_entered(
	_body: Node2D
) -> void:

	pass
