extends CharacterBody2D

@export var speed: float = 300.0
@export_enum("Jugador 1: 1", "Jugador 2: 2") var player_id: int = 1
@export var color_jugador: Color = Color.CYAN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var esta_desapareciendo: bool = false
var modo_fantasma: bool = false


# ============================================================
# POSESIÓN
# ============================================================

var bot_poseido: Node2D = null
var tiempo_posesion: float = 0.0
var cooldown_posesion: float = 0.0

const DURACION_POSESION: float = 10.0
const COOLDOWN_POSESION: float = 20.0


# ============================================================
# ZONAS DE TEMPERATURA
# ============================================================

# X = Frío / C = Calor para P1
# B = Frío / N = Calor para P2
var tecla_frio_anterior: bool = false
var tecla_calor_anterior: bool = false

const COOLDOWN_LECTURA_ZONA: float = 0.15
var cooldown_zona: float = 0.0


# ============================================================
# ROBOT CURADOR
# ============================================================

# G = Robot para P1
# H = Robot para P2
var tecla_robot_anterior: bool = false

const COOLDOWN_ROBOT: float = 0.20
var cooldown_robot: float = 0.0


func _ready() -> void:
	add_to_group("patos")

	if player_id == 1:
		color_jugador = Color.BLUE
	else:
		color_jugador = Color.MAGENTA

	if animated_sprite:
		animated_sprite.modulate = color_jugador

	iniciar_temporizador_desaparicion()


func iniciar_temporizador_desaparicion() -> void:
	await get_tree().create_timer(15.0).timeout

	if modo_fantasma:
		return

	esta_desapareciendo = true
	velocity = Vector2.ZERO

	if animated_sprite and animated_sprite.sprite_frames:
		var animaciones = animated_sprite.sprite_frames.get_animation_names()
		var anim_encontrada = ""

		for anim in animaciones:
			if "desaparec" in anim.to_lower():
				anim_encontrada = anim
				break

		if anim_encontrada != "":
			animated_sprite.sprite_frames.set_animation_loop(
				anim_encontrada,
				false
			)

			animated_sprite.play(anim_encontrada)

			var frames = animated_sprite.sprite_frames.get_frame_count(
				anim_encontrada
			)

			var fps = animated_sprite.sprite_frames.get_animation_speed(
				anim_encontrada
			)

			var duracion = float(frames) / max(fps, 1.0)

			await get_tree().create_timer(duracion).timeout

	infectar_y_desaparecer()


func _physics_process(delta: float) -> void:

	# ========================================================
	# COOLDOWNS
	# ========================================================

	if cooldown_posesion > 0.0:
		cooldown_posesion -= delta
		cooldown_posesion = max(cooldown_posesion, 0.0)

	if cooldown_zona > 0.0:
		cooldown_zona -= delta
		cooldown_zona = max(cooldown_zona, 0.0)

	if cooldown_robot > 0.0:
		cooldown_robot -= delta
		cooldown_robot = max(cooldown_robot, 0.0)


	# ========================================================
	# HABILIDAD DE ROBOT CURADOR
	# ========================================================

	procesar_habilidad_robot()


	# ========================================================
	# HABILIDAD DE ZONAS DE TEMPERATURA
	# ========================================================

	procesar_habilidad_zona_temperatura()


	# ========================================================
	# POSESIÓN ACTIVA
	# ========================================================

	if bot_poseido != null:

		if not is_instance_valid(bot_poseido):
			finalizar_posesion()
			return

		tiempo_posesion -= delta

		if tiempo_posesion <= 0.0:
			finalizar_posesion()
			return

		# Mientras dura la posesión, el Pato no se mueve.
		# El movimiento lo realiza directamente el bot.
		controlar_bot_poseido()

		velocity = Vector2.ZERO

		return


	# ========================================================
	# HABILIDAD DE POSESIÓN
	# ========================================================

	if modo_fantasma and cooldown_posesion <= 0.0:

		var tecla_posesion := false

		if player_id == 1:
			tecla_posesion = Input.is_key_pressed(KEY_Q)
		else:
			tecla_posesion = Input.is_key_pressed(KEY_M)

		if tecla_posesion:
			intentar_poseer_infectado()


	# ========================================================
	# MOVIMIENTO DEL PATO
	# ========================================================

	if esta_desapareciendo:
		velocity = Vector2.ZERO
		return

	var input_vector: Vector2 = obtener_input_jugador()

	velocity = input_vector * speed
	move_and_slide()

	actualizar_animacion(input_vector)


# ============================================================
# HABILIDAD: ZONA DE TEMPERATURA
# ============================================================

func procesar_habilidad_zona_temperatura() -> void:

	if not modo_fantasma:
		# Mantener sincronizados los estados aunque todavía no sea fantasma.
		tecla_frio_anterior = _obtener_tecla_frio()
		tecla_calor_anterior = _obtener_tecla_calor()
		return

	var tecla_frio_actual := _obtener_tecla_frio()
	var tecla_calor_actual := _obtener_tecla_calor()

	# Solo se activa en el momento de presionar, no mientras la tecla permanece apretada.
	if tecla_frio_actual and not tecla_frio_anterior:
		colocar_zona_temperatura("frio")

	elif tecla_calor_actual and not tecla_calor_anterior:
		colocar_zona_temperatura("calor")

	tecla_frio_anterior = tecla_frio_actual
	tecla_calor_anterior = tecla_calor_actual


func _obtener_tecla_frio() -> bool:

	if player_id == 1:
		return Input.is_key_pressed(KEY_X)

	return Input.is_key_pressed(KEY_B)


func _obtener_tecla_calor() -> bool:

	if player_id == 1:
		return Input.is_key_pressed(KEY_C)

	return Input.is_key_pressed(KEY_N)


func colocar_zona_temperatura(tipo: String) -> void:

	if cooldown_zona > 0.0:
		return

	var mapa = get_tree().get_first_node_in_group("mapa")

	if mapa == null:
		print("No se encontró el nodo del mapa.")
		return

	if not mapa.has_method("crear_zona_temperatura"):
		print("El mapa no tiene el método crear_zona_temperatura().")
		return

	# Si estamos poseídos, la zona aparece donde está el bot controlado.
	# Si no, aparece donde está el Pato Fantasma.
	var posicion_zona: Vector2 = global_position

	if bot_poseido != null and is_instance_valid(bot_poseido):
		posicion_zona = bot_poseido.global_position

	var creada: bool = mapa.crear_zona_temperatura(
		player_id,
		tipo,
		posicion_zona
	)

	if creada:
		cooldown_zona = COOLDOWN_LECTURA_ZONA


# ============================================================
# HABILIDAD: ROBOT CURADOR
# ============================================================

func procesar_habilidad_robot() -> void:

	if not modo_fantasma:
		# Mantener sincronizado el estado de la tecla antes de ser fantasma.
		tecla_robot_anterior = _obtener_tecla_robot()
		return

	var tecla_robot_actual := _obtener_tecla_robot()

	# Solo se activa al presionar, no mientras se mantiene la tecla.
	if tecla_robot_actual and not tecla_robot_anterior:
		invocar_robot()

	tecla_robot_anterior = tecla_robot_actual


func _obtener_tecla_robot() -> bool:

	if player_id == 1:
		return Input.is_key_pressed(KEY_G)

	return Input.is_key_pressed(KEY_H)


func invocar_robot() -> void:

	if cooldown_robot > 0.0:
		return

	var mapa = get_tree().get_first_node_in_group("mapa")

	if mapa == null:
		print("No se encontró el nodo del mapa.")
		return

	if not mapa.has_method("crear_robot"):
		print("El mapa no tiene el método crear_robot().")
		return

	# Si estamos poseídos, el robot aparece donde está el bot controlado.
	# Si no, aparece donde está el Pato Fantasma.
	var posicion_robot: Vector2 = global_position

	if bot_poseido != null and is_instance_valid(bot_poseido):
		posicion_robot = bot_poseido.global_position

	var creado: bool = mapa.crear_robot(
		player_id,
		posicion_robot
	)

	if creado:
		cooldown_robot = COOLDOWN_ROBOT


# ============================================================
# OBTENER INPUT DEL JUGADOR
# ============================================================

func obtener_input_jugador() -> Vector2:

	var input_vector := Vector2.ZERO

	if player_id == 1:

		var left = Input.is_key_pressed(KEY_A)
		var right = Input.is_key_pressed(KEY_D)
		var up = Input.is_key_pressed(KEY_W)
		var down = Input.is_key_pressed(KEY_S)

		input_vector = Vector2(
			int(right) - int(left),
			int(down) - int(up)
		)

	else:

		var left = Input.is_key_pressed(KEY_LEFT)
		var right = Input.is_key_pressed(KEY_RIGHT)
		var up = Input.is_key_pressed(KEY_UP)
		var down = Input.is_key_pressed(KEY_DOWN)

		input_vector = Vector2(
			int(right) - int(left),
			int(down) - int(up)
		)

	return input_vector.normalized()


# ============================================================
# BUSCAR INFECTADO Y POSEERLO
# ============================================================

func intentar_poseer_infectado() -> void:

	# Evita repetir la habilidad mientras la tecla está presionada.
	cooldown_posesion = 0.2

	var bots = get_tree().get_nodes_in_group("bots")

	var infectado_mas_cercano: Node2D = null
	var distancia_minima: float = INF

	for bot in bots:

		if not is_instance_valid(bot):
			continue

		if not bot.is_infected:
			continue

		# El infectado debe pertenecer al jugador correspondiente.
		if bot.player_duenio != player_id:
			continue

		var distancia = global_position.distance_to(
			bot.global_position
		)

		if distancia < distancia_minima:
			distancia_minima = distancia
			infectado_mas_cercano = bot

	if infectado_mas_cercano == null:
		return

	iniciar_posesion(infectado_mas_cercano)


# ============================================================
# INICIAR POSESIÓN
# ============================================================

func iniciar_posesion(bot: Node2D) -> void:

	bot_poseido = bot
	tiempo_posesion = DURACION_POSESION

	# El cooldown real empieza al comenzar la posesión.
	cooldown_posesion = COOLDOWN_POSESION

	# Ocultar temporalmente al Pato Fantasma.
	visible = false

	# Detener completamente al Pato.
	velocity = Vector2.ZERO

	# Avisar al bot que está siendo controlado.
	if bot.has_method("activar_control_jugador"):
		bot.activar_control_jugador(player_id)


# ============================================================
# CONTROLAR BOT POSEÍDO
# ============================================================

func controlar_bot_poseido() -> void:

	if bot_poseido == null:
		return

	if not is_instance_valid(bot_poseido):
		return

	# Obtener únicamente el input actual del jugador.
	var input_vector := obtener_input_jugador()

	# El bot recibe directamente el movimiento actual.
	if bot_poseido.has_method("recibir_control_jugador"):
		bot_poseido.recibir_control_jugador(input_vector)


# ============================================================
# FINALIZAR POSESIÓN
# ============================================================

func finalizar_posesion() -> void:

	if bot_poseido != null and is_instance_valid(bot_poseido):

		if bot_poseido.has_method("desactivar_control_jugador"):
			bot_poseido.desactivar_control_jugador()

	bot_poseido = null
	tiempo_posesion = 0.0

	# El fantasma vuelve a aparecer.
	visible = true

	# Mantener la apariencia fantasma.
	if animated_sprite:
		animated_sprite.modulate = Color(
			color_jugador.r,
			color_jugador.g,
			color_jugador.b,
			0.45
		)


# ============================================================
# INFECTAR Y CONVERTIRSE EN FANTASMA
# ============================================================

func infectar_y_desaparecer() -> void:

	var bots = get_tree().get_nodes_in_group("bots")
	var bot_mas_cercano: Node2D = null
	var distancia_minima: float = INF

	for bot in bots:

		if not bot.is_infected:

			var distancia = global_position.distance_to(
				bot.global_position
			)

			if distancia < distancia_minima:
				distancia_minima = distancia
				bot_mas_cercano = bot

	if bot_mas_cercano != null:
		bot_mas_cercano.infectar(
			color_jugador,
			player_id
		)

	convertirse_en_fantasma()


# ============================================================
# CONVERTIRSE EN FANTASMA
# ============================================================

func convertirse_en_fantasma() -> void:

	esta_desapareciendo = false
	modo_fantasma = true
	velocity = Vector2.ZERO

	# Sin colisión.
	set_collision_layer(0)
	set_collision_mask(0)

	for hijo in get_children():

		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	# Apariencia transparente.
	if animated_sprite:

		animated_sprite.modulate = Color(
			color_jugador.r,
			color_jugador.g,
			color_jugador.b,
			0.45
		)

		# Al convertirse en fantasma, utilizar la animación
		# correspondiente de fantasma.
		# La dirección inicial será Abajo.
		if animated_sprite.sprite_frames.has_animation("FantasmaAbajo"):
			animated_sprite.play("FantasmaAbajo")

	if not is_in_group("patos_fantasma"):
		add_to_group("patos_fantasma")


# ============================================================
# ANIMACIÓN DEL PATO
# ============================================================

func actualizar_animacion(direccion: Vector2) -> void:

	if esta_desapareciendo or not animated_sprite:
		return

	if direccion.length_squared() < 0.01:
		animated_sprite.stop()
		return

	var nombre_animacion: String = ""

	# ========================================================
	# PATO VIVO
	# ========================================================

	if not modo_fantasma:

		if abs(direccion.x) > abs(direccion.y):

			if direccion.x > 0:
				nombre_animacion = "Derecha"
			else:
				nombre_animacion = "Izquierda"

		else:

			if direccion.y > 0:
				nombre_animacion = "Abajo"
			else:
				nombre_animacion = "Arriba"


	# ========================================================
	# PATO FANTASMA
	# ========================================================

	else:

		if abs(direccion.x) > abs(direccion.y):

			if direccion.x > 0:
				nombre_animacion = "Fantasma Derecha"
			else:
				nombre_animacion = "Fantasma Izquierda"

		else:

			if direccion.y > 0:
				nombre_animacion = "Fantasma Abajo"
			else:
				nombre_animacion = "Fantasma Arriba"


	# ========================================================
	# REPRODUCIR ANIMACIÓN
	# ========================================================

	if animated_sprite.sprite_frames.has_animation(nombre_animacion):
		animated_sprite.play(nombre_animacion)
