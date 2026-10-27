extends CharacterBody2D
class_name RobotCurador
const CuracionRadial = preload("res://scripts/curacion_radial.gd")


# ============================================================
# CONFIGURACIÓN
# ============================================================

@export var radio_curacion: float = 120.0
@export var duracion: float = 10.0

# Movimiento
@export var velocidad: float = 75.0
@export var intervalo_cambio_direccion: float = 2.0

# Curación
@export_range(0.0, 1.0) var probabilidad_curacion: float = 0.90
@export var intervalo_curacion: float = 0.5

# Visual del área de curación
@export var color_area: Color = Color(0.2, 1.0, 0.2, 0.25)

# Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var jugador_invocador: int = 0

var direccion_movimiento: Vector2 = Vector2.ZERO
var tiempo_cambio_direccion: float = 0.0
var tiempo_curacion: float = 0.0

var motor_aspiradora: AudioStreamPlayer2D


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	add_to_group("robots_curadores")
	# El motor es espacial y pertenece a esta instancia de robot.
	motor_aspiradora = AudioManager.crear_motor_robot(self)
	motor_aspiradora.finished.connect(_repetir_motor)
	motor_aspiradora.play()
	AudioManager.efecto("robot_encender", -13.0, false)

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

	# El zumbido se detiene automaticamente al liberar el robot.
	AudioManager.efecto("robot_apagar", -13.0, false)
	queue_free()


func _repetir_motor() -> void:
	# Mantiene la aspiradora en loop incluso si el WAV no se importo como bucle.
	if is_instance_valid(motor_aspiradora) and is_inside_tree() and not is_queued_for_deletion():
		motor_aspiradora.play()


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
	# Team 0 excludes nobody: the robot retains its original two-team behavior.
	CuracionRadial.aplicar(self, radio_curacion, probabilidad_curacion)
