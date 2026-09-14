extends CharacterBody2D

@export var speed: float = 100.0
@export var skins: Array[SpriteFrames] = [] # Array para almacenar tus archivos .tres

var velocidad_base: float = 100.0

var is_infected: bool = false
var color_infeccion: Color = Color.WHITE
var player_duenio: int = 0
var move_direction: Vector2 = Vector2.ZERO

var probabilidad_contagio: float = 0.35

# Multiplicadores de temperatura
var multiplicador_velocidad_temp: float = 1.0
var multiplicador_contagio_temp: float = 1.0
var probabilidad_curacion: float = 0.01 # 1% Base Neutra (por segundo)

var tiempo_escudo: float = 0.0

# Nodos del personaje
@onready var timer_direccion: Timer = $TimerCambioRumbo
@onready var area_infeccion: Area2D = $AreaInfeccion
@onready var area_vision: Area2D = $AreaVision
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Dos timers separados para distintas frecuencias
var timer_contagio: Timer
var timer_curacion: Timer

func _ready() -> void:
	randomize()
	
	# Asigna una skin aleatoria del array de skins si está configurado
	if skins.size() > 0 and animated_sprite:
		animated_sprite.sprite_frames = skins.pick_random()

	add_to_group("bots")
	velocidad_base = speed
	cambiar_direccion_aleatoria()
	
	if timer_direccion:
		timer_direccion.timeout.connect(_on_timer_timeout)
		timer_direccion.wait_time = randf_range(1.5, 3.0)
		timer_direccion.start()
	
	# 1. Timer de Contagio: Cada 0.5 segundos
	timer_contagio = Timer.new()
	timer_contagio.wait_time = 0.5
	timer_contagio.timeout.connect(_intentar_contagio_area)
	add_child(timer_contagio)
	
	# 2. Timer de Curación: Cada 1.0 segundo
	timer_curacion = Timer.new()
	timer_curacion.wait_time = 1.0
	timer_curacion.timeout.connect(_intentar_curacion)
	add_child(timer_curacion)

func _physics_process(delta: float) -> void:
	if tiempo_escudo > 0:
		tiempo_escudo -= delta
		
	# --- COMPORTAMIENTO DE IA (HUIDA O PERSECUCIÓN) ---
	if area_vision:
		if not is_infected:
			# Si está sano: Huye del infectado más cercano
			var amenaza = obtener_amenaza_cercana()
			if amenaza:
				huir_de(amenaza.global_position)
		else:
			# Si está infectado: Persigue al humano sano más cercano
			var presa = obtener_humano_cercano()
			if presa:
				perseguir_a(presa.global_position)

	velocity = move_direction * (speed * multiplicador_velocidad_temp)
	move_and_slide()
	
	# --- ACTUALIZACIÓN VISUAL ---
	actualizar_animacion(move_direction)

func cambiar_direccion_aleatoria() -> void:
	move_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

func _on_timer_timeout() -> void:
	cambiar_direccion_aleatoria()
	if timer_direccion:
		timer_direccion.wait_time = randf_range(1.5, 3.5)
		timer_direccion.start()

# Busca el primer bot infectado dentro del rango de visión
func obtener_amenaza_cercana() -> Node2D:
	for body in area_vision.get_overlapping_bodies():
		if body != self and body.is_in_group("bots") and body.is_infected:
			return body
	return null

# Busca el primer bot sano dentro del rango de visión
func obtener_humano_cercano() -> Node2D:
	for body in area_vision.get_overlapping_bodies():
		if body != self and body.is_in_group("bots") and not body.is_infected:
			return body
	return null

# Permite a los humanos sanos huir de una amenaza
func huir_de(posicion_amenaza: Vector2) -> void:
	if not is_infected:
		move_direction = (global_position - posicion_amenaza).normalized()

# Permite a los bots infectados perseguir a un humano sano
func perseguir_a(posicion_objetivo: Vector2) -> void:
	if is_infected:
		move_direction = (posicion_objetivo - global_position).normalized()

func infectar(color_jugador: Color, id_jugador: int) -> void:
	if not is_infected:
		is_infected = true
		color_infeccion = color_jugador
		player_duenio = id_jugador
		
		# Tiñe la raíz entera
		modulate = color_jugador
		
		tiempo_escudo = 3.0 # 3 segundos de gracia inicial
		
		var mapa = get_tree().current_scene
		if mapa.has_method("sumar_adn"):
			mapa.sumar_adn(player_duenio)
		if mapa.has_method("aplicar_mutaciones_a_bot"):
			mapa.aplicar_mutaciones_a_bot(self)
			
		# Arrancan ambos temporizadores
		timer_contagio.start()
		timer_curacion.start()

func curar() -> void:
	is_infected = false
	color_infeccion = Color.WHITE
	player_duenio = 0
	
	# Restaura el color original
	modulate = Color.WHITE
	
	# Se apagan ambos temporizadores
	timer_contagio.stop()
	timer_curacion.stop()

# Se ejecuta cada 0,5 segundos
func _intentar_contagio_area() -> void:
	if not is_infected or not area_infeccion:
		return
		
	for body in area_infeccion.get_overlapping_bodies():
		if body != self and body.is_in_group("bots") and not body.is_infected:
			var chance_efectiva = probabilidad_contagio * multiplicador_contagio_temp
			if randf() <= chance_efectiva:
				body.infectar(color_infeccion, player_duenio)

# Se ejecuta cada 1,0 segundo
func _intentar_curacion() -> void:
	if not is_infected:
		return
		
	if tiempo_escudo <= 0:
		if randf() <= probabilidad_curacion:
			curar()

func aplicar_mutaciones(multiplicador_radio: float, multiplicador_velocidad: float, suma_probabilidad: float = 0.0) -> void:
	speed = velocidad_base * multiplicador_velocidad
	probabilidad_contagio = min(1.0, 0.35 + suma_probabilidad)
	
	if area_infeccion:
		area_infeccion.scale = Vector2(multiplicador_radio, multiplicador_radio)
	
	var escala_visual = 1.0 + (multiplicador_radio - 1.0) * 0.3
	scale = Vector2(escala_visual, escala_visual)

# Función que gestiona las animaciones según la dirección actual
func actualizar_animacion(direccion: Vector2) -> void:
	if not animated_sprite:
		return

	# Comprueba si el bot está detenido (tolerando valores flotantes muy pequeños)
	if direccion.length_squared() < 0.01:
		animated_sprite.stop()
		return

	animated_sprite.play()

	# Determina la dirección dominante
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

# Función para resolver la señal vinculada desde el editor
func _on_area_infeccion_body_entered(_body: Node2D) -> void:
	pass
