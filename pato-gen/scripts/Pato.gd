extends CharacterBody2D

@export var speed: float = 300.0
@export_enum("Jugador 1: 1", "Jugador 2: 2") var player_id: int = 1
@export var color_jugador: Color = Color.CYAN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var esta_desapareciendo: bool = false
var modo_fantasma: bool = false

# Aura visual del Pato Fantasma
var indicador_aura_fantasma: Polygon2D = null
var tween_aura_fantasma: Tween = null

const RADIO_AURA_FANTASMA: float = 42.0
const SEGMENTOS_AURA_FANTASMA: int = 48


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

const COOLDOWN_ZONA_FRIO: float = 10.0
const COOLDOWN_ZONA_CALOR: float = 10.0

var cooldown_zona_frio: float = 0.0
var cooldown_zona_calor: float = 0.0


# ROBOT CURADOR
# ============================================================
# ============================================================

# G = Robot para P1
# H = Robot para P2
var tecla_robot_anterior: bool = false

const COOLDOWN_ROBOT: float = 25.0
var cooldown_robot: float = 0.0


func _ready() -> void:
	add_to_group("patos")

	if player_id == 1:
		color_jugador = Color.BLUE
	else:
		color_jugador = Color.MAGENTA

	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		# Primero fijar la capa principal; los 8 contornos usan una inferior.
		animated_sprite.z_index = 6
		configurar_borde_pato()

	crear_aura_fantasma()

	iniciar_temporizador_desaparicion()


# ============================================================
# BORDE DEL PATO (SIN TEÑIR LOS SPRITES)
# ============================================================

# Contorno exterior: 8 copias coloreadas detrás del sprite original.
# A diferencia del shader anterior, funciona aunque el frame ocupe todo el atlas.
var sprites_borde: Array[AnimatedSprite2D] = []
var grupo_visual_pato: CanvasGroup = null
const GROSOR_BORDE_PATO: float = 3.0


func configurar_borde_pato() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	# Mantener el sprite principal con sus colores originales.
	animated_sprite.material = null
	animated_sprite.modulate = Color.WHITE

	# Componer silueta y contorno ANTES de aplicar transparencia.
	# Así las copias de color no se ven a través del fantasma.
	grupo_visual_pato = CanvasGroup.new()
	grupo_visual_pato.name = "GrupoVisualPato"
	grupo_visual_pato.z_index = 5
	add_child(grupo_visual_pato)

	animated_sprite.reparent(grupo_visual_pato, false)
	animated_sprite.z_index = 1

	var shader_color := Shader.new()
	shader_color.code = """shader_type canvas_item;
uniform vec4 color_borde : source_color = vec4(0.0, 0.0, 1.0, 1.0);
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(color_borde.rgb, tex.a * COLOR.a);
}
"""

	var offsets := [
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(0, -1), Vector2(0, 1),
		Vector2(-0.7071, -0.7071), Vector2(0.7071, -0.7071),
		Vector2(-0.7071, 0.7071), Vector2(0.7071, 0.7071)
	]

	for i in offsets.size():
		var borde := AnimatedSprite2D.new()
		borde.name = "BordePato_%d" % i
		borde.sprite_frames = animated_sprite.sprite_frames
		borde.animation = animated_sprite.animation
		borde.frame = animated_sprite.frame
		borde.position = animated_sprite.position + offsets[i] * GROSOR_BORDE_PATO
		borde.scale = animated_sprite.scale
		borde.rotation = animated_sprite.rotation
		borde.centered = animated_sprite.centered
		borde.offset = animated_sprite.offset
		borde.flip_h = animated_sprite.flip_h
		borde.flip_v = animated_sprite.flip_v
		borde.z_index = 0

		var material_borde := ShaderMaterial.new()
		material_borde.shader = shader_color
		material_borde.set_shader_parameter("color_borde", color_jugador)
		borde.material = material_borde
		grupo_visual_pato.add_child(borde)
		sprites_borde.append(borde)

	animated_sprite.frame_changed.connect(sincronizar_borde_pato)
	animated_sprite.animation_changed.connect(sincronizar_borde_pato)
	sincronizar_borde_pato()


func sincronizar_borde_pato() -> void:
	if animated_sprite == null:
		return

	for borde in sprites_borde:
		if not is_instance_valid(borde):
			continue
		if borde.sprite_frames != animated_sprite.sprite_frames:
			borde.sprite_frames = animated_sprite.sprite_frames
		if borde.animation != animated_sprite.animation:
			borde.animation = animated_sprite.animation
		if borde.frame != animated_sprite.frame:
			borde.frame = animated_sprite.frame


func actualizar_transparencia_borde_pato(alpha: float) -> void:
	# La transparencia se aplica a toda la composición ya terminada.
	if grupo_visual_pato:
		grupo_visual_pato.modulate.a = alpha
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	for borde in sprites_borde:
		if is_instance_valid(borde):
			borde.modulate.a = 1.0


func crear_aura_fantasma() -> void:

	if indicador_aura_fantasma != null:
		return

	indicador_aura_fantasma = Polygon2D.new()
	indicador_aura_fantasma.name = "AuraFantasma"

	var puntos := PackedVector2Array()

	for i in range(SEGMENTOS_AURA_FANTASMA):
		var angulo := TAU * float(i) / float(SEGMENTOS_AURA_FANTASMA)
		puntos.append(
			Vector2(cos(angulo), sin(angulo)) * RADIO_AURA_FANTASMA
		)

	indicador_aura_fantasma.polygon = puntos
	indicador_aura_fantasma.color = Color(
		color_jugador.r,
		color_jugador.g,
		color_jugador.b,
		0.16
	)

	# El aura queda por encima del mapa, pero detrás del sprite.
	indicador_aura_fantasma.z_index = 4
	indicador_aura_fantasma.z_as_relative = true
	indicador_aura_fantasma.visible = false

	add_child(indicador_aura_fantasma)

	iniciar_animacion_aura_fantasma()


func iniciar_animacion_aura_fantasma() -> void:

	if indicador_aura_fantasma == null:
		return

	if tween_aura_fantasma != null:
		tween_aura_fantasma.kill()

	tween_aura_fantasma = create_tween()
	tween_aura_fantasma.set_loops()

	tween_aura_fantasma.tween_property(
		indicador_aura_fantasma,
		"scale",
		Vector2(1.0, 1.0),
		0.0
	)

	tween_aura_fantasma.tween_property(
		indicador_aura_fantasma,
		"scale",
		Vector2(1.10, 1.10),
		0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween_aura_fantasma.tween_property(
		indicador_aura_fantasma,
		"scale",
		Vector2(1.0, 1.0),
		0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func mostrar_aura_fantasma() -> void:

	if indicador_aura_fantasma == null:
		crear_aura_fantasma()

	if indicador_aura_fantasma != null:
		indicador_aura_fantasma.visible = true


func ocultar_aura_fantasma() -> void:

	if indicador_aura_fantasma != null:
		indicador_aura_fantasma.visible = false


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

	if cooldown_zona_frio > 0.0:
		cooldown_zona_frio -= delta
		cooldown_zona_frio = max(cooldown_zona_frio, 0.0)

	if cooldown_zona_calor > 0.0:
		cooldown_zona_calor -= delta
		cooldown_zona_calor = max(cooldown_zona_calor, 0.0)

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
			tecla_posesion = Input.is_key_pressed(KEY_X)
		else:
			tecla_posesion = Input.is_key_pressed(KEY_J)

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
		return Input.is_key_pressed(KEY_C)

	return Input.is_key_pressed(KEY_K)


func _obtener_tecla_calor() -> bool:

	if player_id == 1:
		return Input.is_key_pressed(KEY_V)

	return Input.is_key_pressed(KEY_L)


func colocar_zona_temperatura(tipo: String) -> void:

	# Cada tipo de zona tiene su propio cooldown.
	# X/B (frío) y C/N (calor) pueden recargarse de forma independiente.
	if tipo == "frio" and cooldown_zona_frio > 0.0:
		return

	if tipo == "calor" and cooldown_zona_calor > 0.0:
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
		if tipo == "frio":
			cooldown_zona_frio = COOLDOWN_ZONA_FRIO
		else:
			cooldown_zona_calor = COOLDOWN_ZONA_CALOR


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
		return Input.is_key_pressed(KEY_Z)

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
		animated_sprite.modulate = Color.WHITE
		actualizar_transparencia_borde_pato(0.75)


# ============================================================
# INFECTAR Y CONVERTIRSE EN FANTASMA
# ============================================================

func infectar_y_desaparecer() -> void:
	if modo_fantasma:
		return
	AudioManager.efecto("pato_desaparecer", -12.0, false)

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

	# Agrandar el tamaño visual del pato y su contorno un 50 %.
	# No cambia la colisión, la velocidad ni el radio de las habilidades.
	if grupo_visual_pato:
		grupo_visual_pato.scale *= 1.5
	elif animated_sprite:
		animated_sprite.scale *= 1.5

	# Mostrar el aura mientras el Pato está libre en modo fantasma.
	mostrar_aura_fantasma()

	# Sin colisión.
	set_collision_layer(0)
	set_collision_mask(0)

	for hijo in get_children():

		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	# Transparencia suave solo para el fantasma (85 % de opacidad).
	if animated_sprite:

		animated_sprite.modulate = Color.WHITE
		actualizar_transparencia_borde_pato(0.75)

		# Al convertirse en fantasma, utilizar la animación
		# correspondiente de fantasma.
		# La dirección inicial será Abajo.
		if animated_sprite.sprite_frames.has_animation("Fantasma Abajo"):
			animated_sprite.play("Fantasma Abajo")

	if not is_in_group("patos_fantasma"):
		add_to_group("patos_fantasma")


# ============================================================
# ANIMACIÓN DEL PATO
# ============================================================

func actualizar_animacion(direccion: Vector2) -> void:

	if esta_desapareciendo or not animated_sprite:
		return

	if direccion.length_squared() < 0.01:
		# El fantasma flota aun estando quieto: mantener el ciclo animado.
		if modo_fantasma:
			if not animated_sprite.is_playing():
				animated_sprite.play()
		else:
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
