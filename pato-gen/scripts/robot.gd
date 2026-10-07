extends CharacterBody2D
class_name RobotCurador


# ============================================================
# CONFIGURACIÓN
# ============================================================

@export var radio_curacion: float = 100.0
@export var duracion: float = 20.0

# Movimiento
@export var velocidad: float = 90.0
@export var intervalo_cambio_direccion: float = 2.0

# Curación
@export_range(0.0, 1.0) var probabilidad_curacion: float = 0.75
@export var intervalo_curacion: float = 1.0

# Visual del área de curación
@export var color_area: Color = Color(0.2, 1.0, 0.2, 0.25)

# Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var jugador_invocador: int = 0

var direccion_movimiento: Vector2 = Vector2.ZERO
var tiempo_cambio_direccion: float = 0.0
var tiempo_curacion: float = 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	add_to_group("robots_curadores")

	iniciar_duracion()
	cambiar_direccion()

	# Actualiza el dibujo del área
	queue_redraw()


# ============================================================
# DIBUJAR ÁREA DE CURACIÓN
# ============================================================

func _draw() -> void:
	# Círculo verde transparente
	draw_circle(
		Vector2.ZERO,
		radio_curacion,
		color_area
	)


# ============================================================
# DURACIÓN
# ============================================================

func iniciar_duracion() -> void:
	await get_tree().create_timer(duracion).timeout

	if not is_inside_tree():
		return

	queue_free()


# ============================================================
# MOVIMIENTO + CURACIÓN
# ============================================================

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	# --------------------------------------------------------
	# MOVIMIENTO
	# --------------------------------------------------------

	tiempo_cambio_direccion -= delta

	if tiempo_cambio_direccion <= 0.0:
		cambiar_direccion()

	velocity = direccion_movimiento * velocidad
	move_and_slide()

	# Actualizar animación según dirección
	actualizar_animacion(direccion_movimiento)


	# --------------------------------------------------------
	# CURACIÓN
	# --------------------------------------------------------

	tiempo_curacion -= delta

	if tiempo_curacion <= 0.0:
		tiempo_curacion = intervalo_curacion
		intentar_curar()


# ============================================================
# CAMBIAR DIRECCIÓN
# ============================================================

func cambiar_direccion() -> void:
	direccion_movimiento = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	tiempo_cambio_direccion = intervalo_cambio_direccion


# ============================================================
# ANIMACIÓN DEL MOVIMIENTO
# ============================================================

func actualizar_animacion(direccion: Vector2) -> void:
	if animated_sprite == null:
		return

	if direccion.length_squared() < 0.01:
		animated_sprite.stop()
		return

	# Determinamos si se mueve principalmente
	# horizontal o verticalmente.

	if abs(direccion.x) > abs(direccion.y):

		if direccion.x > 0.0:
			animated_sprite.play("Derecha")
		else:
			animated_sprite.play("Izquierda")

	else:

		if direccion.y > 0.0:
			animated_sprite.play("Abajo")
		else:
			animated_sprite.play("Arriba")


# ============================================================
# CURACIÓN
# ============================================================

func intentar_curar() -> void:
	var bots = get_tree().get_nodes_in_group("bots")

	for bot in bots:

		if not is_instance_valid(bot):
			continue

		if not bot.is_infected:
			continue

		var distancia := global_position.distance_to(bot.global_position)

		if distancia > radio_curacion:
			continue

		# ----------------------------------------------------
		# PROBABILIDAD DE CURACIÓN
		# ----------------------------------------------------

		if randf() > probabilidad_curacion:
			continue

		# Cura infectados de cualquier jugador.
		# No activa Último Aliento.
		if bot.has_method("curar_por_robot"):
			bot.curar_por_robot()
