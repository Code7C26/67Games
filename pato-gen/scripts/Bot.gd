
extends CharacterBody2D

# Velocidad del personaje y lista de posibles skins
@export var speed: float = 100.0
@export var skins: Array[SpriteFrames] = []

# Guarda la velocidad original para aplicar mutaciones
var velocidad_base: float = 100.0

# Datos relacionados con la infección
var is_infected: bool = false
var color_infeccion: Color = Color.WHITE
var player_duenio: int = 0
var move_direction: Vector2 = Vector2.ZERO

# Probabilidad inicial de contagiar a otro bot
var probabilidad_contagio: float = 0.35

# Modificadores que pueden cambiar por la temperatura
var multiplicador_velocidad_temp: float = 1.0
var multiplicador_contagio_temp: float = 1.0

# Probabilidad de curarse cada segundo
var probabilidad_curacion: float = 0.01

# Tiempo de protección después de infectarse
var tiempo_escudo: float = 0.0

# Nodos utilizados por el personaje
@onready var timer_direccion: Timer = $TimerCambioRumbo
@onready var area_infeccion: Area2D = $AreaInfeccion
@onready var area_vision: Area2D = $AreaVision
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Timers para controlar contagio y curación
var timer_contagio: Timer
var timer_curacion: Timer


func _ready() -> void:
	randomize()
	
	# Elige una skin al azar al comenzar
	if skins.size() > 0 and animated_sprite:
		animated_sprite.sprite_frames = skins.pick_random()

	# Agrega el personaje al grupo de bots
	add_to_group("bots")
	velocidad_base = speed
	cambiar_direccion_aleatoria()
	
	# Configura el cambio de dirección automático
	if timer_direccion:
		timer_direccion.timeout.connect(_on_timer_timeout)
		timer_direccion.wait_time = randf_range(1.5, 3.0)
		timer_direccion.start()
	
	# Crea el timer que controla los contagios
	timer_contagio = Timer.new()
	timer_contagio.wait_time = 0.5
	timer_contagio.timeout.connect(_intentar_contagio_area)
	add_child(timer_contagio)
	
	# Crea el timer que controla las curaciones
	timer_curacion = Timer.new()
	timer_curacion.wait_time = 1.0
	timer_curacion.timeout.connect(_intentar_curacion)
	add_child(timer_curacion)


func _physics_process(delta: float) -> void:
	# Reduce el tiempo de protección
	if tiempo_escudo > 0:
		tiempo_escudo -= delta
		
	# Decide si el bot debe huir o perseguir
	if area_vision:
		if not is_infected:
			# Los bots sanos huyen de un infectado
			var amenaza = obtener_amenaza_cercana()
			if amenaza:
				huir_de(amenaza.global_position)
		else:
			# Los infectados buscan bots sanos
			var presa = obtener_humano_cercano()
			if presa:
				perseguir_a(presa.global_position)

	# Aplica el movimiento teniendo en cuenta la velocidad
	velocity = move_direction * (speed * multiplicador_velocidad_temp)
	move_and_slide()
	
	# Actualiza la animación según el movimiento
	actualizar_animacion(move_direction)


# Genera una dirección de movimiento aleatoria
func cambiar_direccion_aleatoria() -> void:
	move_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()


# Se ejecuta cuando termina el timer de dirección
func _on_timer_timeout() -> void:
	cambiar_direccion_aleatoria()
	if timer_direccion:
		timer_direccion.wait_time = randf_range(1.5, 3.5)
		timer_direccion.start()


# Busca un bot infectado dentro del área de visión
func obtener_amenaza_cercana() -> Node2D:
	for body in area_vision.get_overlapping_bodies():
		if body != self and body.is_in_group("bots") and body.is_infected:
			return body
	return null


# Busca un bot sano dentro del área de visión
func obtener_humano_cercano() -> Node2D:
	for body in area_vision.get_overlapping_bodies():
		if body != self and body.is_in_group("bots") and not body.is_infected:
			return body
	return null


# Hace que un bot sano se aleje del infectado
func huir_de(posicion_amenaza: Vector2) -> void:
	if not is_infected:
		move_direction = (global_position - posicion_amenaza).normalized()


# Hace que un bot infectado se acerque a un bot sano
func perseguir_a(posicion_objetivo: Vector2) -> void:
	if is_infected:
		move_direction = (posicion_objetivo - global_position).normalized()


# Infecta al bot y registra al jugador responsable
func infectar(color_jugador: Color, id_jugador: int) -> void:
	if not is_infected:
		is_infected = true
		color_infeccion = color_jugador
		player_duenio = id_jugador
		
		# Cambia el color visual del bot
		modulate = color_jugador
		
		# Da unos segundos de protección inicial
		tiempo_escudo = 3.0
		
		# Informa al mapa que se consiguió ADN
		var mapa = get_tree().current_scene
		if mapa.has_method("sumar_adn"):
			mapa.sumar_adn(player_duenio)
		if mapa.has_method("aplicar_mutaciones_a_bot"):
			mapa.aplicar_mutaciones_a_bot(self)
			
		# Activa los timers de contagio y curación
		timer_contagio.start()
		timer_curacion.start()


# Cura al bot y restaura su estado original
func curar() -> void:
	is_infected = false
	color_infeccion = Color.WHITE
	player_duenio = 0
	
	# Restaura el color original
	modulate = Color.WHITE
	
	# Detiene los timers de infección
	timer_contagio.stop()
	timer_curacion.stop()


# Intenta contagiar a los bots cercanos
func _intentar_contagio_area() -> void:
	if not is_infected or not area_infeccion:
		return
		
	for body in area_infeccion.get_overlapping_bodies():
		if body != self and body.is_in_group("bots") and not body.is_infected:
			# Calcula la probabilidad de contagio
			var chance_efectiva = probabilidad_contagio * multiplicador_contagio_temp
			if randf() <= chance_efectiva:
				body.infectar(color_infeccion, player_duenio)


# Intenta curar al bot una vez por segundo
func _intentar_curacion() -> void:
	if not is_infected:
		return
		
	# Solo puede curarse cuando termina el escudo
	if tiempo_escudo <= 0:
		if randf() <= probabilidad_curacion:
			curar()


# Aplica las mutaciones al bot
func aplicar_mutaciones(multiplicador_radio: float, multiplicador_velocidad: float, suma_probabilidad: float = 0.0) -> void:
	# Modifica la velocidad y la probabilidad de contagio
	speed = velocidad_base * multiplicador_velocidad
	probabilidad_contagio = min(1.0, 0.35 + suma_probabilidad)
	
	# Cambia el tamaño del área de infección
	if area_infeccion:
		area_infeccion.scale = Vector2(multiplicador_radio, multiplicador_radio)
	
	# Cambia ligeramente el tamaño visual del bot
	var escala_visual = 1.0 + (multiplicador_radio - 1.0) * 0.3
	scale = Vector2(escala_visual, escala_visual)


# Controla la animación dependiendo de la dirección
func actualizar_animacion(direccion: Vector2) -> void:
	if not animated_sprite:
		return

	# Detiene la animación si el bot está quieto
	if direccion.length_squared() < 0.01:
		animated_sprite.stop()
		return

	animated_sprite.play()

	# Determina si debe mirar hacia un lado o hacia arriba/abajo
	if abs(direccion.x) > abs(direccion.y):
		if direccion.x > 0:
			animated_sprite.play("Derecha")
		else:
			animated_sprite.play("Izquierda")
	else:
		if direccion.y > 0:
			animated_sprite.play("Abajo")
		else:
			animated_sprite.play("Arriba")


# Función conectada a la señal del área de infección
func _on_area_infeccion_body_entered(_body: Node2D) -> void:
	pass
