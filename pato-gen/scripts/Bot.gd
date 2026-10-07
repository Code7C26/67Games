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

var controlado_por_jugador: bool = false
var jugador_controlador: int = 0
var direccion_control_jugador: Vector2 = Vector2.ZERO

# Dirección que realmente está utilizando el bot.
# Puede venir de la IA o del jugador.
var direccion_movimiento_real: Vector2 = Vector2.ZERO


# ============================================================
# EVASIÓN DE OBSTÁCULOS
# ============================================================

var direccion_evasion: Vector2 = Vector2.ZERO
var tiempo_evasion: float = 0.0
var tiempo_ultimo_obstaculo: float = 0.0
var tiempo_contacto_obstaculo: float = 0.0


# ============================================================
# CURACIÓN POR ROBOT
# ============================================================

func curar_por_robot() -> void:

	if not is_infected:
		return

	# El robot cura directamente y NO activa Último Aliento.
	is_infected = false

	color_infeccion = Color.WHITE
	player_duenio = 0

	modulate = Color.WHITE

	# Reiniciar estados de infección.
	tiempo_persiguiendo = 0.0
	tiempo_sin_infectar = 0.0

	en_rabia = false

	bonus_contagio_temporal = 0.0
	tiempo_bonus_contagio = 0.0

	intentos_curacion = 0
	tiempo_asintomatico = 0.0

	# Detener los timers de infección/curación mientras el bot está sano.
	if timer_contagio:
		timer_contagio.stop()

	if timer_curacion:
		timer_curacion.stop()


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
# ESTADOS DE MUTACIONES
# ============================================================

# FIEBRE
var tiempo_persiguiendo: float = 0.0


# CADENA
var bonus_contagio_temporal: float = 0.0
var tiempo_bonus_contagio: float = 0.0


# RETARDADA
var infeccion_pendiente: bool = false
var tiempo_infeccion_pendiente: float = 0.0

var color_infeccion_pendiente: Color = Color.WHITE
var jugador_infeccion_pendiente: int = 0


# RESISTENCIA / CURACIÓN
var intentos_curacion: int = 0


# RABIA
var tiempo_sin_infectar: float = 0.0
var en_rabia: bool = false


# ============================================================
# NODOS
# ============================================================

@onready var timer_direccion: Timer = $TimerCambioRumbo
@onready var area_infeccion: Area2D = $AreaInfeccion
@onready var area_vision: Area2D = $AreaVision
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Indicador visual de posesión.
# Es independiente del AreaInfeccion física para no alterar las colisiones.
var indicador_area_infeccion: Polygon2D = null
var indicador_aura_posesion: Polygon2D = null
var tween_indicador_posesion: Tween = null

const RADIO_INDICADOR_INFECCION: float = 68.88396
const RADIO_INDICADOR_AURA: float = 80.0
const SEGMENTOS_INDICADOR: int = 64


# ============================================================
# TIMERS
# ============================================================

var timer_contagio: Timer
var timer_curacion: Timer


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# No hacemos randomize() en cada bot.
	# Cada instancia usa su propio RNG para elegir una skin.

	crear_indicador_posesion()

	if skins.size() > 0 and animated_sprite:
		var rng := RandomNumberGenerator.new()
		rng.randomize()

		var indice_skin := rng.randi_range(0, skins.size() - 1)
		animated_sprite.sprite_frames = skins[indice_skin]

	add_to_group("bots")

	velocidad_base = speed

	cambiar_direccion_aleatoria()

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
	# TIMER CONTAGIO
	# ========================================================

	timer_contagio = Timer.new()

	timer_contagio.wait_time = 0.5
	timer_contagio.one_shot = false

	timer_contagio.timeout.connect(
		_intentar_contagio_area
	)

	add_child(timer_contagio)


	# ========================================================
	# TIMER CURACIÓN
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

	# ========================================================
	# ESCUDO
	# ========================================================

	if tiempo_escudo > 0.0:
		tiempo_escudo -= delta


	# ========================================================
	# INFECCIÓN RETARDADA
	# ========================================================

	if infeccion_pendiente:

		tiempo_infeccion_pendiente -= delta

		if tiempo_infeccion_pendiente <= 0.0:
			activar_infeccion_pendiente()


	# ========================================================
	# ASINTOMÁTICO
	# ========================================================

	if tiempo_asintomatico > 0.0:

		tiempo_asintomatico -= delta

		if tiempo_asintomatico <= 0.0:
			modulate = color_infeccion


	# ========================================================
	# BONUS CADENA
	# ========================================================

	if tiempo_bonus_contagio > 0.0:

		tiempo_bonus_contagio -= delta

		if tiempo_bonus_contagio <= 0.0:
			bonus_contagio_temporal = 0.0


	# ========================================================
	# EVASIÓN DE OBSTÁCULOS
	# ========================================================

	if tiempo_evasion > 0.0:
		tiempo_evasion -= delta

	if tiempo_ultimo_obstaculo > 0.0:
		tiempo_ultimo_obstaculo -= delta


	# ========================================================
	# IA
	# ========================================================

	# Mientras el bot está controlado por un jugador,
	# la IA NO modifica move_direction.

	if not controlado_por_jugador:

		# Mientras está evitando una pared, la IA no cambia
		# la dirección para volver inmediatamente contra ella.

		if tiempo_evasion <= 0.0 and area_vision:

			if not is_infected:

				var amenaza = obtener_amenaza_cercana()

				if amenaza:

					huir_de(
						amenaza.global_position
					)

			else:

				var presa = obtener_humano_cercano()

				if presa:

					perseguir_a(
						presa.global_position
					)

					tiempo_persiguiendo += delta

				else:

					tiempo_persiguiendo = 0.0


	# ========================================================
	# RABIA
	# ========================================================

	if tiene_mutacion("rabia") and is_infected:

		if tiempo_sin_infectar >= 8.0:
			en_rabia = true
		else:
			en_rabia = false


	# ========================================================
	# TIEMPO SIN INFECTAR
	# ========================================================

	if is_infected:
		tiempo_sin_infectar += delta


	# ========================================================
	# MOVIMIENTO
	# ========================================================

	var multiplicador_mutaciones: float = (
		obtener_multiplicador_velocidad()
	)


	if controlado_por_jugador:

		# ====================================================
		# MOVIMIENTO CONTROLADO POR EL JUGADOR
		# ====================================================

		direccion_movimiento_real = direccion_control_jugador

		velocity = direccion_control_jugador * (
			speed
			* multiplicador_velocidad_temp
			* multiplicador_mutaciones
		)

	else:

		# ====================================================
		# MOVIMIENTO NORMAL DE LA IA
		# ====================================================

		direccion_movimiento_real = move_direction

		velocity = move_direction * (
			speed
			* multiplicador_velocidad_temp
			* multiplicador_mutaciones
		)


	move_and_slide()


	# ========================================================
	# REACCIÓN A COLISIONES
	# ========================================================

	if get_slide_collision_count() > 0:

		reaccionar_a_obstaculo()

	else:

		tiempo_contacto_obstaculo = 0.0


	# ========================================================
	# ANIMACIÓN
	# ========================================================

	# MUY IMPORTANTE:
	# La animación usa la dirección REAL del movimiento.
	actualizar_animacion(
		direccion_movimiento_real
	)


# ============================================================
# VARIABLE ASINTOMÁTICO
# ============================================================

var tiempo_asintomatico: float = 0.0


# ============================================================
# DIRECCIÓN ALEATORIA
# ============================================================

func cambiar_direccion_aleatoria() -> void:

	move_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()


func _on_timer_timeout() -> void:

	# La IA no debe cambiar dirección mientras está poseída.
	if controlado_por_jugador:
		return

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

	tiempo_escudo = 3.0

	tiempo_persiguiendo = 0.0
	tiempo_sin_infectar = 0.0

	bonus_contagio_temporal = 0.0
	tiempo_bonus_contagio = 0.0

	intentos_curacion = 0

	en_rabia = false


	# ========================================================
	# PORTADOR ASINTOMÁTICO
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
# ACTIVAR INFECCIÓN PENDIENTE
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

	intentos_curacion = 0

	tiempo_asintomatico = 0.0


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

		var chance_efectiva: float = (
			probabilidad_contagio
			* multiplicador_contagio_temp
		)


		# ====================================================
		# CADENA
		# ====================================================

		chance_efectiva += bonus_contagio_temporal


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


	var radio: float = 80.0


	for body in get_tree().get_nodes_in_group("bots"):

		if body == self:
			continue

		if body == origen:
			continue

		if body.is_infected:
			continue


		var distancia: float = (
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

	if tiempo_escudo > 0.0:
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

	var radio: float = 100.0


	for body in get_tree().get_nodes_in_group("bots"):

		if body == self:
			continue

		if body.is_infected:
			continue


		var distancia: float = (
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
# VELOCIDAD POR MUTACIONES
# ============================================================

func obtener_multiplicador_velocidad() -> float:

	var multiplicador: float = 1.0


	# ========================================================
	# FIEBRE
	# ========================================================

	if tiene_mutacion("fiebre") and is_infected:

		var bonus_fiebre: float = floor(
			tiempo_persiguiendo / 2.0
		) * 0.05

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


	return multiplicador


# ============================================================
# APLICAR MUTACIONES
# ============================================================

func aplicar_mutaciones(
	nuevas_mutaciones: Array[String]
) -> void:

	mutaciones = nuevas_mutaciones.duplicate()


	# ========================================================
	# VALORES BASE
	# ========================================================

	speed = velocidad_base

	probabilidad_contagio = 0.35


	# ========================================================
	# CADENA
	# ========================================================

	if tiene_mutacion("contagio_cadena"):
		probabilidad_contagio += 0.05


	# ========================================================
	# EXPLOSIÓN
	# ========================================================

	if tiene_mutacion("explosion_infecciosa"):
		probabilidad_contagio += 0.03


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
# REACCIÓN A OBSTÁCULOS
# ============================================================

func reaccionar_a_obstaculo() -> void:

	# IMPORTANTE:
	# Si está controlado por el jugador, no modificamos
	# su dirección de movimiento mediante la IA.
	if controlado_por_jugador:
		return


	# No esquivamos en el mismo instante del primer contacto.
	if tiempo_ultimo_obstaculo > 0.0:
		return

	var normal_promedio := Vector2.ZERO
	var encontro_obstaculo_real := false
	var cantidad_obstaculos := 0

	# Los bots no cuentan como obstáculos.
	for i in get_slide_collision_count():

		var colision := get_slide_collision(i)

		if not colision:
			continue

		var objeto := colision.get_collider()

		if objeto is Node and objeto.is_in_group("bots"):
			continue

		normal_promedio += colision.get_normal()
		cantidad_obstaculos += 1
		encontro_obstaculo_real = true

	if not encontro_obstaculo_real:

		tiempo_contacto_obstaculo = 0.0
		return

	tiempo_contacto_obstaculo += (
		get_physics_process_delta_time()
	)

	# Un roce corto no cambia la dirección.
	if tiempo_contacto_obstaculo < 0.12:
		return

	tiempo_contacto_obstaculo = 0.0
	tiempo_ultimo_obstaculo = 0.12


	# Si está encerrado entre dos superficies enfrentadas.
	if (
		normal_promedio.length_squared() < 0.01
		and cantidad_obstaculos >= 2
	):

		if move_direction.length_squared() > 0.01:

			direccion_evasion = Vector2(
				-move_direction.y,
				move_direction.x
			).normalized()

			if randf() < 0.5:
				direccion_evasion *= -1.0

			move_direction = direccion_evasion
			tiempo_evasion = 0.55

		return


	if normal_promedio.length_squared() < 0.01:
		return

	normal_promedio = normal_promedio.normalized()


	# Dirección perpendicular a la pared.
	var tangente := Vector2(
		-normal_promedio.y,
		normal_promedio.x
	)


	# No cambiamos de lado constantemente.
	if randf() < 0.5:
		tangente *= -1.0


	direccion_evasion = (
		normal_promedio * 0.65
		+ tangente * 0.90
	).normalized()

	move_direction = direccion_evasion

	tiempo_evasion = 0.55


# ============================================================
# ANIMACIÓN
# ============================================================

func actualizar_animacion(
	direccion: Vector2
) -> void:

	if not animated_sprite:
		return


	if direccion.length_squared() < 0.01:

		animated_sprite.stop()

		return


	if abs(direccion.x) > abs(direccion.y):

		if direccion.x > 0:

			animated_sprite.play(
				"Derecha"
			)

		else:

			animated_sprite.play(
				"Izquierda"
			)

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


# ============================================================
# ACTIVAR CONTROL DEL JUGADOR
# ============================================================

func activar_control_jugador(
	id_jugador: int
) -> void:

	controlado_por_jugador = true
	jugador_controlador = id_jugador

	mostrar_indicador_posesion(id_jugador)

	# Limpiar completamente el movimiento anterior de la IA.
	move_direction = Vector2.ZERO

	# Limpiar cualquier input anterior.
	direccion_control_jugador = Vector2.ZERO

	# Limpiar la dirección real.
	direccion_movimiento_real = Vector2.ZERO

	# Detener inmediatamente el movimiento anterior.
	velocity = Vector2.ZERO

	# Limpiar estados de evasión.
	direccion_evasion = Vector2.ZERO
	tiempo_evasion = 0.0
	tiempo_contacto_obstaculo = 0.0
	tiempo_ultimo_obstaculo = 0.0


# ============================================================
# RECIBIR CONTROL DEL JUGADOR
# ============================================================

func recibir_control_jugador(
	direccion: Vector2
) -> void:

	if not controlado_por_jugador:
		return

	# Normalizamos para evitar que una dirección diagonal
	# sea más rápida.
	direccion_control_jugador = direccion.normalized()


# ============================================================
# DESACTIVAR CONTROL DEL JUGADOR
# ============================================================

func desactivar_control_jugador() -> void:

	controlado_por_jugador = false
	jugador_controlador = 0

	ocultar_indicador_posesion()

	# Limpiar completamente el control anterior.
	direccion_control_jugador = Vector2.ZERO
	direccion_movimiento_real = Vector2.ZERO

	# Detener el movimiento anterior.
	velocity = Vector2.ZERO

	# Limpiar estados de evasión.
	direccion_evasion = Vector2.ZERO
	tiempo_evasion = 0.0
	tiempo_contacto_obstaculo = 0.0
	tiempo_ultimo_obstaculo = 0.0

	# La IA comienza nuevamente con una dirección limpia.
	cambiar_direccion_aleatoria()


# ============================================================
# INDICADOR VISUAL DE POSESIÓN
# ============================================================

func crear_poligono_circular(
	radio: float
) -> PackedVector2Array:

	var puntos := PackedVector2Array()

	for i in SEGMENTOS_INDICADOR:

		var angulo := (
			float(i) / float(SEGMENTOS_INDICADOR)
		) * TAU

		puntos.append(
			Vector2(cos(angulo), sin(angulo)) * radio
		)

	return puntos


func crear_indicador_posesion() -> void:

	# Capa exterior: aura suave.
	indicador_aura_posesion = Polygon2D.new()
	indicador_aura_posesion.name = "AuraPosesion"
	indicador_aura_posesion.polygon = crear_poligono_circular(
		RADIO_INDICADOR_AURA
	)
	indicador_aura_posesion.color = Color(
		0.0,
		1.0,
		1.0,
		0.0
	)
	indicador_aura_posesion.z_index = 10
	indicador_aura_posesion.visible = false
	add_child(indicador_aura_posesion)

	# Capa interior: coincide con el área real de infección.
	indicador_area_infeccion = Polygon2D.new()
	indicador_area_infeccion.name = "AreaInfeccionVisual"
	indicador_area_infeccion.polygon = crear_poligono_circular(
		RADIO_INDICADOR_INFECCION
	)
	indicador_area_infeccion.color = Color(
		0.0,
		1.0,
		1.0,
		0.0
	)
	indicador_area_infeccion.z_index = 11
	indicador_area_infeccion.visible = false
	add_child(indicador_area_infeccion)


func mostrar_indicador_posesion(
	id_jugador: int
) -> void:

	if not indicador_area_infeccion or not indicador_aura_posesion:
		return

	var color_jugador := Color.CYAN

	if id_jugador == 2:
		color_jugador = Color(
			1.0,
			0.0,
			1.0,
			1.0
		)

	# Área real de infección: más visible.
	indicador_area_infeccion.color = Color(
		color_jugador.r,
		color_jugador.g,
		color_jugador.b,
		0.18
	)

	# Aura exterior: más tenue.
	indicador_aura_posesion.color = Color(
		color_jugador.r,
		color_jugador.g,
		color_jugador.b,
		0.10
	)

	indicador_area_infeccion.scale = Vector2.ONE
	indicador_aura_posesion.scale = Vector2.ONE

	indicador_area_infeccion.visible = true
	indicador_aura_posesion.visible = true

	if tween_indicador_posesion:
		tween_indicador_posesion.kill()

	tween_indicador_posesion = create_tween()
	tween_indicador_posesion.set_loops()
	tween_indicador_posesion.set_trans(Tween.TRANS_SINE)
	tween_indicador_posesion.set_ease(Tween.EASE_IN_OUT)

	tween_indicador_posesion.tween_property(
		indicador_aura_posesion,
		"scale",
		Vector2(1.10, 1.10),
		0.65
	)

	tween_indicador_posesion.parallel().tween_property(
		indicador_aura_posesion,
		"color:a",
		0.16,
		0.65
	)

	tween_indicador_posesion.tween_property(
		indicador_aura_posesion,
		"scale",
		Vector2(1.0, 1.0),
		0.65
	)

	tween_indicador_posesion.parallel().tween_property(
		indicador_aura_posesion,
		"color:a",
		0.10,
		0.65
	)


func ocultar_indicador_posesion() -> void:

	if tween_indicador_posesion:
		tween_indicador_posesion.kill()
		tween_indicador_posesion = null

	if indicador_area_infeccion:
		indicador_area_infeccion.visible = false
		indicador_area_infeccion.scale = Vector2.ONE

	if indicador_aura_posesion:
		indicador_aura_posesion.visible = false
		indicador_aura_posesion.scale = Vector2.ONE
